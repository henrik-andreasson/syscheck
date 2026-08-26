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


def test_fresh_install_has_no_pre_existing_status(syscheck):
    syscheck.exec("rm -rf /opt/syscheck/var && cp -a /src/var /opt/syscheck/var").check()
    status = syscheck.read_file("/opt/syscheck/var/last_status")

    stale = [ln for ln in status.splitlines() if ln.strip() and not ln.startswith("#")]
    assert not stale, f"{len(stale)} stale status lines shipped in the package"


def _error_code_usage():
    import re
    from syscheck_harness import REPO_ROOT

    out = []
    for folder, pattern in (("scripts-available", "sc_*.sh"), ("related-available", "9*.sh")):
        for path in sorted((REPO_ROOT / folder).glob(pattern)):
            src = path.read_text(errors="replace")
            declared = re.search(r"^NO_OF_ERR=(\d+)", src, re.M)
            if not declared:
                continue
            declared = int(declared.group(1))
            used = sorted({int(n) for n in re.findall(r"ERRNO\[(\d+)\]", src)})
            sid = re.search(r"^SCRIPTID=(\S+)", src, re.M)
            sid = sid.group(1).strip('"') if sid else None
            lang = REPO_ROOT / "lang" / f"{sid}.english"
            descr = set()
            if lang.exists():
                descr = {int(n) for n in re.findall(r"^DESCR\[(\d+)\]", lang.read_text(errors="replace"), re.M)}
            out.append((path.name, declared, used, descr))
    return out


def test_no_of_err_covers_every_errno_index_used():
    offenders = {
        name: (declared, max(used))
        for name, declared, used, _ in _error_code_usage()
        if used and max(used) > declared
    }
    assert not offenders, f"NO_OF_ERR too low: {offenders}"


def test_every_errno_index_used_has_a_description():
    offenders = {
        name: sorted(set(used) - descr)
        for name, _, used, descr in _error_code_usage()
        if set(used) - descr
    }
    assert not offenders, f"ERRNO[] used with no DESCR[]: {offenders}"


@pytest.mark.known_bug
@pytest.mark.xfail(
    strict=True,
    reason="NO_OF_ERR promises more codes than the language file defines, so "
           "--help prints blank entries for them",
)
def test_help_does_not_list_undefined_error_codes():
    offenders = {
        name: sorted(n for n in range(1, declared + 1) if n not in descr)
        for name, declared, _, descr in _error_code_usage()
        if descr and any(n not in descr for n in range(1, declared + 1))
    }
    assert not offenders, f"NO_OF_ERR promises codes the lang file lacks: {offenders}"
