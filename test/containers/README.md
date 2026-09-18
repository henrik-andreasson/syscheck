# syscheck testcontainers suite

End-to-end tests that run each syscheck script inside a throwaway container laid
out like a real install, against real services (MariaDB, Redis, an OpenSSL OCSP
responder, an HTTP server) or against fake binaries where the
dependency is vendor hardware tooling that cannot be containerised. MinIO and
sshd are planned for Phase 4 and not used yet.

## Running

```bash
./run.sh                              # everything
./run.sh test_sc_01_diskusage.py -v   # one script's suite
./run.sh -k diskusage                 # by keyword
./run.sh -m known_bug                 # just the open-defect tests
```

`run.sh` creates `.venv/` on first use (needs `python3-venv`) and installs
`requirements.txt`. Docker must be reachable by the current user.

**In this repo's dev container there may be no Docker engine to reach.**
`.devcontainer/devcontainer.json` sets both `build.dockerfile` and `image`, and
`image` wins, so the container comes up from the stock
`mcr.microsoft.com/devcontainers/base:trixie` without the `docker-ce` that
`.devcontainer/Dockerfile` installs — and `.devcontainer/start-docker.sh` then
fails with a message blaming privileges. The container is privileged; it is the
engine that is missing. Install `docker-ce` per that Dockerfile and re-run
`start-docker.sh`. Note that a shell started before the `docker` group existed
is not in it, so the first session after installing needs `sg docker -c './run.sh'`.

The base image is built once per session from `Dockerfile.syscheck` and cached
by Docker; the container is started once per session and reset between tests.
A full sc_01 run is ~35s, most of which is the fill/measure cycle on tmpfs.

## How a test is written

```python
def test_error_when_usage_is_above_the_error_limit(syscheck, filled):
    syscheck.set_script_config("01", config((FS_A, 10, 5)))
    run = syscheck.run_script("sc_01_diskusage.sh")

    msg = run.only()
    assert msg.level == "E"
    assert msg.errno == "012"
```

The `syscheck` fixture is a container with a pristine config, one per test.
`run_script` returns a `ScriptRun` whose `.messages` are parsed `NEWFMT` /
`OLDFMT` / JSON log lines, so assertions target `level` / `errno` / `index` /
`text` instead of matching whole lines that contain a timestamp and hostname.

Useful harness methods (`syscheck_harness.py`):

| method | purpose |
| --- | --- |
| `set_script_config(id, text)` | replace `config/<id>.conf`; also the place to override common settings, since it is sourced after `common.conf` |
| `run_script(name, *args)` | run a script with `--screen` and parse the output |
| `fill_filesystem(mount, pct)` | consume a percentage of a tmpfs, returns the real `df` percentage |
| `install_fake_bin(name, body)` | drop an executable early on `PATH` |
| `start_process(name)` | start a long-lived process whose argv is `/usr/local/bin/<name>`, returns its pid; killed again by the next `reset()` |
| `free_pid()` | a pid that is not in use, for the stale-pidfile cases |
| `exec(cmd)` / `bash(script)` | arbitrary commands in the container |
| `last_status()` / `file_log()` / `syslog()` | the three non-screen output sinks |

Service helpers, for the checks that talk to something over the network. Each
starts a container on the shared test network and returns a handle plus the name
to address it by; each is stopped by the fixture that started it.

| helper | starts | used by |
| --- | --- | --- |
| `start_mariadb_node` | `mariadb:11` | sc_12, sc_18, sc_32, sc_38, sc_40 |
| `start_redis_node` | `redis:7` with `requirepass` | sc_34 |
| `start_http_server` | a stdlib HTTP server serving `{path: {status, body, delay}}`; `set_routes()` changes the answer without a restart, and `body_b64` carries binary (a DER CRL). `{HOST}` in a body is replaced with the `Host:` header actually received, which is how sc_37's header is asserted | sc_02, sc_08, sc_33, sc_37 |
| `start_ocsp_responder` | a real `openssl ocsp` responder over a real CA built by `OCSP_PKI_SH` — good, revoked and foreign certificates, with the revocation recorded in the CA database | sc_10 |

Not every check that talks to a service needs one. `sc_28` shells out to
`related/915` for all its ssh, so its suite stubs *that* and needs no sshd —
the seam worth testing is the call, not the transport.

## Marker conventions

- `xfail(strict=True)` — the test asserts the behaviour the script *should*
  have and the reason names the defect. These are the open bugs in `REPORT.md`.
  When a bug is fixed the strict xfail becomes a failure, which is the signal to
  delete the marker.
- `known_bug` — selects those tests (`-m known_bug`).
- `slow` — starts extra containers.

## Layout

```
Dockerfile.syscheck    base image: bash, coreutils, getopt, rsyslogd, openssl, curl
syscheck_harness.py    container lifecycle, exec helpers, log-line parsers
conftest.py            session container + per-test reset
test_sc_NN_*.py        one file per syscheck script
test_sc_process_checks.py  the exception: sc_05/12/15/16 are the same check
                       four times over, so they are one parametrised file
test_proc_checker.py   lib/proc_checker.sh, shared by seven of the sc_ scripts
test_packaging.py      install-wide invariants
PLAN.md                per-script mock strategy for every sc_ + related script
REPORT.md              coverage and findings
```
