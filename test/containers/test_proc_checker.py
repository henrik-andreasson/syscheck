"""Tests for lib/proc_checker.sh.

Five Phase 1 scripts (05, 12, 15, 16, 30) answer "is this process
running?" by calling this helper and testing whether its stdout came back
empty. A defect here is therefore a defect in all of them at once, which is
what makes it worth covering once on its own — the same argument that applied
to `printlogmess`.

Its documented interface is

    proc_checker.sh <pid-file>|<pid> <procname>

so there are three input shapes to cover: a pidfile, a bare pid, and a name
used as the fallback when the pidfile is absent.

A note for whoever extends this file: do *not* build the "process is gone"
cases by starting a process and killing it. PID 1 in the test image is
`sleep infinity`, which never reaps its orphans, so a killed process lingers as
a zombie and `ps --pid` still prints a line for it. That is an artefact of the
container, not how a real host behaves. Use `free_pid()` instead.
"""

from __future__ import annotations

import pytest

CHECKER = "lib/proc_checker.sh"
PIDFILE = "/var/run/probe.pid"


@pytest.fixture
def checker(syscheck):
    """The helper's absolute path, on a container with no stray processes."""
    # reset() restores the install but does not clean /var/run
    syscheck.exec(f"rm -f {PIDFILE}")
    syscheck.checker = f"{syscheck.home}/{CHECKER}"
    return syscheck


def test_a_pidfile_holding_a_live_pid_reports_the_process(checker):
    pid = checker.start_process("probed")
    checker.write_file(PIDFILE, f"{pid}\n")

    res = checker.exec([checker.checker, PIDFILE, "probed"])

    assert res.exit_code == 0, res.output
    assert str(pid) in res.stdout, res.output
    assert "probed" in res.stdout, res.output


def test_a_pidfile_holding_a_stale_pid_reports_nothing(checker):
    """The pidfile survived but the process did not — the case a stale pidfile
    after an unclean shutdown produces."""
    checker.write_file(PIDFILE, f"{checker.free_pid()}\n")

    res = checker.exec([checker.checker, PIDFILE, "probed"])

    assert res.stdout.strip() == "", res.output
    assert res.exit_code != 0


def test_a_process_is_found_by_name_when_the_pidfile_is_absent(checker):
    """The fallback every caller relies on, since none of the shipped pidfile
    paths exist on a host that installs its daemons anywhere else."""
    checker.start_process("probed")

    res = checker.exec([checker.checker, "/no/such/probe.pid", "probed"])

    assert res.exit_code == 0, res.output
    assert "probed" in res.stdout, res.output


def test_a_process_that_is_not_running_reports_nothing(checker):
    res = checker.exec([checker.checker, "/no/such/ghost.pid", "ghostd"])

    assert res.stdout.strip() == "", res.output
    assert res.exit_code != 0


def test_the_checkers_own_command_line_is_not_mistaken_for_the_process(checker):
    """`proc_checker.sh /no/such/ghost.pid ghostd` itself contains the string
    `ghostd`, so without the `grep -v proc_checker.sh` filter the helper would
    always find its own argv and report every process as running."""
    res = checker.exec([checker.checker, "/no/such/ghost.pid", "ghostd"])

    assert "proc_checker" not in res.stdout, res.output
    assert res.stdout.strip() == "", res.output


def test_no_arguments_prints_usage(checker):
    res = checker.exec([checker.checker])

    assert res.exit_code == 1
    assert "<pid-file>" in res.output, res.output


def test_a_bare_pid_is_checked_by_pid_rather_than_by_name(checker):
    """Given a pid, the helper must check that pid. Passing a name that cannot
    match proves which branch ran.

    The regression guard for D21: the test used to be
    `elif [ $(isdigit $1) ]`, which captures isdigit's *stdout*. isdigit
    reports through its return status and prints nothing, so the string was
    always empty, the branch was dead, and the documented bare-pid mode fell
    through to a name lookup."""
    pid = checker.start_process("probed")

    res = checker.exec([checker.checker, str(pid), "a-name-that-matches-nothing"])

    assert "probed" in res.stdout, res.output


def test_a_bare_pid_without_a_procname_is_still_checked(checker):
    """Same branch as above with no name at all: before D21 was fixed there was
    no arm left to match, so the helper printed its usage instead of checking
    the pid it was given."""
    pid = checker.start_process("probed")

    res = checker.exec([checker.checker, str(pid)])

    assert "probed" in res.stdout, res.output
