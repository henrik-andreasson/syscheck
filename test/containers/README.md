# syscheck testcontainers suite

End-to-end tests that run each syscheck script inside a throwaway container laid
out like a real install, against real services (MariaDB, Redis, nginx, an
OpenSSL OCSP responder, MinIO, sshd, ...) or against fake binaries where the
dependency is vendor hardware tooling that cannot be containerised.

## Running

```bash
./run.sh                              # everything
./run.sh test_sc_01_diskusage.py -v   # one script's suite
./run.sh -k diskusage                 # by keyword
./run.sh -m known_bug                 # just the open-defect tests
```

`run.sh` creates `.venv/` on first use (needs `python3-venv`) and installs
`requirements.txt`. Docker must be reachable by the current user.

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
| `exec(cmd)` / `bash(script)` | arbitrary commands in the container |
| `last_status()` / `file_log()` / `syslog()` | the three non-screen output sinks |

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
test_packaging.py      install-wide invariants
PLAN.md                per-script mock strategy for all 38 sc_ + 43 related scripts
REPORT.md              coverage and findings
```
