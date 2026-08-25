"""Shared fixtures for the syscheck testcontainers suite."""

from __future__ import annotations

import pytest

from syscheck_harness import (
    SyscheckContainer,
    build_image,
    start_syscheck_container,
)


def pytest_configure(config: pytest.Config) -> None:
    config.addinivalue_line("markers", "slow: test that starts extra containers")
    config.addinivalue_line(
        "markers", "known_bug: documents behaviour that is currently wrong"
    )


@pytest.fixture(scope="session")
def syscheck_image() -> str:
    return build_image()


@pytest.fixture(scope="session")
def _syscheck_session(syscheck_image: str):
    tc, sc = start_syscheck_container(syscheck_image)
    try:
        yield sc
    finally:
        tc.stop()


@pytest.fixture
def syscheck(_syscheck_session: SyscheckContainer) -> SyscheckContainer:
    """A syscheck install with pristine config, one per test."""
    _syscheck_session.reset()
    return _syscheck_session
