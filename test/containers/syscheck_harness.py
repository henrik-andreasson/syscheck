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

import base64
import io
import json
import re
import shlex
import subprocess
import tarfile
import time
import uuid
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


    def start_process(self, name: str, seconds: int = 600) -> int:
        """Start a long-lived process whose argv[0] is /usr/local/bin/<name>.

        A copy of `sleep` is enough: the process checks only ever look at the
        command line `ps` reports, never at what the process does. Returns the
        pid, for writing into a pidfile.
        """
        quoted = shlex.quote(f"/usr/local/bin/{name}")
        # not an unconditional cp: copying over a binary that is already
        # running fails with ETXTBSY, and a test may want two instances
        self.exec(f"test -x {quoted} || cp /bin/sleep {quoted}").check()
        res = self.exec(
            f"nohup {quoted} {int(seconds)} >/dev/null 2>&1 & echo $!"
        ).check()
        return int(res.stdout.strip())

    def kill_stray_processes(self) -> None:
        """Kill anything a previous test started from /usr/local/bin.

        Deleting the binaries does not stop the processes, so without this a
        process started in one test is still running for every test that
        follows — and a process check looking it up by name would find it.

        Waits for them to actually go, rather than assuming: the container runs
        with init=True so they are reaped promptly, but `ps` must not be able to
        see them at all by the time the next test looks.
        """
        self.exec(
            "pkill -9 -f '^/usr/local/bin/' 2>/dev/null || true ; "
            "for i in $(seq 50) ; do "
            "  pgrep -f '^/usr/local/bin/' >/dev/null 2>&1 || break ; "
            "  sleep 0.1 ; "
            "done"
        )

    def free_pid(self) -> int:
        """A pid that is not in use, for the stale-pidfile cases.

        Picked by probing rather than assumed, so the test cannot accidentally
        name a live process.
        """
        res = self.exec(
            "for p in $(seq 30000 32768) ; do "
            "  kill -0 $p 2>/dev/null || { echo $p ; exit 0 ; } ; "
            "done ; exit 1"
        ).check()
        return int(res.stdout.strip())


    def set_script_config(self, scriptid: str, content: str) -> None:
        """Replace config/<scriptid>.conf.

        Note this file is sourced *after* common.conf, so it is also the place
        to override common settings for a single test (e.g. output format).
        """
        self.write_file(f"{self.home}/config/{scriptid}.conf", content)

    # scripts-enabled and related-enabled are restored too: a test that enables a
    # check would otherwise leave it enabled for every test that follows, and
    # `syscheck.sh` runs whatever it finds there.
    MUTABLE_TREES = ("config", "lang", "lib", "scripts-available",
                     "related-available", "scripts-enabled", "related-enabled")

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
        self.kill_stray_processes()
        self.exec("rm -rf /usr/local/bin/* || true")
        for mount in TMPFS_MOUNTS:
            self.exec(f"rm -rf {mount:s}/* || true")


    # the entry points that live at the install root rather than in
    # scripts-available/ — syscheck.sh is the orchestrator, not a check
    TOP_LEVEL_SCRIPTS = ("syscheck.sh", "logbook.sh", "getroot.sh",
                         "console_syscheck.sh")

    def script_path(self, script: str) -> str:
        if "/" in script:
            return f"{self.home}/{script}"
        if script in self.TOP_LEVEL_SCRIPTS:
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
    # init=True gives the container a real init (tini) as PID 1. Without it PID 1
    # is the image's `sleep infinity`, which never reaps, so every process a test
    # starts and stops stays behind as a zombie — and `ps -ef` still lists a
    # zombie as `[name] <defunct>`, which the name-based process checks in
    # sc_05/12/15/16/22/23/30 would happily match.
    kwargs: dict = {"hostname": "syscheck-test", "init": True}
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


def create_network(prefix: str = "syscheck-test") -> str:
    name = f"{prefix}-{uuid.uuid4().hex[:8]}"
    proc = subprocess.run(["docker", "network", "create", name],
                          capture_output=True, text=True)
    if proc.returncode != 0:
        raise HarnessError(f"docker network create failed: {proc.stderr}")
    return name


def remove_network(name: str) -> None:
    subprocess.run(["docker", "network", "rm", name], capture_output=True, text=True)


def docker_exec(container_name: str, argv: list[str]) -> str:
    """Run a command in a container by name and return its stdout.

    For asking a service container about itself — what its process is called,
    where it puts its pidfile — which is not something the syscheck container
    can see from outside.
    """
    proc = subprocess.run(["docker", "exec", container_name, *argv],
                          capture_output=True, text=True)
    if proc.returncode != 0:
        raise HarnessError(
            f"docker exec {container_name} {shlex.join(argv)} failed:\n{proc.stderr}")
    return proc.stdout


# A tiny HTTP server for the checks that poll a web endpoint (sc_02, sc_33,
# sc_37). PLAN.md proposed the repo's own test/pyhton-dummy-health-web-server.py,
# but that needs Flask installed in the container and serves three fixed routes
# (/health, /ok, /fail) — while the checks request paths of their own
# (/ejbca/publicweb/healthcheck/ejbcahealth, a .jnlp file). This serves any path,
# any status, any body, with an optional delay for timeout cases, out of the
# standard library and therefore out of the image the suite already builds.
_HTTP_SERVER_PY = """
import base64, json, os, time
from http.server import BaseHTTPRequestHandler, HTTPServer

ROUTES_FILE = os.environ["ROUTES_FILE"]

class Handler(BaseHTTPRequestHandler):
    def do_GET(self):
        # re-read per request, so a test can change the served response without
        # restarting the container. The checks under test hard-code their URL
        # path, so varying the body is the only way to drive their branches.
        with open(ROUTES_FILE) as fh:
            routes = json.load(fh)

        route = routes.get(self.path)
        if route is None:
            self.send_response(404)
            self.end_headers()
            self.wfile.write(b"not found")
            return
        time.sleep(route.get("delay", 0))
        if "body_b64" in route:
            # binary payloads - a DER-encoded CRL or certificate cannot be
            # carried as a JSON string, so it travels base64 encoded
            payload = base64.b64decode(route["body_b64"])
            ctype = "application/pkix-crl"
        else:
            body = route.get("body", "")
            # lets a test prove which Host header the client actually sent
            body = body.replace("{HOST}", self.headers.get("Host", ""))
            payload = body.encode()
            ctype = "text/plain"
        self.send_response(route.get("status", 200))
        self.send_header("Content-Type", ctype)
        self.send_header("Content-Length", str(len(payload)))
        self.end_headers()
        self.wfile.write(payload)

    def log_message(self, *args):
        pass

HTTPServer(("0.0.0.0", int(os.environ.get("PORT", "8080"))), Handler).serve_forever()
"""

ROUTES_FILE = "/tmp/routes.json"


class HttpServer:
    """A running mock HTTP server, addressable by container name on the network."""

    def __init__(self, container: DockerContainer, name: str, port: int):
        self._tc = container
        self.name = name
        self.port = port

    def set_routes(self, routes: dict) -> None:
        """Replace what the server answers, effective on the next request.

        Base64 so that a body containing quotes, newlines or shell
        metacharacters survives the trip through `docker exec sh -c`.
        """
        encoded = base64.b64encode(json.dumps(routes).encode()).decode()
        docker_exec(self.name, ["sh", "-c",
                                f"echo {encoded} | base64 -d > {ROUTES_FILE}"])

    def stop(self) -> None:
        self._tc.stop()


def start_http_server(network: str, routes: dict, port: int = 8080,
                      image: str = IMAGE_TAG) -> tuple[HttpServer, str]:
    """Serve `routes` — {path: {"status": int, "body": str, "delay": float}} —
    on `network`, reachable by container name. Call `set_routes` to change them."""
    name = f"httpd-{uuid.uuid4().hex[:8]}"
    encoded = base64.b64encode(_HTTP_SERVER_PY.encode()).decode()
    seed = base64.b64encode(json.dumps(routes).encode()).decode()
    tc = DockerContainer(image)
    tc.with_name(name)
    tc.with_env("ROUTES_FILE", ROUTES_FILE)
    tc.with_env("PORT", str(port))
    tc.with_command(
        f"bash -c 'echo {seed} | base64 -d > {ROUTES_FILE} && "
        f"echo {encoded} | base64 -d > /tmp/server.py && exec python3 /tmp/server.py'"
    )
    tc.with_kwargs(network=network)
    tc.start()

    raw = tc.get_wrapped_container()
    deadline = time.monotonic() + 30
    # probe a path that is not in `routes`: the 404 handler proves the server is
    # accepting connections without depending on a route the test may replace,
    # and without consuming a route whose `delay` would stall the probe.
    while time.monotonic() < deadline:
        probe = (
            "import urllib.request as u, urllib.error as e\n"
            f"try: u.urlopen('http://127.0.0.1:{port}/-readiness-probe')\n"
            "except e.HTTPError: pass\n"
        )
        code, _ = raw.exec_run(["python3", "-c", probe])
        if code == 0:
            return HttpServer(tc, name, port), name
        time.sleep(0.3)
    raise HarnessError(f"http server {name} did not become ready")


def start_redis_node(network: str, password: str = "redispw",
                     image: str = "redis:7") -> tuple[DockerContainer, str]:
    """Start one password-protected Redis on `network`, reachable by its name.

    `requirepass` is set on the command line rather than through a config file
    so the container needs no volume; the checks under test only ever send PING.
    """
    name = f"redis-{uuid.uuid4().hex[:8]}"
    tc = DockerContainer(image)
    tc.with_name(name)
    # with_command, not with_kwargs(command=...): testcontainers passes its own
    # _command through to docker create, and the two collide
    tc.with_command(f"redis-server --requirepass {shlex.quote(password)}")
    tc.with_kwargs(network=network)
    tc.start()

    raw = tc.get_wrapped_container()
    deadline = time.monotonic() + 60
    while time.monotonic() < deadline:
        code, _ = raw.exec_run(["redis-cli", "-a", password, "ping"])
        if code == 0:
            return tc, name
        time.sleep(0.5)
    raise HarnessError(f"redis node {name} did not become ready")


def start_sshd_node(network: str, public_key: str, image: str = IMAGE_TAG,
                    user: str = "syscheckbak") -> tuple[DockerContainer, str]:
    """Start one sshd on `network`, reachable by name, accepting `public_key`.

    Built from the syscheck image rather than a dedicated sshd image so the
    remote end has the same coreutils the scripts assume when they run things
    like `df --block-size=M` and `mktemp -p` over the connection.

    Key-only: `PasswordAuthentication no`, and the account is locked with `!` so
    nothing can log in without the key. `user` owns a writable home, which is
    where `906` and friends drop files.
    """
    name = f"sshd-{uuid.uuid4().hex[:8]}"
    setup = (
        "set -e ; "
        "ssh-keygen -A ; "
        "mkdir -p /run/sshd ; "
        # debian already ships users named backup, sync and so on
        f"id -u {shlex.quote(user)} >/dev/null 2>&1 || "
        f"useradd -m -s /bin/bash {shlex.quote(user)} ; "
        f"passwd -l {shlex.quote(user)} >/dev/null ; "
        f"mkdir -p /home/{user}/.ssh ; "
        f"printf '%s\n' {shlex.quote(public_key)} > /home/{user}/.ssh/authorized_keys ; "
        f"chown -R {user}:{user} /home/{user}/.ssh ; "
        f"chmod 700 /home/{user}/.ssh ; chmod 600 /home/{user}/.ssh/authorized_keys ; "
        "printf 'PasswordAuthentication no\nPermitRootLogin no\n' "
        ">> /etc/ssh/sshd_config ; "
        "exec /usr/sbin/sshd -D -e"
    )
    tc = DockerContainer(image)
    tc.with_name(name)
    tc.with_command(f"bash -lc {shlex.quote(setup)}")
    tc.with_kwargs(network=network)
    tc.start()

    raw = tc.get_wrapped_container()
    deadline = time.monotonic() + 60
    while time.monotonic() < deadline:
        code, _ = raw.exec_run(["bash", "-c", "exec 3<>/dev/tcp/127.0.0.1/22"])
        if code == 0:
            return tc, name
        time.sleep(0.5)
    raise HarnessError(f"sshd node {name} did not become ready")


def start_mariadb_node(network: str, root_password: str = "rootpw",
                       database: str = "syscheckdb", user: str = "syscheck",
                       password: str = "syscheckpw",
                       image: str = "mariadb:11") -> tuple[DockerContainer, str]:
    """Start one MariaDB node on `network`, reachable by its container name."""
    name = f"mariadb-{uuid.uuid4().hex[:8]}"
    tc = DockerContainer(image)
    tc.with_env("MARIADB_ROOT_PASSWORD", root_password)
    tc.with_env("MARIADB_DATABASE", database)
    tc.with_env("MARIADB_USER", user)
    tc.with_env("MARIADB_PASSWORD", password)
    tc.with_name(name)
    tc.with_kwargs(network=network)
    tc.start()

    raw = tc.get_wrapped_container()
    deadline = time.monotonic() + 120
    while time.monotonic() < deadline:
        code, _ = raw.exec_run(
            ["mariadb-admin", "ping", "-h", "127.0.0.1", "--protocol=TCP",
             "-uroot", f"-p{root_password}", "--silent"]
        )
        if code == 0:
            return tc, name
        time.sleep(1)
    raise HarnessError(f"mariadb node {name} did not become ready")


# A throwaway PKI and a real `openssl ocsp` responder, for sc_10. Everything is
# genuine: a CA, leaf certificates, a revocation recorded in the CA database,
# and an OCSP responder answering signed responses over HTTP. Only the hostname
# is ours.
OCSP_PKI_SH = r"""
set -e
D=$1
rm -rf "$D"; mkdir -p "$D/newcerts"; cd "$D"
: > index.txt; echo 01 > serial
cat > ca.cnf <<'EOF'
[ ca ]
default_ca = CA_default
[ CA_default ]
dir             = PKIDIR
database        = $dir/index.txt
new_certs_dir   = $dir/newcerts
serial          = $dir/serial
certificate     = $dir/ca.crt
private_key     = $dir/ca.key
default_md      = sha256
default_days    = 3650
policy          = pol
email_in_dn     = no
rand_serial     = no
unique_subject  = no
[ pol ]
commonName = supplied
[ req ]
distinguished_name = dn
prompt = no
[ dn ]
CN = syscheck-ocsp-ca
[ v3_ocsp ]
basicConstraints = CA:FALSE
keyUsage = critical, digitalSignature
extendedKeyUsage = OCSPSigning
EOF
sed -i "s#PKIDIR#$D#" ca.cnf

openssl req -x509 -newkey rsa:2048 -nodes -keyout ca.key -out ca.crt \
        -days 3650 -subj "/CN=syscheck-ocsp-ca" 2>/dev/null

leaf() {
  openssl req -newkey rsa:2048 -nodes -keyout "$1.key" -out "$1.csr" \
          -subj "/CN=$1" 2>/dev/null
  openssl ca -batch -config ca.cnf ${2:-} -in "$1.csr" -out "$1.crt" 2>/dev/null
}

leaf good
leaf revoked
leaf "responder" "-extensions v3_ocsp"
openssl ca -batch -config ca.cnf -revoke revoked.crt 2>/dev/null

# an unrelated CA: its leaf is genuinely "unknown" to this responder, because
# the responder's database has never heard of that issuer
openssl req -x509 -newkey rsa:2048 -nodes -keyout other-ca.key -out other-ca.crt \
        -days 3650 -subj "/CN=other-ca" 2>/dev/null
openssl req -newkey rsa:2048 -nodes -keyout unknown.key -out unknown.csr \
        -subj "/CN=unknown" 2>/dev/null
openssl x509 -req -in unknown.csr -CA other-ca.crt -CAkey other-ca.key \
        -CAcreateserial -out unknown.crt -days 3650 2>/dev/null
echo READY
"""


class OcspResponder:
    """A real `openssl ocsp` responder in its own container."""

    def __init__(self, container: DockerContainer, name: str, port: int):
        self._tc = container
        self.name = name
        self.port = port

    @property
    def url(self) -> str:
        return f"http://{self.name}:{self.port}"

    def stop(self) -> None:
        self._tc.stop()


def start_ocsp_responder(network: str, pki_tar_b64: str, pki_dir: str = "/pki",
                         port: int = 8888,
                         image: str = IMAGE_TAG) -> tuple[OcspResponder, str]:
    """Serve OCSP for the PKI in `pki_tar_b64` (a base64 tar of `pki_dir`).

    Runs in its own container so that the syscheck container's per-test
    `reset()` — which kills stray processes — cannot take the responder with it.
    """
    name = f"ocsp-{uuid.uuid4().hex[:8]}"
    tc = DockerContainer(image)
    tc.with_name(name)
    tc.with_command(
        "bash -c '"
        f"mkdir -p {pki_dir} && echo {pki_tar_b64} | base64 -d | tar -x -C {pki_dir} && "
        f"cd {pki_dir} && exec openssl ocsp -index index.txt -port {port} "
        f"-rsigner responder.crt -rkey responder.key -CA ca.crt -text"
        "'"
    )
    tc.with_kwargs(network=network)
    tc.start()

    raw = tc.get_wrapped_container()
    deadline = time.monotonic() + 60
    while time.monotonic() < deadline:
        code, _ = raw.exec_run(
            ["bash", "-c",
             f"cd {pki_dir} && openssl ocsp -issuer ca.crt -cert good.crt "
             f"-CAfile ca.crt -url http://127.0.0.1:{port} 2>&1 | grep -q ': good'"]
        )
        if code == 0:
            return OcspResponder(tc, name, port), name
        time.sleep(0.5)
    raise HarnessError(f"ocsp responder {name} did not become ready")

