"""End-to-end tests for scripts-available/sc_44_cert_from_webserver.sh.

The happy paths run against a real TLS server (`openssl s_server`) holding a
real certificate generated with a chosen lifetime, so the handshake, the PEM
extraction and the expiry arithmetic are all exercised for real. The timeout
path points at an unroutable address from TEST-NET-1, which black-holes the
connection rather than refusing it.
"""

from __future__ import annotations

import time

import pytest

SCRIPT = "sc_44_cert_from_webserver.sh"
BLACKHOLE_IP = "192.0.2.1"
TLS_PORT = 4443


def config(*entries: tuple[str, int, int, int, str], timeout: int = 5) -> str:
    lines = [f"TIMEOUT={timeout}"]
    for i, (service, port, warn, err, ip) in enumerate(entries):
        lines += [
            f"SERVICENAME[{i}]={service}",
            f"PORTNO[{i}]={port}",
            f"WARNTIME[{i}]={warn}",
            f"ERRTIME[{i}]={err}",
            f"HOST_IP[{i}]={ip}",
        ]
    return "\n".join(lines) + "\n"


@pytest.fixture
def tls_server(syscheck):
    """Start openssl s_server with a cert whose lifetime the test chooses."""
    started: list[int] = []

    def _start(days_valid: int, port: int = TLS_PORT, cn: str = "test.example.org"):
        syscheck.exec(
            f"openssl req -x509 -newkey rsa:2048 -nodes -keyout /tmp/k{port}.pem "
            f"-out /tmp/c{port}.pem -days {days_valid} -subj '/CN={cn}' 2>/dev/null"
        ).check()
        syscheck.exec(
            f"nohup openssl s_server -accept {port} -cert /tmp/c{port}.pem "
            f"-key /tmp/k{port}.pem -www >/tmp/s{port}.log 2>&1 &"
        )
        syscheck.exec(
            f"for i in $(seq 40); do "
            f"(echo > /dev/tcp/127.0.0.1/{port}) 2>/dev/null && break; sleep 0.25; done"
        )
        started.append(port)
        return port

    yield _start
    for port in started:
        syscheck.exec(f"pkill -f 's_server -accept {port}' || true")


def test_a_valid_certificate_is_reported_ok(syscheck, tls_server):
    tls_server(days_valid=365)
    syscheck.set_script_config(
        "44", config(("test.example.org", TLS_PORT, 60, 40, "127.0.0.1"))
    )
    run = syscheck.run_script(SCRIPT)

    assert run.levels[0] == "I", run.describe()
    assert run.messages[0].errno == "441"
    assert "Cert ok" in run.messages[0].text


def test_a_certificate_inside_the_warn_window_warns(syscheck, tls_server):
    tls_server(days_valid=50)
    syscheck.set_script_config(
        "44", config(("test.example.org", TLS_PORT, 60, 40, "127.0.0.1"))
    )
    run = syscheck.run_script(SCRIPT)

    assert run.levels[0] == "W", run.describe()
    assert run.messages[0].errno == "442"


def test_a_certificate_inside_the_error_window_errors(syscheck, tls_server):
    tls_server(days_valid=30)
    syscheck.set_script_config(
        "44", config(("test.example.org", TLS_PORT, 60, 40, "127.0.0.1"))
    )
    run = syscheck.run_script(SCRIPT)

    assert run.levels[0] == "E", run.describe()
    assert run.messages[0].errno == "443"


def test_an_unroutable_host_gives_up_after_the_timeout(syscheck):
    """The regression guard for D16: with no timeout this ran forever."""
    syscheck.set_script_config(
        "44", config(("blackhole.example.org", 443, 60, 40, BLACKHOLE_IP), timeout=5)
    )

    start = time.monotonic()
    res = syscheck.exec(f"timeout 60 {syscheck.script_path(SCRIPT)} --screen")
    elapsed = time.monotonic() - start

    assert res.exit_code != 124, "script hung past the 60s outer timeout"
    assert elapsed < 30, f"took {elapsed:.1f}s for a single 5s-timeout check"


def test_an_unroutable_host_is_reported_as_an_error(syscheck):
    syscheck.set_script_config(
        "44", config(("blackhole.example.org", 443, 60, 40, BLACKHOLE_IP), timeout=5)
    )
    run = syscheck.run_script(SCRIPT)

    assert run.levels[0] == "E", run.describe()
    assert run.messages[0].errno == "447"
    assert "Cant get server certificate" in run.messages[0].text


def test_a_closed_port_is_reported_as_an_error(syscheck):
    syscheck.set_script_config(
        "44", config(("localhost", 9, 60, 40, "127.0.0.1"), timeout=5)
    )
    run = syscheck.run_script(SCRIPT)

    assert run.levels[0] == "E", run.describe()
    assert run.messages[0].errno == "447"


def test_the_timeout_is_configurable(syscheck):
    syscheck.set_script_config(
        "44", config(("blackhole.example.org", 443, 60, 40, BLACKHOLE_IP), timeout=1)
    )

    start = time.monotonic()
    syscheck.run_script(SCRIPT)
    fast = time.monotonic() - start

    syscheck.set_script_config(
        "44", config(("blackhole.example.org", 443, 60, 40, BLACKHOLE_IP), timeout=8)
    )
    start = time.monotonic()
    syscheck.run_script(SCRIPT)
    slow = time.monotonic() - start

    assert slow > fast + 3, f"1s timeout took {fast:.1f}s, 8s timeout took {slow:.1f}s"


def test_the_timeout_defaults_to_five_seconds_when_unset(syscheck):
    syscheck.set_script_config(
        "44",
        config(("blackhole.example.org", 443, 60, 40, BLACKHOLE_IP)).replace(
            "TIMEOUT=5\n", ""
        ),
    )

    start = time.monotonic()
    run = syscheck.run_script(SCRIPT)
    elapsed = time.monotonic() - start

    assert 3 < elapsed < 20, f"expected the 5s default, took {elapsed:.1f}s"
    assert run.levels[0] == "E", run.describe()


def test_every_error_code_the_script_uses_is_defined(syscheck):
    res = syscheck.exec([syscheck.script_path(SCRIPT), "--help"])

    for errno in ("441", "442", "443", "444", "445", "446", "447", "448"):
        assert f"{errno} / " in res.output, res.output
