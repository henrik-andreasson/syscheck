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


def test_python_helpers_are_executable_on_a_stock_debian(syscheck):
    """Regression guard for D6: a `#!/usr/bin/python` shebang left
    sc_20_errors_ejbcalog.sh silently reporting a clean EJBCA log it had never
    managed to read."""
    helpers = syscheck.exec(
        "ls /opt/syscheck/lib/*.py"
    ).check().stdout.split()

    broken = []
    for path in helpers:
        res = syscheck.exec(f"{path} --help")
        if res.exit_code == 127 or "cannot execute" in res.output:
            shebang = syscheck.exec(["head", "-1", path]).stdout.strip()
            broken.append((path, shebang))
    assert not broken, f"helpers whose interpreter is missing: {broken}"


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
