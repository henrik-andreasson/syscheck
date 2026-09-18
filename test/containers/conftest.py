"""Shared fixtures for the syscheck testcontainers suite."""

from __future__ import annotations

import pytest

from syscheck_harness import (
    SyscheckContainer,
    build_image,
    create_network,
    remove_network,
    start_mariadb_node,
    start_sshd_node,
    start_syscheck_container,
)

MARIADB_ROOT_PASSWORD = "rootpw"
MARIADB_DATABASE = "syscheckdb"



def pytest_configure(config: pytest.Config) -> None:
    config.addinivalue_line("markers", "slow: test that starts extra containers")
    config.addinivalue_line(
        "markers", "known_bug: documents behaviour that is currently wrong"
    )


@pytest.fixture(scope="session")
def syscheck_image() -> str:
    return build_image()


@pytest.fixture(scope="session")
def syscheck_network():
    name = create_network()
    try:
        yield name
    finally:
        remove_network(name)


@pytest.fixture(scope="session")
def _syscheck_session(syscheck_image: str, syscheck_network: str):
    tc, sc = start_syscheck_container(syscheck_image, network=syscheck_network)
    sc.network = syscheck_network
    try:
        yield sc
    finally:
        tc.stop()


@pytest.fixture
def syscheck(_syscheck_session: SyscheckContainer) -> SyscheckContainer:
    """A syscheck install with pristine config, one per test."""
    _syscheck_session.reset()
    return _syscheck_session


@pytest.fixture(scope="session")
def mariadb_node(syscheck_network) -> str:
    """One MariaDB server shared by every suite that needs a database.

    Session-scoped because starting it costs ~10s and the three suites using it
    (sc_18, sc_38, sc_40) each want a live server rather than a private one.
    Tests that need to *stop* a server start their own.
    """
    tc, name = start_mariadb_node(syscheck_network,
                                  root_password=MARIADB_ROOT_PASSWORD,
                                  database=MARIADB_DATABASE)
    try:
        yield name
    finally:
        tc.stop()


SSH_KEY = "/root/.ssh/id_syscheck"
SSH_REMOTE_USER = "syscheckbak"


@pytest.fixture(scope="session")
def sshd_node(syscheck_network, _syscheck_session) -> str:
    """One key-only sshd shared by every suite in the ssh/remote group.

    The keypair is generated inside the syscheck container and its public half
    installed on the remote, so the scripts authenticate the way they would in
    production rather than against anything stubbed.

    Session-scoped: `906`, `907`, `915` and `930` all want a
    live remote, and none of them needs a private one — tests that must break
    the connection point at a host that does not exist instead of stopping this.
    """
    _syscheck_session.exec(
        f"mkdir -p /root/.ssh && rm -f {SSH_KEY} {SSH_KEY}.pub && "
        f"ssh-keygen -q -t ed25519 -N '' -f {SSH_KEY}").check()
    public_key = _syscheck_session.read_file(f"{SSH_KEY}.pub").strip()

    tc, name = start_sshd_node(syscheck_network, public_key=public_key)
    try:
        yield name
    finally:
        tc.stop()
