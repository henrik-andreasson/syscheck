"""End-to-end template compilation and rendering tests for the Ansible role.

This ensures all templates under misc/ansible/roles/syscheck/templates compile
successfully against the default variables configured in defaults/main.yml.
"""

from __future__ import annotations

import os
import subprocess
import pytest
import yaml
import jinja2

ROLE_PATH = os.path.abspath(os.path.join(os.path.dirname(__file__), "../../misc/ansible/roles/syscheck"))
DEFAULTS_FILE = os.path.join(ROLE_PATH, "defaults/main.yml")
TEMPLATES_DIR = os.path.join(ROLE_PATH, "templates")


def load_defaults() -> dict:
    """Load default variables from main.yml."""
    with open(DEFAULTS_FILE, "r") as f:
        # Load yaml and strip out potential ansible-specific values or set mock defaults
        data = yaml.safe_load(f) or {}
    
    # Add common extra vars that would normally be supplied by Ansible at runtime
    data.update({
        "inventory_hostname": "ca1.lab.certificateservices.org",
        "webclitool": "curl",
        "sc_01_disks": [
            {"path": "/", "warn": "70", "error": "85"},
            {"path": "/var/lib", "warn": "70", "error": "85"}
        ],
        "sc_08_crl_from_webserver_urls": [
            "http://localhost/crl/eIDCA.crl",
            "http://localhost/crl/eSignCA.crl"
        ],
        "sc_08_crl_time_out": 10,
        "sc_08_crl_retries": 2,
        "sc_33_healthcheck": [
            "certservice-public"
        ],
        "apache_public_http_ip": "127.0.0.1",
        "apache_public_http_port": "80",
        "apache_admin_http_ip": "127.0.0.1",
        "apache_admin_http_port": "443",
        "sc_36_dell_health_fans": [{"id": "0", "fanid": "0"}],
        "sc_36_dell_health_temps": [{"id": "0", "tempid": "0"}],
        "sc_36_dell_health_cpus": [{"id": "0", "cpuid": "0"}],
        "sc_36_dell_health_psus": [{"id": "0", "psuid": "0"}]
    })
    return data


def test_defaults_yaml_loads_successfully():
    """Verify defaults/main.yml is valid YAML."""
    defaults = load_defaults()
    assert isinstance(defaults, dict)
    assert "syscheck_home" in defaults


def get_templates() -> list[str]:
    """Gather all template file names."""
    if not os.path.exists(TEMPLATES_DIR):
        return []
    return [f for f in os.listdir(TEMPLATES_DIR) if os.path.isfile(os.path.join(TEMPLATES_DIR, f))]


@pytest.mark.parametrize("template_name", get_templates())
def test_template_compiles_and_renders_successfully(template_name):
    """Verify each template compiles and renders with defaults."""
    # Load defaults
    defaults = load_defaults()

    # Load template
    with open(os.path.join(TEMPLATES_DIR, template_name), "r") as f:
        template_content = f.read()

    # Set up Jinja2 environment and render template
    env = jinja2.Environment(undefined=jinja2.StrictUndefined)
    template = env.from_string(template_content)
    
    # This will raise an exception if there are undefined variables or syntax errors
    rendered = template.render(**defaults)
    
    assert isinstance(rendered, str)


def test_ansible_playbook_syntax_check():
    """Verify that the overall Ansible playbook syntax check passes."""
    playbook_path = os.path.abspath(os.path.join(ROLE_PATH, "../../playbooks/playbook-syscheck.yml"))
    hosts_path = os.path.abspath(os.path.join(ROLE_PATH, "../../hosts"))
    
    # We find the ansible-playbook executable inside the virtualenv's bin directory
    ansible_playbook_bin = os.path.abspath(os.path.join(os.path.dirname(__file__), ".venv/bin/ansible-playbook"))
    if not os.path.exists(ansible_playbook_bin):
        ansible_playbook_bin = "ansible-playbook"
        
    # Set up temporary ANSIBLE_COLLECTIONS_PATH structure
    collections_dir = "/tmp/ansible_test_collections_syntax"
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

    cmd = [ansible_playbook_bin, "--syntax-check", "-i", hosts_path, playbook_path]
    run_env = dict(os.environ)
    run_env["ANSIBLE_COLLECTIONS_PATH"] = collections_dir

    res = subprocess.run(cmd, capture_output=True, text=True, env=run_env)
    
    # Clean up symlink
    if os.path.exists(collections_dir):
        subprocess.run(["rm", "-rf", collections_dir])

    assert res.returncode == 0, f"Ansible playbook syntax check failed:\nSTDERR: {res.stderr}\nSTDOUT: {res.stdout}"
