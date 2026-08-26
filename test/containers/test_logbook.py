"""Tests for logbook.sh.

logbook.sh refuses to run as root, so every test drives it as an unprivileged
user. The container has no such user by default, so one is created here.
"""

from __future__ import annotations

import pytest

TIMEOUT = 15
LOGBOOK = "/var/log/syscheck-logbook.log"
USER = "logbookuser"

ENTRY_TEMPLATE = (
    '{{ "FROM": "SYSCHECK", "SYSCHECK_VERSION": "2.0", "LOGFMT": "LOGBOOK-1.1", '
    '"SCRIPTID": "701", "SCRIPTINDEX": "00", "LEVEL": "I", "ERRNO": "7011", '
    '"SYSTEMNAME": "PKI", "DATE": "{date} 09:00:00", "HOSTNAME": "syscheck-test", '
    '"LONGLEVEL": "INFO", "DESCRIPTION": "logbook entry", "USERNAME": "logbookuser", '
    '"LOGENTRY": "{text}", '
    '"LEGACYFMT": "701-00-I-7011-PKI {date} 09:00:00 syscheck-test: INFO - logbook {text}" }}'
)


@pytest.fixture
def logbook(syscheck):
    syscheck.exec(f"id -u {USER} >/dev/null 2>&1 || useradd -m {USER}").check()
    syscheck.exec(f"rm -f {LOGBOOK}")
    return syscheck


def today(syscheck) -> str:
    return syscheck.exec('date +"%Y%m%d"').check().stdout.strip()


def write_entries(syscheck, *texts: str, date: str | None = None) -> None:
    date = date or today(syscheck)
    body = "\n".join(ENTRY_TEMPLATE.format(date=date, text=t) for t in texts) + "\n"
    syscheck.write_file(LOGBOOK, body, mode=0o666)


def run_logbook(syscheck, *args: str):
    """logbook.sh --read pages with `read a`, so feed it EOF on stdin."""
    argv = " ".join(args) or "--read"
    return syscheck.exec(
        f"timeout {TIMEOUT} su {USER} -c "
        f"'SYSCHECK_HOME=/opt/syscheck /opt/syscheck/logbook.sh {argv} < /dev/null'"
    )


def test_json_entries_are_rendered_as_readable_lines(logbook):
    """The regression guard for D7: this printed nothing at all, because the
    renderer called bare `python` with Python 2 `print` syntax."""
    write_entries(logbook, "restarted the CA service")
    res = run_logbook(logbook, "--read")

    assert "restarted the CA service" in res.output, res.output
    assert "701-00-I-7011-PKI" in res.output
    assert '"LEGACYFMT"' not in res.output


def test_every_entry_for_the_day_is_rendered(logbook):
    write_entries(logbook, "first entry", "second entry", "third entry")
    res = run_logbook(logbook, "--read")

    for text in ("first entry", "second entry", "third entry"):
        assert text in res.output, res.output


def test_a_corrupt_row_does_not_hide_the_others(logbook):
    """One unparseable line must not take the whole day's log with it."""
    date = today(logbook)
    good = ENTRY_TEMPLATE.format(date=date, text="good entry")
    logbook.write_file(
        LOGBOOK,
        f"{good}\nPKI {date} this row is not json at all\n",
        mode=0o666,
    )
    res = run_logbook(logbook, "--read")

    assert "good entry" in res.output, res.output
    assert "not json at all" in res.output, "the corrupt row should be shown verbatim"
    assert "Traceback" not in res.output


def test_an_empty_logbook_is_not_an_error(logbook):
    logbook.write_file(LOGBOOK, "", mode=0o666)
    res = run_logbook(logbook, "--read")

    assert "Traceback" not in res.output
    assert "command not found" not in res.output


def test_non_json_logbook_format_is_passed_through(logbook):
    date = today(logbook)
    logbook.exec(
        "printf '%s\\n' 'LOGBOOK_OUTPUTTYPE=NEWFMT' >> /opt/syscheck/config/common.conf"
    ).check()
    logbook.write_file(
        LOGBOOK,
        f"701-00-I-7011-PKI {date} 09:00:00 syscheck-test: INFO - logbook plain entry\n",
        mode=0o666,
    )
    res = run_logbook(logbook, "--read")

    assert "plain entry" in res.output, res.output


def test_refuses_to_run_as_root(syscheck):
    res = syscheck.exec(
        f"timeout {TIMEOUT} env SYSCHECK_HOME=/opt/syscheck "
        "/opt/syscheck/logbook.sh --read < /dev/null"
    )

    assert "restarted" not in res.output
    assert res.exit_code == 0


def test_unknown_option_is_rejected_without_hanging(logbook):
    res = logbook.exec(
        f"timeout {TIMEOUT} su {USER} -c "
        f"'SYSCHECK_HOME=/opt/syscheck /opt/syscheck/logbook.sh --nonsense < /dev/null'"
    )

    assert res.exit_code != 124, "logbook.sh hung until the timeout killed it"
    assert res.exit_code != 0
