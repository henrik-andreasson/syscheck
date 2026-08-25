"""Tests for lib/libsyscheck.sh and lib/printlogmess.sh.

These are shared by every script, so a defect here is a defect in all 38 of
them. Kept separate from the per-script suites for exactly that reason.
"""

from __future__ import annotations

import pytest

SC01 = "sc_01_diskusage.sh"


def test_addonetoindex_zero_pads(syscheck):
    res = syscheck.bash(
        "source /opt/syscheck/lib/printlogmess.sh; "
        "for n in 0 8 9 98 99; do addOneToIndex $n; echo; done"
    ).check()
    assert res.stdout.split() == ["01", "09", "10", "99", "100"]


def test_getconfig_refuses_to_run_with_a_missing_config(syscheck):
    syscheck.exec("rm -f /opt/syscheck/config/01.conf").check()
    run = syscheck.run_script(SC01)

    assert "cant open configfile" in run.output
    assert run.messages == []


def test_getlangfiles_refuses_to_run_with_a_missing_language_file(syscheck):
    syscheck.exec("rm -f /opt/syscheck/lang/01.english").check()
    run = syscheck.run_script(SC01)

    assert "cant open langfile" in run.output
    assert run.messages == []


def test_syscheck_on_hold_suppresses_the_check(syscheck):
    """The hold file must stop the check from running and reporting."""
    syscheck.write_file("/opt/syscheck/var/syscheck-on-hold", "operator: maintenance\n")
    run = syscheck.run_script(SC01)

    assert not any(m.scriptname == "diskusage" for m in run.messages), run.describe()
    assert "diskusage" not in syscheck.file_log()


@pytest.mark.known_bug
@pytest.mark.xfail(
    strict=True,
    reason='libsyscheck.sh:82 is `printf "00" "0" $WARN "00" "SYSCHECK IS ON '
           'HOLD BY: ..."` - the format string has no conversion specifiers, so '
           "printf prints the literal 00 and discards all five arguments; the "
           "operator is never told why the check produced nothing",
)
def test_syscheck_on_hold_tells_the_operator_who_holds_it(syscheck):
    syscheck.write_file("/opt/syscheck/var/syscheck-on-hold", "operator: maintenance\n")
    run = syscheck.run_script(SC01)

    assert "SYSCHECK IS ON HOLD BY" in run.output, run.output
    assert "operator" in run.output


@pytest.mark.known_bug
@pytest.mark.xfail(
    strict=True,
    reason="libsyscheck.sh:81 shells out to `sudo printlogmess-cli.sh` to log "
           "the hold, so on a host without sudo (or when already root) the hold "
           "notice never reaches syslog and a bare error is printed instead",
)
def test_syscheck_on_hold_is_logged_without_requiring_sudo(syscheck):
    syscheck.exec("rm -f /usr/bin/sudo /usr/local/bin/sudo")
    syscheck.write_file("/opt/syscheck/var/syscheck-on-hold", "operator: maintenance\n")
    run = syscheck.run_script(SC01)

    assert "sudo: command not found" not in run.output, run.output


def test_message_is_truncated_to_messagelength(syscheck):
    syscheck.set_script_config(
        "01",
        'FILESYSTEM[0]="/does/not/exist"\nUSAGEPERCENT[0]=90\nMESSAGELENGTH=40\n',
    )
    run = syscheck.run_script(SC01)

    # NEWFMT is "<prefix> <date> <time> <message>" where only the message is capped
    line = run.output.strip().splitlines()[0]
    tail = line.split(" ", 3)[3]
    assert len(tail) == 40, f"expected 40 chars, got {len(tail)}: {tail!r}"


@pytest.mark.known_bug
@pytest.mark.xfail(
    strict=True,
    reason="printlogmess silently drops the message when a required argument is "
           "empty: it prints 'scriptindex must be passed' / 'wrong type of "
           "LEVEL ()' on stdout and returns, so nothing reaches syslog, "
           "last_status or the monitoring API",
)
def test_printlogmess_with_an_empty_scriptindex_still_reports_something(syscheck):
    res = syscheck.bash(
        "export SYSCHECK_HOME=/opt/syscheck; "
        "source /opt/syscheck/config/syscheck-scripts.conf; "
        "PRINTTOSCREEN=1 SAVELASTSTATUS=0 SENDTOSYSLOG=0 PRINTTOFILE=0 "
        'printlogmess -n probe -i 99 -x "" -l E -e 991 -d "something broke"'
    )
    assert "something broke" in res.output, res.output


@pytest.mark.known_bug
@pytest.mark.xfail(
    strict=True,
    reason="libsyscheck.sh:17 declares short option -c in the getopt string but "
           "default_script_getopt has no case arm for it, so the argument loop "
           "never shifts and every syscheck script spins forever on -c",
)
def test_declared_but_unhandled_short_option_does_not_hang(syscheck):
    res = syscheck.exec(f"timeout 10 {syscheck.script_path(SC01)} -c")
    assert res.exit_code != 124, "script hung until the 10s timeout killed it"
