"""Test harness for driving syscheck scripts inside a throwaway container.

The container mirrors a real syscheck install: the repo is mounted read-only at
/src and copied into /opt/syscheck the same way lib/release.sh lays out a
package, so the scripts run against the paths they expect ($SYSCHECK_HOME,
config/, lang/, var/last_status, ...).

Tests drive a script with `syscheck.run_script(...)` and assert on the parsed
messages rather than on raw text, so they stay readable and are not coupled to
the exact date/hostname in every line.
"""

from __future__ import annotations

import io
import json
import re
import shlex
import subprocess
import tarfile
from dataclasses import dataclass, field
from pathlib import Path

from testcontainers.core.container import DockerContainer
from testcontainers.core.waiting_utils import wait_for_logs

REPO_ROOT = Path(__file__).resolve().parents[2]
IMAGE_TAG = "syscheck-testcontainers:latest"

INSTALL_PAYLOAD = [
    "config",
    "lang",
    "lib",
    "scripts-available",
    "scripts-enabled",
    "related-available",
    "related-enabled",
    "var",
    "syscheck.sh",
    "console_syscheck.sh",
    "logbook.sh",
    "getroot.sh",
]

TMPFS_MOUNTS = {
    "/mnt/tfs_a": "size=64m,mode=1777",
    "/mnt/tfs_b": "size=16m,mode=1777",
}

_NEWFMT_RE = re.compile(
    r"^(?P<scriptid>[0-9]+)-(?P<index>[0-9]+)-(?P<level>[IWE])-(?P<errno>[^-]*)-(?P<systemname>\S+)"
    r"\s+(?P<date>[0-9]{8})\s+(?P<time>[0-9]{2}:[0-9]{2}:[0-9]{2})"
    r"\s+(?P<host>[^:]+):\s+(?P<longlevel>INFO|WARNING|ERROR)\s+-\s+(?P<scriptname>\S+)\s*(?P<text>.*)$"
)

_OLDFMT_RE = re.compile(
    r"^(?P<level>[IWE])-(?P<scriptid_errno>[^-]*)-(?P<systemname>\S+)"
    r"\s+(?P<date>[0-9]{8})\s+(?P<time>[0-9]{2}:[0-9]{2}:[0-9]{2})"
    r"\s+(?P<host>[^:]+):\s+(?P<longlevel>INFO|WARNING|ERROR)\s+-\s+(?P<scriptname>\S+)\s*(?P<text>.*)$"
)

INFO = "I"
WARN = "W"
ERROR = "E"


class HarnessError(RuntimeError):
    pass


@dataclass(frozen=True)
class Message:
    """One parsed syscheck log line."""

    scriptid: str
    index: str
    level: str
    errno: str
    systemname: str
    host: str
    longlevel: str
    scriptname: str
    text: str
    raw: str

    def __str__(self) -> str:
        return self.raw


@dataclass
class ExecResult:
    exit_code: int
    stdout: str
    stderr: str
    command: str

    @property
    def output(self) -> str:
        return self.stdout + self.stderr

    def check(self) -> "ExecResult":
        if self.exit_code != 0:
            raise HarnessError(
                f"command failed ({self.exit_code}): {self.command}\n"
                f"--- stdout ---\n{self.stdout}\n--- stderr ---\n{self.stderr}"
            )
        return self


@dataclass
class ScriptRun:
    """Result of running one scripts-available/sc_NN_*.sh."""

    script: str
    exit_code: int
    stdout: str
    stderr: str
    messages: list[Message] = field(default_factory=list)
    json_messages: list[dict] = field(default_factory=list)
    unparsed: list[str] = field(default_factory=list)

    @property
    def output(self) -> str:
        """Everything the script printed.

        `--screen` output goes to stderr (printlogmess.sh) while the library's
        own complaints ("cant open configfile") go to stdout, so assertions
        should generally look at both.
        """
        return self.stdout + self.stderr

    @property
    def levels(self) -> list[str]:
        return [m.level for m in self.messages]

    @property
    def errnos(self) -> list[str]:
        return [m.errno for m in self.messages]

    @property
    def indexes(self) -> list[str]:
        return [m.index for m in self.messages]

    def only(self) -> Message:
        """The single message this run was expected to emit."""
        if len(self.messages) != 1:
            raise AssertionError(
                f"expected exactly 1 message from {self.script}, got {len(self.messages)}:\n"
                + self.describe()
            )
        return self.messages[0]

    def describe(self) -> str:
        parts = [f"$ {self.script} -> exit {self.exit_code}"]
        for m in self.messages:
            parts.append(f"  msg: {m.raw}")
        for line in self.unparsed:
            parts.append(f"  raw: {line}")
        if self.stderr.strip():
            parts.append(f"  stderr: {self.stderr.strip()}")
        return "\n".join(parts)


def parse_messages(text: str) -> tuple[list[Message], list[dict], list[str]]:
    """Split script stdout into NEWFMT/OLDFMT messages, JSON messages and noise."""
    messages: list[Message] = []
    json_messages: list[dict] = []
    unparsed: list[str] = []

    for line in text.splitlines():
        if not line.strip():
            continue
        stripped = line.strip()
        if stripped.startswith("{") and stripped.endswith("}"):
            try:
                obj = json.loads(stripped)
            except json.JSONDecodeError:
                unparsed.append(line)
                continue
            json_messages.append(obj)
            messages.append(
                Message(
                    scriptid=obj.get("SCRIPTID", ""),
                    index=obj.get("SCRIPTINDEX", ""),
                    level=obj.get("LEVEL", ""),
                    errno=obj.get("ERRNO", ""),
                    systemname=obj.get("SYSTEMNAME", ""),
                    host=obj.get("HOSTNAME", ""),
                    longlevel=obj.get("LONGLEVEL", ""),
                    scriptname=obj.get("SCRIPTNAME", ""),
                    text=obj.get("DESCRIPTION", ""),
                    raw=line,
                )
            )
            continue

        m = _NEWFMT_RE.match(line)
        if m:
            messages.append(
                Message(
                    scriptid=m["scriptid"],
                    index=m["index"],
                    level=m["level"],
                    errno=m["errno"],
                    systemname=m["systemname"],
                    host=m["host"],
                    longlevel=m["longlevel"],
                    scriptname=m["scriptname"],
                    text=m["text"],
                    raw=line,
                )
            )
            continue

        m = _OLDFMT_RE.match(line)
        if m:
            messages.append(
                Message(
                    scriptid=m["scriptid_errno"],
                    index="",
                    level=m["level"],
                    errno=m["scriptid_errno"],
                    systemname=m["systemname"],
                    host=m["host"],
                    longlevel=m["longlevel"],
                    scriptname=m["scriptname"],
                    text=m["text"],
                    raw=line,
                )
            )
            continue

        unparsed.append(line)

    return messages, json_messages, unparsed


def build_image(dockerfile: str = "Dockerfile.syscheck", tag: str = IMAGE_TAG) -> str:
    """Build the base image. Cheap after the first run thanks to layer cache."""
    here = Path(__file__).resolve().parent
    proc = subprocess.run(
        ["docker", "build", "-q", "-f", str(here / dockerfile), "-t", tag, str(here)],
        capture_output=True,
        text=True,
    )
    if proc.returncode != 0:
        raise HarnessError(f"docker build failed:\n{proc.stdout}\n{proc.stderr}")
    return tag


class SyscheckContainer:
    """A running container with syscheck installed at $SYSCHECK_HOME."""

    home = "/opt/syscheck"

    def __init__(self, container: DockerContainer):
        self._tc = container
        self._raw = container.get_wrapped_container()


    def exec(self, command: list[str] | str, env: dict | None = None,
             workdir: str | None = None, user: str | None = None) -> ExecResult:
        if isinstance(command, str):
            argv = ["/bin/bash", "-c", command]
            shown = command
        else:
            argv = command
            shown = shlex.join(command)

        exit_code, out = self._raw.exec_run(
            argv,
            environment=env or {},
            workdir=workdir,
            user=user or "root",
            demux=True,
        )
        stdout, stderr = out
        return ExecResult(
            exit_code=exit_code,
            stdout=(stdout or b"").decode("utf-8", "replace"),
            stderr=(stderr or b"").decode("utf-8", "replace"),
            command=shown,
        )

    def bash(self, script: str, env: dict | None = None) -> ExecResult:
        return self.exec(script, env=env)


    def write_file(self, path: str, content: str, mode: int = 0o644) -> None:
        data = content.encode("utf-8")
        buf = io.BytesIO()
        with tarfile.open(fileobj=buf, mode="w") as tar:
            info = tarfile.TarInfo(name=Path(path).name)
            info.size = len(data)
            info.mode = mode
            tar.addfile(info, io.BytesIO(data))
        buf.seek(0)
        parent = str(Path(path).parent)
        self.exec(["mkdir", "-p", parent]).check()
        if not self._raw.put_archive(parent, buf.getvalue()):
            raise HarnessError(f"failed to write {path}")

    def read_file(self, path: str) -> str:
        res = self.exec(["cat", path])
        if res.exit_code != 0:
            raise HarnessError(f"cannot read {path}: {res.stderr}")
        return res.stdout

    def file_exists(self, path: str) -> bool:
        return self.exec(["test", "-e", path]).exit_code == 0

    def install_fake_bin(self, name: str, script: str) -> str:
        """Drop an executable named `name` into /usr/local/bin (first on PATH)."""
        path = f"/usr/local/bin/{name}"
        body = script if script.startswith("#!") else "#!/bin/bash\n" + script
        self.write_file(path, body, mode=0o755)
        return path


    def set_script_config(self, scriptid: str, content: str) -> None:
        """Replace config/<scriptid>.conf.

        Note this file is sourced *after* common.conf, so it is also the place
        to override common settings for a single test (e.g. output format).
        """
        self.write_file(f"{self.home}/config/{scriptid}.conf", content)

    MUTABLE_TREES = ("config", "lang", "lib", "scripts-available", "related-available")

    def reset(self) -> None:
        """Restore a pristine install and clear anything a previous test produced."""
        for tree in self.MUTABLE_TREES:
            self.exec(
                f"rm -rf {self.home}/{tree} && cp -a /src/{tree} {self.home}/{tree}"
            ).check()
        self.exec(
            f"find {self.home} -name '*.sh' -exec chmod 755 {{}} + ; "
            f"find {self.home} -name '*.py' -exec chmod 755 {{}} +"
        ).check()
        self.exec(
            f"rm -f {self.home}/var/last_status "
            f"{self.home}/var/syscheck-on-hold "
            "/var/tmp/syscheck2.log /var/log/syscheck-logbook.log "
            "&& : > /var/log/syslog"
        ).check()
        self.exec("rm -rf /usr/local/bin/* || true")
        for mount in TMPFS_MOUNTS:
            self.exec(f"rm -rf {mount:s}/* || true")


    def script_path(self, script: str) -> str:
        if "/" in script:
            return f"{self.home}/{script}"
        return f"{self.home}/scripts-available/{script}"

    def run_script(self, script: str, *args: str, env: dict | None = None,
                   screen: bool = True) -> ScriptRun:
        argv = [self.script_path(script)]
        if screen and "--screen" not in args and "-s" not in args:
            argv.append("--screen")
        argv.extend(args)

        run_env = {"SYSCHECK_HOME": self.home}
        run_env.update(env or {})
        res = self.exec(argv, env=run_env)

        messages, json_messages, unparsed = parse_messages(res.stdout + res.stderr)
        return ScriptRun(
            script=shlex.join(argv),
            exit_code=res.exit_code,
            stdout=res.stdout,
            stderr=res.stderr,
            messages=messages,
            json_messages=json_messages,
            unparsed=unparsed,
        )


    def last_status(self) -> str:
        path = f"{self.home}/var/last_status"
        return self.read_file(path) if self.file_exists(path) else ""

    def file_log(self) -> str:
        return self.read_file("/var/tmp/syscheck2.log") if self.file_exists("/var/tmp/syscheck2.log") else ""

    def syslog(self) -> str:
        return self.read_file("/var/log/syslog") if self.file_exists("/var/log/syslog") else ""


    def fill_filesystem(self, mountpoint: str, percent: int, name: str = "filler") -> int:
        """Consume `percent` of `mountpoint` and return the real df Use% after.

        Uses the filesystem's own reported total/available so the result holds
        for any tmpfs size, and reads the percentage back with the same
        `df -Ph` the scripts use rather than assuming it.
        """
        self.exec(f"rm -f {shlex.quote(mountpoint)}/{name}").check()
        script = f"""
set -e
mp={shlex.quote(mountpoint)}
total=$(df -Pk "$mp" | awk 'NR==2 {{print $2}}')
target=$(( total * {percent} / 100 ))
used=$(df -Pk "$mp" | awk 'NR==2 {{print $3}}')
need=$(( target - used ))
if [ "$need" -gt 0 ] ; then
  dd if=/dev/zero of="$mp/{name}" bs=1024 count="$need" status=none
fi
"""
        self.exec(script).check()
        return self.disk_percent(mountpoint)

    def disk_percent(self, mountpoint: str) -> int:
        res = self.exec(
            f"df -Ph {shlex.quote(mountpoint)} | grep -v Filesystem | awk '{{print $5}}' | sed 's/%//'"
        ).check()
        return int(res.stdout.strip())


def start_syscheck_container(image: str = IMAGE_TAG,
                             network: str | None = None) -> tuple[DockerContainer, SyscheckContainer]:
    """Start the container and lay syscheck out inside it."""
    tc = DockerContainer(image)
    tc.with_volume_mapping(str(REPO_ROOT), "/src", "ro")
    for mountpoint, options in TMPFS_MOUNTS.items():
        tc.with_tmpfs_mount(mountpoint, options)
    kwargs: dict = {"hostname": "syscheck-test"}
    if network:
        kwargs["network"] = network
    tc.with_kwargs(**kwargs)
    tc.with_env("SYSCHECK_HOME", "/opt/syscheck")
    tc.start()

    sc = SyscheckContainer(tc)

    payload = " ".join(INSTALL_PAYLOAD)
    sc.exec(
        f"set -e; mkdir -p {sc.home}; cd /src; cp -a {payload} {sc.home}/; "
        f"mkdir -p {sc.home}/var; "
        f"touch {sc.home}/syscheck.sh; chmod 755 {sc.home}/syscheck.sh; "
        f"find {sc.home} -name '*.sh' -exec chmod 755 {{}} +; "
        f"find {sc.home} -name '*.py' -exec chmod 755 {{}} +"
    ).check()

    sc.exec("rsyslogd 2>/dev/null || true")
    sc.exec("for i in 1 2 3 4 5 6 7 8 9 10; do [ -S /dev/log ] && break; sleep 0.2; done")

    return tc, sc
