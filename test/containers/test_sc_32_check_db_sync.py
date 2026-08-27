"""End-to-end tests for scripts-available/sc_32_check_db_sync.sh.

Driven against real MariaDB nodes on a shared docker network, so the SQL, the
settle window and the retry logic are exercised for real. Divergence is created
by writing directly to one node, which is what a split brain looks like from
the check's point of view.
"""

from __future__ import annotations

import pytest

from syscheck_harness import start_mariadb_node

SCRIPT = "sc_32_check_db_sync.sh"
DB = "syscheckdb"
DB_USER = "syscheck"
DB_PASSWORD = "syscheckpw"
ROOT_PASSWORD = "rootpw"

SCHEMA = """
CREATE TABLE CertificateData (
  id INT PRIMARY KEY,
  subject VARCHAR(128),
  updateTime DATETIME
);
CREATE TABLE CAData (
  id INT PRIMARY KEY,
  name VARCHAR(64)
);
"""

pytestmark = pytest.mark.slow


def config(nodes: list[str], *, settle: int = 0, tries: int = 2, delay: int = 1,
           tables: tuple[tuple[str, str], ...] = (("CertificateData", "updateTime"),)) -> str:
    lines = [f'DBSYNC_NODE[{i}]={n}' for i, n in enumerate(nodes)]
    lines += [
        "DBSYNC_PORT=3306",
        f"DBSYNC_SETTLE_SECONDS={settle}",
        f"DBSYNC_RECHECK_TRIES={tries}",
        f"DBSYNC_RECHECK_DELAY={delay}",
        "DBSYNC_TIMEOUT=15",
    ]
    for i, (table, cutoff) in enumerate(tables):
        lines.append(f"SYNCTABLE[{i}]={table}")
        lines.append(f"SYNCCUTOFF[{i}]={cutoff}")
    return "\n".join(lines) + "\n"


def mariadb_conf() -> str:
    return (
        f"DB_NAME={DB}\n"
        f"DB_USER={DB_USER}\n"
        f'DB_PASSWORD="{DB_PASSWORD}"\n'
        "DB_TEST_TABLE=CertificateData\n"
        "MYSQL_BIN=/usr/bin/mariadb\n"
    )


@pytest.fixture(scope="module")
def nodes(syscheck_image, syscheck_network):
    """Two MariaDB nodes with identical schema. Module scoped: starting these
    is the expensive part, individual tests reset the data."""
    started = []
    try:
        for _ in range(2):
            tc, name = start_mariadb_node(syscheck_network, root_password=ROOT_PASSWORD,
                                          database=DB, user=DB_USER, password=DB_PASSWORD)
            started.append((tc, name))
        yield [name for _, name in started]
    finally:
        for tc, _ in started:
            tc.stop()


def sql(syscheck, node: str, statements: str) -> str:
    res = syscheck.exec(
        ["mariadb", "-h", node, "-uroot", f"-p{ROOT_PASSWORD}", DB, "-e", statements]
    )
    assert res.exit_code == 0, res.output
    return res.stdout


@pytest.fixture
def dbconf(syscheck, nodes):
    """Credentials only. Tests that never touch the data do not need the schema
    rebuilt on both nodes."""
    syscheck.write_file("/opt/syscheck/config/mariadb.conf", mariadb_conf())
    return nodes


@pytest.fixture
def db(dbconf, syscheck, nodes):
    for node in nodes:
        sql(syscheck, node, "DROP TABLE IF EXISTS CertificateData; DROP TABLE IF EXISTS CAData;")
        sql(syscheck, node, SCHEMA)
    return nodes


OLD = "2026-01-01 00:00:00"


def seed(syscheck, nodes, rows: int = 5):
    """Fixed timestamps, not NOW(): the statement runs against each node a
    moment apart, so NOW() would differ and the checksums with it."""
    for node in nodes:
        values = ",".join(
            f"({i}, 'CN=cert{i}', '{OLD}')" for i in range(1, rows + 1)
        )
        sql(syscheck, node, f"INSERT INTO CertificateData VALUES {values};")
        sql(syscheck, node, "INSERT INTO CAData VALUES (1,'RootCA'),(2,'SubCA');")


def test_identical_nodes_report_in_sync(syscheck, db):
    seed(syscheck, db)
    syscheck.set_script_config("32", config(db))
    run = syscheck.run_script(SCRIPT)

    assert run.levels == ["I", "I"], run.describe()
    assert run.messages[0].errno == "321"
    assert "CertificateData" in run.messages[0].text
    assert run.messages[1].errno == "327"


def test_a_missing_row_on_one_node_is_an_error(syscheck, db):
    seed(syscheck, db)
    sql(syscheck, db[1], "DELETE FROM CertificateData WHERE id = 3;")
    syscheck.set_script_config("32", config(db))
    run = syscheck.run_script(SCRIPT)

    assert run.levels == ["E", "E"], run.describe()
    assert run.messages[0].errno == "322"
    assert "CertificateData" in run.messages[0].text
    assert run.messages[1].errno == "328"


def test_a_changed_value_on_one_node_is_an_error(syscheck, db):
    """Row counts match, so only the checksum can catch this."""
    seed(syscheck, db)
    sql(syscheck, db[1], "UPDATE CertificateData SET subject='CN=tampered' WHERE id = 2;")
    syscheck.set_script_config("32", config(db))
    run = syscheck.run_script(SCRIPT)

    assert run.messages[0].level == "E", run.describe()
    assert run.messages[0].errno == "322"


def test_two_extra_identical_rows_are_caught_by_the_row_count(syscheck, db):
    """BIT_XOR cancels identical values, so the checksum alone would miss this."""
    seed(syscheck, db)
    sql(syscheck, db[1],
        f"INSERT INTO CertificateData VALUES (98,'CN=dup','{OLD}'),"
        f"(99,'CN=dup','{OLD}');")
    run_config = config(db)
    syscheck.set_script_config("32", run_config)
    run = syscheck.run_script(SCRIPT)

    assert run.messages[0].level == "E", run.describe()


def test_rows_inside_the_settle_window_are_ignored(syscheck, db):
    """A write that has not replicated yet must not raise an alarm."""
    seed(syscheck, db)
    sql(syscheck, db[0],
        "INSERT INTO CertificateData VALUES (50,'CN=inflight',NOW());")
    syscheck.set_script_config("32", config(db, settle=60))
    run = syscheck.run_script(SCRIPT)

    assert run.levels == ["I", "I"], run.describe()


def test_the_same_write_outside_the_settle_window_is_an_error(syscheck, db):
    seed(syscheck, db)
    sql(syscheck, db[0],
        f"INSERT INTO CertificateData VALUES (50,'CN=inflight','{OLD}');")
    syscheck.set_script_config("32", config(db, settle=60))
    run = syscheck.run_script(SCRIPT)

    assert run.messages[0].level == "E", run.describe()


def test_a_node_that_catches_up_is_a_warning_not_an_error(syscheck, db):
    """The retry loop is what separates lag from divergence: the row is added to
    the lagging node while the check is between attempts."""
    seed(syscheck, db)
    sql(syscheck, db[0],
        f"INSERT INTO CertificateData VALUES (60,'CN=late','{OLD}');")
    syscheck.set_script_config("32", config(db, tries=5, delay=3))

    syscheck.exec(
        f"(sleep 4; mariadb -h {db[1]} -uroot -p{ROOT_PASSWORD} {DB} "
        f"-e \"INSERT INTO CertificateData VALUES (60,'CN=late','{OLD}');\") "
        ">/dev/null 2>&1 &"
    )
    run = syscheck.run_script(SCRIPT)

    assert run.messages[0].level == "W", run.describe()
    assert run.messages[0].errno == "323"
    assert run.messages[1].errno == "327"


def test_a_table_without_a_cutoff_column_is_compared_whole(syscheck, db):
    """Also covers several tables being reported separately, each with its own
    script index."""
    seed(syscheck, db)
    syscheck.set_script_config(
        "32", config(db, tables=(("CertificateData", "updateTime"), ("CAData", "")))
    )
    run = syscheck.run_script(SCRIPT)

    assert run.levels == ["I", "I", "I"], run.describe()
    assert run.indexes == ["01", "02", "03"]

    sql(syscheck, db[1], "UPDATE CAData SET name='Tampered' WHERE id = 1;")
    run = syscheck.run_script(SCRIPT)

    assert run.levels == ["I", "E", "E"], run.describe()
    assert "CAData" in run.messages[1].text


def test_an_unreachable_node_is_reported(syscheck, db):
    seed(syscheck, db)
    syscheck.set_script_config("32", config([db[0], "no-such-node"]))
    run = syscheck.run_script(SCRIPT)

    assert run.messages[0].level == "E", run.describe()
    assert run.messages[0].errno == "324"
    assert "no-such-node" in run.messages[0].text


def test_a_missing_table_is_reported(syscheck, db):
    seed(syscheck, db)
    syscheck.set_script_config("32", config(db, tables=(("NoSuchTable", ""),)))
    run = syscheck.run_script(SCRIPT)

    assert run.messages[0].level == "E", run.describe()
    assert run.messages[0].errno == "325"
    assert "NoSuchTable" in run.messages[0].text


def test_a_single_node_is_a_config_error(syscheck, dbconf):
    syscheck.set_script_config("32", config([dbconf[0]]))
    run = syscheck.run_script(SCRIPT)

    msg = run.only()
    assert msg.level == "E"
    assert msg.errno == "326"
    assert "two nodes" in msg.text


def test_no_tables_configured_is_a_config_error(syscheck, dbconf):
    syscheck.set_script_config("32", config(dbconf, tables=()))
    run = syscheck.run_script(SCRIPT)

    msg = run.only()
    assert msg.level == "E"
    assert msg.errno == "326"
    assert "SYNCTABLE" in msg.text


def test_help_documents_every_error_code(syscheck):
    res = syscheck.exec([syscheck.script_path(SCRIPT), "--help"])

    for errno in ("321", "322", "323", "324", "325", "326", "327", "328"):
        assert f"{errno} / " in res.output, res.output
