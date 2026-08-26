"""End-to-end tests for scripts-available/sc_20_errors_ejbcalog.sh.

Driven against real EJBCA-shaped log files and the real
lib/tail_errors_from_ejbca_log.py helper, so the parsing, the position-file
resume and the IGNORE[] filtering are all covered for real.
"""

from __future__ import annotations

import pytest

SCRIPT = "sc_20_errors_ejbcalog.sh"
LOG = "/tmp/server.log"
POS = "/tmp/ejbca-lastpos"

CLEAN_LOG = """\
2026-08-25 10:00:01,100 INFO  [org.ejbca] Startup complete
2026-08-25 10:00:04,400 INFO  [org.ejbca] heartbeat
"""

ERROR_LOG = """\
2026-08-25 10:00:01,100 INFO  [org.ejbca] Startup complete
2026-08-25 10:00:02,200 ERROR [org.ejbca.core] CA Token is disconnected
2026-08-25 10:00:03,300 ERROR [org.ejbca.core] Error Connecting to EJBCA Database
2026-08-25 10:00:04,400 INFO  [org.ejbca] heartbeat
"""


def config(*, logfile: str = LOG, posfile: str = POS, ignores: tuple[str, ...] = ()) -> str:
    lines = [f'EEL_SERVER_LOG_FILE="{logfile}"', f'EEL_SERVER_LOG_LASTPOSITION="{posfile}"']
    lines += [f'IGNORE[{i}]="{text}"' for i, text in enumerate(ignores)]
    return "\n".join(lines) + "\n"


@pytest.fixture
def ejbca(syscheck):
    syscheck.exec(f"rm -f {POS}")
    return syscheck


def test_clean_log_reports_no_new_errors(ejbca):
    ejbca.write_file(LOG, CLEAN_LOG)
    ejbca.set_script_config("20", config())
    run = ejbca.run_script(SCRIPT)

    msg = run.only()
    assert msg.level == "I"
    assert msg.errno == "201"
    assert msg.text == "No new errors in ejbca server log"


def test_errors_in_the_log_are_reported(ejbca):
    """The regression guard for D6: this used to report INFO 'no new errors'
    because the helper could not start and its failure was discarded."""
    ejbca.write_file(LOG, ERROR_LOG)
    ejbca.set_script_config("20", config())
    run = ejbca.run_script(SCRIPT)

    assert run.levels[0] == "E", run.describe()
    assert run.messages[0].errno == "202"
    assert run.messages[0].text == "New error in log: 2"

    details = [m.text for m in run.messages if m.errno == "204"]
    assert len(details) == 2, run.describe()
    assert any("CA Token is disconnected" in d for d in details)
    assert any("Error Connecting to EJBCA Database" in d for d in details)


def test_helper_diagnostics_are_not_mistaken_for_errors(ejbca):
    """On the first run the helper creates the position file; its 'deltat'
    notice must not land on stdout and be counted as a matched error."""
    ejbca.write_file(LOG, CLEAN_LOG)
    ejbca.set_script_config("20", config())
    run = ejbca.run_script(SCRIPT)

    assert ejbca.file_exists(POS), "first run should create the position file"
    assert run.only().level == "I"
    assert "deltat" not in run.output


def test_already_seen_errors_are_not_reported_twice(ejbca):
    ejbca.write_file(LOG, ERROR_LOG)
    ejbca.set_script_config("20", config())

    first = ejbca.run_script(SCRIPT)
    assert first.levels[0] == "E", first.describe()

    second = ejbca.run_script(SCRIPT)
    assert second.only().level == "I", second.describe()
    assert second.only().text == "No new errors in ejbca server log"


def test_errors_appended_after_the_last_run_are_reported(ejbca):
    ejbca.write_file(LOG, ERROR_LOG)
    ejbca.set_script_config("20", config())
    ejbca.run_script(SCRIPT)

    ejbca.exec(
        f"printf '%s\\n' "
        f"'2026-08-25 11:00:00,000 ERROR [org.ejbca.core] Fresh failure' >> {LOG}"
    ).check()
    run = ejbca.run_script(SCRIPT)

    details = [m.text for m in run.messages if m.errno == "204"]
    assert len(details) == 1, run.describe()
    assert "Fresh failure" in details[0]


def test_ignored_errors_are_filtered_from_the_detail_lines(ejbca):
    ejbca.write_file(LOG, ERROR_LOG)
    ejbca.set_script_config("20", config(ignores=("CA Token is disconnected",)))
    run = ejbca.run_script(SCRIPT)

    details = [m.text for m in run.messages if m.errno == "204"]
    assert len(details) == 1, run.describe()
    assert "Error Connecting to EJBCA Database" in details[0]


def test_missing_logfile_warns(ejbca):
    ejbca.set_script_config("20", config(logfile="/does/not/exist.log"))
    run = ejbca.run_script(SCRIPT)

    msg = run.only()
    assert msg.level == "W"
    assert msg.errno == "203"
    assert "/does/not/exist.log" in msg.text


def test_a_broken_helper_is_reported_as_an_error(ejbca):
    """The core of D6: if the helper cannot run, say so. Reporting 'no new
    errors' for a log that was never read is the worst possible outcome."""
    ejbca.write_file(LOG, ERROR_LOG)
    ejbca.set_script_config("20", config())
    ejbca.write_file(
        "/opt/syscheck/lib/tail_errors_from_ejbca_log.py",
        "#!/usr/bin/python-that-does-not-exist\nprint('unreachable')\n",
        mode=0o755,
    )
    run = ejbca.run_script(SCRIPT)

    msg = run.only()
    assert msg.level == "E", run.describe()
    assert msg.errno == "205"
    assert "Log checker tool failed" in msg.text


def test_a_helper_that_crashes_is_reported_as_an_error(ejbca):
    ejbca.write_file(LOG, ERROR_LOG)
    ejbca.set_script_config("20", config())
    ejbca.write_file(
        "/opt/syscheck/lib/tail_errors_from_ejbca_log.py",
        "#!/usr/bin/python3\nimport sys\nsys.stderr.write('boom\\n')\nsys.exit(3)\n",
        mode=0o755,
    )
    run = ejbca.run_script(SCRIPT)

    msg = run.only()
    assert msg.level == "E", run.describe()
    assert msg.errno == "205"
    assert "boom" in msg.text


def test_help_documents_the_new_error_code(ejbca):
    res = ejbca.exec([ejbca.script_path(SCRIPT), "--help"])

    for errno in ("201", "202", "203", "204", "205"):
        assert f"{errno} / " in res.output, res.output
