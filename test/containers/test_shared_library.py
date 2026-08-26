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

    line = run.output.strip().splitlines()[0]
    tail = line.split(" ", 3)[3]
    assert len(tail) == 40, f"expected 40 chars, got {len(tail)}: {tail!r}"


PLM_PRELUDE = (
    "export SYSCHECK_HOME=/opt/syscheck; "
    "source /opt/syscheck/config/syscheck-scripts.conf; "
    "PRINTTOSCREEN=1 SAVELASTSTATUS=0 SENDTOSYSLOG=0 PRINTTOFILE=0; "
)


@pytest.mark.parametrize(
    "args, missing",
    [
        ('-i 99 -x 01 -l E -e 991 -d "boom"', "scriptname"),
        ('-n probe -x 01 -l E -e 991 -d "boom"', "scriptid"),
        ('-n probe -i 99 -l E -e 991 -d "boom"', "scriptindex"),
        ('-n probe -i 99 -x 01 -l E -e 991', "description"),
        ('-n probe -i 99 -x 01 -e 991 -d "boom"', "bad level"),
        ('-n probe -i 99 -x 01 -l Q -e 991 -d "boom"', "bad level"),
    ],
)
def test_printlogmess_rejects_a_malformed_call(syscheck, args, missing):
    """A malformed call is a bug in the caller: say so on stderr, return
    non-zero, and do not fabricate a log line."""
    res = syscheck.bash(PLM_PRELUDE + f"printlogmess {args}; echo rc=$?")

    assert missing in res.stderr, res.output
    assert "printlogmess:" in res.stderr
    assert "rc=1" in res.stdout, res.output
    assert "PKI" not in res.output


def test_printlogmess_reports_the_calling_script(syscheck):
    res = syscheck.bash(PLM_PRELUDE + 'printlogmess -n probe -i 99 -l E -e 991 -d "boom"')

    assert "called by" in res.stderr, res.stderr
    assert "boom" in res.stderr, "the offending call should be echoed back"


def test_printlogmess_accepts_a_well_formed_call(syscheck):
    res = syscheck.bash(
        PLM_PRELUDE + 'printlogmess -n probe -i 99 -x 01 -l E -e 991 -d "boom"; echo rc=$?'
    )

    assert "99-01-E-991-PKI" in res.output, res.output
    assert "boom" in res.output
    assert "rc=0" in res.stdout


def test_printlogmess_does_not_exit_its_caller(syscheck):
    """The guards used to `exit`, which killed the calling script's remaining
    checks. A bad call must cost one message, not the whole run."""
    res = syscheck.bash(
        "export SYSCHECK_HOME=/opt/syscheck; "
        "source /opt/syscheck/config/syscheck-scripts.conf; "
        "PRINTTOSCREEN=1 SAVELASTSTATUS=0 SENDTOSYSLOG=0 PRINTTOFILE=0; "
        'printlogmess -n probe -i 99 -x "" -l E -e 991 -d "first"; '
        'echo CALLER-STILL-ALIVE'
    )
    assert "CALLER-STILL-ALIVE" in res.output, res.output


def test_one_bad_config_entry_does_not_disable_the_whole_check(syscheck):
    """Regression guard for the original defect: an empty FILESYSTEM entry used
    to abort sc_01 entirely, leaving every later filesystem unchecked."""
    syscheck.fill_filesystem("/mnt/tfs_a", 60)
    syscheck.set_script_config(
        "01",
        'FILESYSTEM[0]=""\nUSAGEPERCENT[0]=90\n'
        'FILESYSTEM[1]="/mnt/tfs_a"\nUSAGEPERCENT[1]=95\n'
        'FILESYSTEM[2]="/mnt/tfs_b"\nUSAGEPERCENT[2]=95\n',
    )
    run = syscheck.run_script(SC01)

    assert len(run.messages) == 3, run.describe()
    assert run.levels == ["E", "I", "I"]
    assert run.indexes == ["01", "02", "03"]


TIMEOUT = 10


@pytest.mark.parametrize("flag", ["-c", "-z", "-q", "--nonsense"])
def test_unknown_option_is_rejected_without_hanging(syscheck, flag):
    """An option the case statement does not handle must never reach the top of
    the `while true` loop: with no `shift` it spins forever."""
    res = syscheck.exec(f"timeout {TIMEOUT} {syscheck.script_path(SC01)} {flag}")

    assert res.exit_code != 124, f"{flag} hung until the {TIMEOUT}s timeout killed it"
    assert res.exit_code != 0, f"{flag} should be a usage error"


@pytest.mark.parametrize("flag", ["-z", "--nonsense"])
def test_unknown_option_does_not_run_the_check(syscheck, flag):
    """getopt writes a usable '--' to stdout even when it fails, so without an
    exit the script printed help and then ran the check anyway."""
    syscheck.exec(f"timeout {TIMEOUT} {syscheck.script_path(SC01)} {flag}")

    assert syscheck.last_status().strip() == "", syscheck.last_status()
    assert syscheck.file_log().strip() == ""


@pytest.mark.parametrize(
    "flag, expected",
    [("-i", "01"), ("-n", "diskusage"), ("-a", "Disk usage"),
     ("--scriptid", "01"), ("--scriptname", "diskusage"),
     ("--scripthumanname", "Disk usage")],
)
def test_metadata_flags_have_working_short_and_long_forms(syscheck, flag, expected):
    res = syscheck.exec(f"timeout {TIMEOUT} {syscheck.script_path(SC01)} {flag}")

    assert res.stdout.strip() == expected, res.output


def test_syscheck_sh_rejects_an_unknown_option_without_hanging(syscheck):
    res = syscheck.exec(f"timeout {TIMEOUT} {syscheck.home}/syscheck.sh -c")

    assert res.exit_code != 124, f"syscheck.sh hung until the {TIMEOUT}s timeout"
    assert res.exit_code != 0
