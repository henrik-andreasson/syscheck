"""Sanity checks on the harness itself, so a broken fixture is not mistaken
for a broken syscheck script."""

from __future__ import annotations


def test_syscheck_is_installed(syscheck):
    assert syscheck.file_exists("/opt/syscheck/syscheck.sh")
    assert syscheck.file_exists("/opt/syscheck/config/common.conf")
    assert syscheck.file_exists("/opt/syscheck/lang/common.english")
    assert syscheck.file_exists("/opt/syscheck/scripts-available/sc_01_diskusage.sh")


def test_tmpfs_mounts_are_present_and_writable(syscheck):
    for mount in ("/mnt/tfs_a", "/mnt/tfs_b"):
        res = syscheck.exec(f"df -Ph {mount} | tail -1")
        assert res.exit_code == 0, res.stderr
        assert mount in res.stdout
        assert syscheck.exec(f"touch {mount}/probe").exit_code == 0


def test_fill_filesystem_reaches_requested_percent(syscheck):
    assert syscheck.disk_percent("/mnt/tfs_a") == 0
    percent = syscheck.fill_filesystem("/mnt/tfs_a", 60)
    assert 55 <= percent <= 65


def test_syslog_daemon_is_running(syscheck):
    syscheck.exec("logger -p local3.info harness-syslog-probe").check()
    syscheck.exec("for i in $(seq 20); do grep -q harness-syslog-probe /var/log/syslog && break; sleep 0.1; done")
    assert "harness-syslog-probe" in syscheck.syslog()


def test_reset_restores_pristine_config(syscheck):
    syscheck.set_script_config("01", "FILESYSTEM[0]=/tmp\n")
    assert "FILESYSTEM[0]=/tmp" in syscheck.read_file("/opt/syscheck/config/01.conf")
    syscheck.reset()
    assert "FILESYSTEM[0]=/tmp" not in syscheck.read_file("/opt/syscheck/config/01.conf")
