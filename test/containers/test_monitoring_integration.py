"""Tests for the Icinga / OP5 integration in lib/printlogmess.sh.

This is the path that actually feeds monitoring: syscheck runs from cron and
*pushes* a passive check result to the API, mapping its own level to a
status_code. Nothing reads the scripts' exit status, so the payload built here
is the whole contract.

A mock HTTP endpoint stands in for the Icinga/OP5 API and records every request
so tests can assert on the exact body that was sent.
"""

from __future__ import annotations

import json

import pytest

MOCK_PORT = 8899
MOCK_LOG = "/tmp/monitoring-requests.log"

MOCK_SERVER = r'''#!/usr/bin/python3
import http.server, json, os, sys

LOG = os.environ.get("MOCK_LOG", "/tmp/monitoring-requests.log")

class Handler(http.server.BaseHTTPRequestHandler):
    def _record(self):
        length = int(self.headers.get("Content-Length") or 0)
        body = self.rfile.read(length).decode("utf-8", "replace") if length else ""
        with open(LOG, "a") as fh:
            fh.write(json.dumps({
                "method": self.command,
                "path": self.path,
                "auth": self.headers.get("Authorization", ""),
                "content_type": self.headers.get("Content-Type", ""),
                "body": body,
            }) + "\n")
        payload = b"Successfully submitted the command"
        self.send_response(200)
        self.send_header("Content-Length", str(len(payload)))
        self.end_headers()
        self.wfile.write(payload)

    do_POST = _record
    do_GET = _record

    def log_message(self, *a):
        pass

http.server.HTTPServer(("127.0.0.1", int(sys.argv[1])), Handler).serve_forever()
'''


@pytest.fixture
def monitoring(syscheck):
    """A syscheck container with a mock monitoring API on 127.0.0.1:8899."""
    syscheck.write_file("/usr/local/bin/mock-monitoring", MOCK_SERVER, mode=0o755)
    syscheck.exec(f"rm -f {MOCK_LOG}")
    syscheck.exec(
        f"nohup /usr/local/bin/mock-monitoring {MOCK_PORT} >/tmp/mock.out 2>&1 &",
    )
    syscheck.exec(
        f"for i in $(seq 30); do "
        f"  (echo > /dev/tcp/127.0.0.1/{MOCK_PORT}) 2>/dev/null && break; sleep 0.2; "
        f"done"
    )
    return syscheck


def requests_made(syscheck) -> list[dict]:
    if not syscheck.file_exists(MOCK_LOG):
        return []
    return [json.loads(l) for l in syscheck.read_file(MOCK_LOG).splitlines() if l.strip()]


def emit(syscheck, level: str, backend: str, descr: str = "the check failed") -> None:
    """Drive printlogmess once with the given backend pointed at the mock."""
    op5 = "1" if backend == "op5" else "0"
    icinga = "1" if backend == "icinga" else "0"
    syscheck.write_file(
        "/opt/syscheck/config/monitoring.conf",
        'ICINGA_USER="root"\nICINGA_PASS="secret"\n'
        f'ICINGA_API_URL="http://127.0.0.1:{MOCK_PORT}/v1/actions/"\n'
        'OP5_USER="root"\nOP5_PASS="secret"\n'
        f'OP5_API_URL="http://127.0.0.1:{MOCK_PORT}/api/command"\n',
    )
    syscheck.bash(
        "export SYSCHECK_HOME=/opt/syscheck; "
        "source /opt/syscheck/config/syscheck-scripts.conf; "
        f"SENDTO_OP5={op5} SENDTO_ICINGA={icinga} "
        "PRINTTOSCREEN=0 SAVELASTSTATUS=0 SENDTOSYSLOG=0 PRINTTOFILE=0 "
        f'printlogmess -n probe -i 99 -x 01 -l {level} -e 991 -d "{descr}"'
    )


# ------------------------------------------------------------------- OP5 --


@pytest.mark.parametrize("level, status_code", [("I", "0"), ("W", "1"), ("E", "2")])
def test_op5_maps_syscheck_level_to_status_code(monitoring, level, status_code):
    """I/W/E must arrive as OK/WARNING/CRITICAL. This mapping is the whole
    reason monitoring sees anything at all."""
    emit(monitoring, level, "op5")

    reqs = requests_made(monitoring)
    assert len(reqs) == 1, reqs
    body = json.loads(reqs[0]["body"])
    assert body["status_code"] == status_code
    assert body["service_description"] == "sc_probe_99_01"
    assert "the check failed" in body["plugin_output"]


def test_op5_sends_a_parseable_json_body(monitoring):
    emit(monitoring, "E", "op5")

    body = json.loads(requests_made(monitoring)[0]["body"])
    assert set(body) == {"host_name", "service_description", "status_code", "plugin_output"}


# ---------------------------------------------------------------- Icinga --


def test_icinga_receives_a_request_at_all(monitoring):
    emit(monitoring, "E", "icinga")

    reqs = requests_made(monitoring)
    assert len(reqs) == 1, reqs
    assert reqs[0]["method"] == "POST"
    # note the shipped ICINGA_API_URL ends in "/" and printlogmess.sh:105 adds
    # another, so the real path contains "//" - harmless, but faithful here
    assert "process-check-result" in reqs[0]["path"]
    assert "host=" in reqs[0]["path"]


@pytest.mark.known_bug
@pytest.mark.xfail(
    strict=True,
    reason="printlogmess.sh:105 single-quotes the Icinga -d payload, so "
           "$status_code, ${MESSAGE} and ${check_source} are never expanded; "
           "Icinga receives those literal strings and the body is not even "
           "valid JSON",
)
@pytest.mark.parametrize("level, status_code", [("I", "0"), ("W", "1"), ("E", "2")])
def test_icinga_maps_syscheck_level_to_exit_status(monitoring, level, status_code):
    emit(monitoring, level, "icinga")

    body = json.loads(requests_made(monitoring)[0]["body"])
    assert str(body["exit_status"]) == status_code
    assert "the check failed" in body["plugin_output"]


@pytest.mark.known_bug
@pytest.mark.xfail(
    strict=True,
    reason="config/monitoring.conf already ends OP5_API_URL with "
           "/PROCESS_SERVICE_CHECK_RESULT and printlogmess.sh:86 appends it "
           "again, so the shipped config posts to "
           "/PROCESS_SERVICE_CHECK_RESULT/PROCESS_SERVICE_CHECK_RESULT",
)
def test_op5_url_from_the_shipped_config_is_not_doubled(syscheck):
    syscheck.write_file("/usr/local/bin/mock-monitoring", MOCK_SERVER, mode=0o755)
    syscheck.exec(f"rm -f {MOCK_LOG}")
    syscheck.exec(f"nohup /usr/local/bin/mock-monitoring {MOCK_PORT} >/tmp/mock.out 2>&1 &")
    syscheck.exec(
        f"for i in $(seq 30); do (echo > /dev/tcp/127.0.0.1/{MOCK_PORT}) 2>/dev/null && break; sleep 0.2; done"
    )
    # the shipped config's URL shape, only the host swapped for the mock
    syscheck.write_file(
        "/opt/syscheck/config/monitoring.conf",
        'OP5_USER="root"\nOP5_PASS="secret"\n'
        f'OP5_API_URL="http://127.0.0.1:{MOCK_PORT}/api/command/PROCESS_SERVICE_CHECK_RESULT"\n',
    )
    syscheck.bash(
        "export SYSCHECK_HOME=/opt/syscheck; "
        "source /opt/syscheck/config/syscheck-scripts.conf; "
        "SENDTO_OP5=1 SENDTO_ICINGA=0 "
        "PRINTTOSCREEN=0 SAVELASTSTATUS=0 SENDTOSYSLOG=0 PRINTTOFILE=0 "
        'printlogmess -n probe -i 99 -x 01 -l E -e 991 -d "boom"'
    )

    path = requests_made(syscheck)[0]["path"]
    assert path.count("PROCESS_SERVICE_CHECK_RESULT") == 1, path
