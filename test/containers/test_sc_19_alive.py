"""End-to-end tests for scripts-available/sc_19_alive.sh.

The whole job of this script is to emit one heartbeat, so the message text is
the entire contract.
"""

from __future__ import annotations

SCRIPT = "sc_19_alive.sh"


def test_emits_a_single_heartbeat(syscheck):
    run = syscheck.run_script(SCRIPT)

    msg = run.only()
    assert msg.level == "I"
    assert msg.scriptid == "19"
    assert msg.errno == "193"
    assert msg.index == "01"
    assert msg.scriptname == "alive"


def test_the_heartbeat_carries_the_message_text(syscheck):
    """The regression guard for D10: `-d "$DESCR[3]"` expanded DESCR[0], which
    is unset, followed by the literal [3], so the heartbeat read "alive [3]"."""
    run = syscheck.run_script(SCRIPT)

    assert run.only().text == "I'm alive", run.describe()


def test_the_heartbeat_reaches_syslog(syscheck):
    syscheck.run_script(SCRIPT)
    syscheck.exec(
        "for i in $(seq 20); do grep -q 19-01-I-193-PKI /var/log/syslog && break; sleep 0.1; done"
    )

    assert "I'm alive" in syscheck.syslog()
