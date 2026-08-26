"""End-to-end tests for scripts-available/sc_41_ra_verifier.sh.

The RA verifier is a vendor tool, so it is replaced by a fake that replays the
three result lines the script greps for. That covers the parsing and the three
independent checks; it does not prove the real tool speaks this dialect.
"""

from __future__ import annotations

import pytest

SCRIPT = "sc_41_ra_verifier.sh"
TOOL_DIR = "/opt/certificate-services/vcc-factoryra-verifier"
TOOL = "verify-factoryra.sh"

ALL_OK = """\
Client Certificate: VALID
Request Verification: OK
Server Certificate: VALID
"""

ALL_BAD = """\
Client Certificate: INVALID
Error <faultstring>request signature could not be verified</faultstring>
Server Certificate: EXPIRED
"""


def config() -> str:
    return (
        "SCRIPTNAME=ra_verifier\n"
        "RA_HOSTNAME=localhost\n"
        "RA_TIMEOUT=10\n"
        f"CHECKTOOL_PATH={TOOL_DIR}\n"
        f"CHECKTOOL={TOOL}\n"
    )


@pytest.fixture
def ra(syscheck):
    syscheck.set_script_config("41", config())
    syscheck.exec("rm -f /tmp/rahealth.log")

    def install_tool(output: str):
        syscheck.exec(f"mkdir -p {TOOL_DIR}").check()
        syscheck.write_file(f"{TOOL_DIR}/{TOOL}", "cat <<'EOT'\n" + output + "EOT\n", mode=0o755)

    syscheck.install_tool = install_tool
    return syscheck


def test_a_missing_tool_is_reported_with_its_path(ra):
    """The regression guard for D15: `-d "$DESCR_3"` named a variable that does
    not exist, so printlogmess got an empty description and the message was
    dropped."""
    ra.exec(f"rm -rf {TOOL_DIR}")
    run = ra.run_script(SCRIPT)

    msg = run.only()
    assert msg.level == "E"
    assert msg.errno == "413"
    assert msg.index == "01"
    assert "health check tool failure" in msg.text
    assert f"{TOOL_DIR}/{TOOL}" in msg.text


def test_a_missing_tool_stops_the_script(ra):
    """Reporting the tool is missing and then running it anyway produced a
    second, meaningless set of results."""
    ra.exec(f"rm -rf {TOOL_DIR}")
    run = ra.run_script(SCRIPT)

    assert len(run.messages) == 1, run.describe()


def test_all_three_checks_passing(ra):
    ra.install_tool(ALL_OK)
    run = ra.run_script(SCRIPT)

    assert len(run.messages) == 3, run.describe()
    assert run.levels == ["I", "I", "I"]
    assert run.errnos == ["411", "411", "411"]
    assert run.indexes == ["01", "02", "03"]


def test_all_three_checks_failing(ra):
    ra.install_tool(ALL_BAD)
    run = ra.run_script(SCRIPT)

    assert len(run.messages) == 3, run.describe()
    assert run.levels == ["E", "E", "E"]
    assert run.errnos == ["412", "412", "412"]


def test_a_single_failing_check_is_isolated(ra):
    ra.install_tool(
        "Client Certificate: VALID\n"
        "Error <faultstring>request signature could not be verified</faultstring>\n"
        "Server Certificate: VALID\n"
    )
    run = ra.run_script(SCRIPT)

    assert run.levels == ["I", "E", "I"], run.describe()
    assert "request signature could not be verified" in run.messages[1].text


def test_help_documents_every_error_code(ra):
    res = ra.exec([ra.script_path(SCRIPT), "--help"])

    for errno in ("411", "412", "413"):
        assert f"{errno} / " in res.output, res.output
