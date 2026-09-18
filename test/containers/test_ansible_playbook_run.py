"""End-to-end integration tests for running the Ansible playbook.

This runs the playbook locally inside the test container against a temporary
syscheck home, ensuring that the entire configuration, directory setup,
and symbolic link generation logic functions perfectly.
"""

from __future__ import annotations

import os
import subprocess
import pytest

ROLE_PATH = os.path.abspath(os.path.join(os.path.dirname(__file__), "../../misc/ansible/roles/syscheck"))
PLAYBOOK_PATH = os.path.abspath(os.path.join(ROLE_PATH, "../../playbooks/playbook-syscheck.yml"))
TEST_HOME = "/tmp/syscheck_test"
TEST_BACKUP = "/tmp/syscheck_test/backup"
TEST_SSH_KEY = "/tmp/syscheck_test/id_rsa"


@pytest.fixture(autouse=True)
def setup_test_home():
    """Create a temporary syscheck directory structure."""
    if os.path.exists(TEST_HOME):
        subprocess.run(["sudo", "rm", "-rf", TEST_HOME], check=True)
    
    # Create directories
    os.makedirs(os.path.join(TEST_HOME, "config"), exist_ok=True)
    os.makedirs(os.path.join(TEST_HOME, "scripts-available"), exist_ok=True)
    os.makedirs(os.path.join(TEST_HOME, "scripts-enabled"), exist_ok=True)
    os.makedirs(os.path.join(TEST_HOME, "related-available"), exist_ok=True)
    os.makedirs(os.path.join(TEST_HOME, "related-enabled"), exist_ok=True)

    # Touch all default enabled core scripts so symbolic links can be created to them
    default_core_scripts = [
        "sc_01_diskusage.sh",
        "sc_02_ejbca.sh",
        "sc_03_memory-usage.sh",
        "sc_07_syslog.sh",
        "sc_09_firewall.sh",
        "sc_12_mysql.sh",
        "sc_17_ntp.sh",
        "sc_18_sqlselect.sh",
        "sc_19_alive.sh",
        "sc_20_errors_ejbcalog.sh"
    ]
    for script in default_core_scripts:
        with open(os.path.join(TEST_HOME, "scripts-available", script), "w") as f:
            f.write("#!/bin/bash\necho test\n")
            
    # Touch all default enabled related scripts
    default_related_scripts = [
        "904_make_mysql_db_backup.sh",
        "906_ssh-copy-to-remote-machine.sh",
        "908_clean_old_backups.sh",
        "920_restore_mysql_db_from_backup.sh",
        "927_create_crls.sh",
        "929_filter_syscheck_messages.sh",
        "930_send_filtered_result_to_remote_machine.sh",
        "931_mysql_backup_encrypt_send_to_remote_host.sh"
    ]
    for script in default_related_scripts:
        with open(os.path.join(TEST_HOME, "related-available", script), "w") as f:
            f.write("#!/bin/bash\necho test\n")

    yield

    # Cleanup with sudo because files are owned by root after Ansible run
    if os.path.exists(TEST_HOME):
        subprocess.run(["sudo", "rm", "-rf", TEST_HOME], check=True)


def test_ansible_playbook_run_and_installation():
    """Verify that running the Ansible playbook installs files and configures links."""
    # Find ansible-playbook binary
    ansible_playbook_bin = os.path.abspath(os.path.join(os.path.dirname(__file__), ".venv/bin/ansible-playbook"))
    if not os.path.exists(ansible_playbook_bin):
        ansible_playbook_bin = "ansible-playbook"

    # Define variables to override for local non-destructive testing
    extra_vars = (
        f"syscheck_home={TEST_HOME} "
        f"syscheck_backup_dir={TEST_BACKUP} "
        f"syscheck_ssh_key={TEST_SSH_KEY} "
        "install_rpm=false "
        "setup_cron=false"
    )

    # Set up temporary ANSIBLE_COLLECTIONS_PATH structure
    collections_dir = "/tmp/ansible_test_collections_run"
    collection_link_dir = os.path.join(collections_dir, "ansible_collections/aberosecurity")
    os.makedirs(collection_link_dir, exist_ok=True)
    
    # Symlink our collection root (misc/ansible) to the collection path
    collection_dest = os.path.join(collection_link_dir, "syscheck")
    if os.path.exists(collection_dest):
        if os.path.islink(collection_dest):
            os.remove(collection_dest)
        else:
            subprocess.run(["rm", "-rf", collection_dest])
            
    os.symlink(os.path.abspath(os.path.join(ROLE_PATH, "../..")), collection_dest)

    # Run playbook with sudo, local connection, targeting localhost
    # We pass ANSIBLE_COLLECTIONS_PATH directly into the env block of sudo
    cmd = [
        "sudo",
        f"ANSIBLE_COLLECTIONS_PATH={collections_dir}",
        ansible_playbook_bin,
        "-i", "localhost,",
        "-c", "local",
        "--extra-vars", extra_vars,
        PLAYBOOK_PATH
    ]
    
    res = subprocess.run(cmd, capture_output=True, text=True)
    
    # Clean up symlink
    if os.path.exists(collections_dir):
        subprocess.run(["rm", "-rf", collections_dir])

    assert res.returncode == 0, f"Playbook run failed:\nSTDERR: {res.stderr}\nSTDOUT: {res.stdout}"

    # Verify directory structure was created by Ansible
    assert os.path.exists(TEST_BACKUP)
    assert os.path.isdir(os.path.join(TEST_BACKUP, "default"))
    assert os.path.isdir(os.path.join(TEST_BACKUP, "daily"))

    # Verify configs were compiled from Jinja2 templates and copied
    assert os.path.exists(os.path.join(TEST_HOME, "config/common.conf"))
    assert os.path.exists(os.path.join(TEST_HOME, "config/01.conf"))
    assert os.path.exists(os.path.join(TEST_HOME, "config/03.conf"))

    # Verify symbolic links were enabled as configured by defaults
    sc_01_link = os.path.join(TEST_HOME, "scripts-enabled/sc_01_diskusage.sh")
    assert os.path.exists(sc_01_link)
    assert os.path.islink(sc_01_link)
    assert os.readlink(sc_01_link) == f"{TEST_HOME}/scripts-available/sc_01_diskusage.sh"

    sc_03_link = os.path.join(TEST_HOME, "scripts-enabled/sc_03_memory-usage.sh")
    assert os.path.exists(sc_03_link)
    assert os.path.islink(sc_03_link)
    assert os.readlink(sc_03_link) == f"{TEST_HOME}/scripts-available/sc_03_memory-usage.sh"

    # Verify related script links
    r_904_link = os.path.join(TEST_HOME, "related-enabled/904_make_mysql_db_backup.sh")
    assert os.path.exists(r_904_link)
    assert os.path.islink(r_904_link)
    assert os.readlink(r_904_link) == f"{TEST_HOME}/related-available/904_make_mysql_db_backup.sh"

    # Verify SSH Key generation occurred
    assert os.path.exists(TEST_SSH_KEY)
    assert os.path.exists(f"{TEST_SSH_KEY}.pub")
