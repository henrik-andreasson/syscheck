"""Checks on what a syscheck *install* looks like, independent of any one script."""

from __future__ import annotations

import pytest


def test_every_script_reports_an_id_and_a_name(syscheck):
    """--scriptid / --scriptname are how syscheck.sh and the bats suite
    identify a script; every script must answer both."""
    listing = syscheck.exec(
        "ls /opt/syscheck/scripts-available/sc_*.sh"
    ).check().stdout.split()

    broken = []
    for path in listing:
        sid = syscheck.exec([path, "--scriptid"]).stdout.strip()
        name = syscheck.exec([path, "--scriptname"]).stdout.strip()
        if not sid or not name:
            broken.append((path, sid, name))
    assert not broken, f"scripts with missing id/name: {broken}"


def test_script_ids_are_unique(syscheck):
    listing = syscheck.exec(
        "ls /opt/syscheck/scripts-available/sc_*.sh"
    ).check().stdout.split()

    seen: dict[str, str] = {}
    clashes = []
    for path in listing:
        sid = syscheck.exec([path, "--scriptid"]).stdout.strip()
        if sid in seen:
            clashes.append((sid, seen[sid], path))
        seen[sid] = path
    assert not clashes, f"duplicate script ids: {clashes}"


@pytest.mark.known_bug
@pytest.mark.xfail(
    strict=True,
    reason="lib/tail_errors_from_ejbca_log.py still has a `#!/usr/bin/python` "
           "shebang. Debian has no /usr/bin/python, so sc_20_errors_ejbcalog.sh "
           "can never read the EJBCA log - commit b8c636f fixed the other two "
           "helpers and missed this one",
)
def test_python_helpers_are_executable_on_a_stock_debian(syscheck):
    helpers = syscheck.exec(
        "ls /opt/syscheck/lib/*.py"
    ).check().stdout.split()

    broken = []
    for path in helpers:
        # run through bash so a missing interpreter surfaces as exit 127
        res = syscheck.exec(f"{path} --help")
        if res.exit_code == 127 or "cannot execute" in res.output:
            shebang = syscheck.exec(["head", "-1", path]).stdout.strip()
            broken.append((path, shebang))
    assert not broken, f"helpers whose interpreter is missing: {broken}"


@pytest.mark.known_bug
@pytest.mark.xfail(
    strict=True,
    reason="logbook.sh lines 91 and 108 call bare `python` with Python 2 syntax "
           "(`print obj[...]` without parentheses); on Debian there is no "
           "`python` at all, so --list output is empty either way",
)
def test_logbook_list_renders_entries(syscheck):
    syscheck.write_file(
        "/var/log/syscheck-logbook.log",
        '{ "FROM": "SYSCHECK", "LOGFMT": "LOGBOOK-1.1", "SCRIPTID": "99", '
        '"LEGACYFMT": "99-01-I-991-PKI 20260101 00:00:00 host: INFO - probe entry" }\n',
    )
    res = syscheck.exec(
        "/opt/syscheck/logbook.sh --list", env={"SYSCHECK_HOME": "/opt/syscheck"}
    )

    assert "probe entry" in res.output, res.output


@pytest.mark.known_bug
@pytest.mark.xfail(
    strict=True,
    reason="var/last_status is committed to git with 291 lines of stale status "
           "from a Nov-2025 build container, and lib/release.sh copies var/ "
           "into the package, so a fresh install reports historical ERRORs "
           "before syscheck has ever run",
)
def test_fresh_install_has_no_pre_existing_status(syscheck):
    syscheck.exec("rm -rf /opt/syscheck/var && cp -a /src/var /opt/syscheck/var").check()
    status = syscheck.read_file("/opt/syscheck/var/last_status")

    stale = [ln for ln in status.splitlines() if ln.strip() and not ln.startswith("#")]
    assert not stale, f"{len(stale)} stale status lines shipped in the package"
