"""End-to-end tests for related-available/927_create_crls.sh.

`927` runs `ejbca.sh ca createcrl` and decides success by grepping the output
for the literal string `CRLs have been created.`.

FAKE-BIN: a stub `ejbca.sh` under a temporary `EJBCA_HOME`. `config/common.conf`
sets `EJBCA_HOME=${EJBCA_HOME:-"/opt/ejbca"}`, so a pre-set environment variable
wins and becomes the seam.

Fidelity gap, stated plainly: no EJBCA installation was available, so the stub's
output is written from the string `927` itself greps for. These tests prove the
script's branching, not that EJBCA prints that sentence. If the real wording has
ever changed across EJBCA versions, `927` would report failure on a successful
run and nothing here would catch it — the assertion and the script share the
same assumption.
"""

from __future__ import annotations

import pytest

SCRIPT = "related-available/927_create_crls.sh"
EJBCA_HOME = "/tmp/927/ejbca"

pytestmark = pytest.mark.slow

SUCCESS_OUTPUT = "CRLs have been created."


def install_ejbca(sc, *, stdout: str = SUCCESS_OUTPUT, exit_code: int = 0) -> None:
    """A stub `ejbca.sh` that records its argv and prints what the test wants."""
    sc.exec(f"mkdir -p {EJBCA_HOME}/bin").check()
    sc.write_file(f"{EJBCA_HOME}/bin/ejbca.sh",
                  "#!/bin/bash\n"
                  f'echo "$@" >> {EJBCA_HOME}/calls.log\n'
                  f"cat <<'EOF'\n{stdout}\nEOF\n"
                  f"exit {exit_code}\n",
                  mode=0o755)


@pytest.fixture
def ejbca(syscheck):
    syscheck.exec(f"rm -rf /tmp/927").check()
    install_ejbca(syscheck)
    return syscheck


def run(sc, **kw):
    return sc.run_script(SCRIPT, env={"EJBCA_HOME": EJBCA_HOME}, **kw)


def calls(sc) -> list[str]:
    if not sc.file_exists(f"{EJBCA_HOME}/calls.log"):
        return []
    return [l for l in sc.read_file(f"{EJBCA_HOME}/calls.log").splitlines() if l.strip()]


# --- the command it issues --------------------------------------------------

def test_it_asks_ejbca_to_create_crls(ejbca):
    run(ejbca)

    assert calls(ejbca) == ["ca createcrl"], calls(ejbca)


# --- the two branches -------------------------------------------------------

def test_the_success_sentence_is_reported_as_ok(ejbca):
    r = run(ejbca)

    msg = r.only()
    assert (msg.level, msg.errno) == ("I", "9271"), r.describe()


def test_output_without_the_success_sentence_is_an_error(ejbca):
    """Anything that is not the expected sentence is a failure, including a
    stack trace or an authorisation refusal."""
    install_ejbca(ejbca, stdout="ERROR: CA is offline")

    r = run(ejbca)

    msg = r.only()
    assert (msg.level, msg.errno) == ("E", "9272"), r.describe()


def test_the_error_message_carries_the_tool_output(ejbca):
    """`DESCR[2]` is `"Create CRL failed (%s)"` and the failure branch passes
    the captured output as `-1`, so an operator sees why it failed."""
    install_ejbca(ejbca, stdout="ERROR: CA is offline")

    r = run(ejbca)

    assert "CA is offline" in r.only().text, r.describe()


def test_a_nonzero_exit_with_the_success_sentence_still_reads_as_success(ejbca):
    """`927` never looks at the exit status — only at the text. Pinned because
    it is the kind of assumption that is invisible until a tool starts failing
    loudly while still printing its usual banner.

    Characterisation, not a defect claim: grepping the output is a reasonable
    choice when the tool's exit codes are unreliable, which is common for
    java-based CLIs."""
    install_ejbca(ejbca, stdout=SUCCESS_OUTPUT, exit_code=3)

    r = run(ejbca)

    assert r.only().errno == "9271", r.describe()


def test_a_missing_ejbca_installation_is_an_error(ejbca):
    """`EJBCA_HOME` pointing nowhere must not read as success — the grep finds
    no success sentence in the shell's "No such file" message."""
    r = ejbca.run_script(SCRIPT, env={"EJBCA_HOME": "/tmp/927/not-installed"})

    assert r.only().errno == "9272", r.describe()


def test_multiline_output_is_flattened_into_one_message(ejbca):
    """`tr -d '\\n'` collapses the output so a multi-line result stays a single
    log line rather than breaking the message format."""
    install_ejbca(ejbca, stdout="first line\nsecond line\nthird line")

    r = run(ejbca)

    assert len(r.messages) == 1, r.describe()
    assert "firstlinesecondlinethirdline" in r.only().text.replace(" ", ""), \
        r.only().text


# --- known defect -----------------------------------------------------------

def test_the_success_message_carries_the_tool_output(ejbca):
    """D78, fixed 2026-09-17. `DESCR[1]` is `"Create CRL run successfully (%s)"`
    — one placeholder — but the success branch passed the captured output as `-2`:

        printlogmess ... -e ${ERRNO[1]} -d "${DESCR[1]}" -2 "$CMD"

    so the single `%s` is filled from the empty `ARG1` and the message reads
    `Create CRL run successfully ()`. The failure branch gets this right with
    `-1`, which is what makes the success branch look deliberate rather than
    typed once and never read.

    Same family as D77 in `917`."""
    r = run(ejbca)

    assert SUCCESS_OUTPUT in r.only().text, r.describe()


def test_help_documents_every_error_code(ejbca):
    res = ejbca.exec([ejbca.script_path(SCRIPT), "--help"])

    for errno in ("9271", "9272", "9273"):
        assert f"{errno} / " in res.output, res.output
