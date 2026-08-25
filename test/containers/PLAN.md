# Test plan: every syscheck script

Derived from reading all 38 `scripts-available/sc_*.sh`, all 43
`related-available/9*.sh` and their `config/*.conf`. Each script is classified
by what it actually talks to, which determines how it gets tested.

## Mock strategies

| Strategy | When | Cost |
| --- | --- | --- |
| **REAL-OS** | the script reads state the container genuinely has (`df`, `free`, processes, syslog) | free, highest fidelity |
| **REAL-SVC** | the dependency is a service with an official image (MariaDB, Redis, nginx, MinIO, sshd, snmpsim, Elasticsearch) | one extra container, high fidelity |
| **MOCK-SRV** | the dependency is an HTTP API we control the shape of (EJBCA/SignServer healthcheck, JNLP) — served by the repo's own `test/pyhton-dummy-health-web-server.py` in a container | one small container |
| **FAKE-BIN** | the dependency is vendor hardware tooling that cannot be containerised (`omreport`, `ilorest`, `ssacli`, `lunacm`, `mdadm`, `iptables`, `systemctl`, `chronyc`) — an executable early on `PATH` replaying captured real output | free; fidelity limited by the fixtures |
| **FIXTURE** | the script parses a file (EJBCA server.log, CRL, certificate) | free, high fidelity |

For FAKE-BIN the fixtures must be **captured from real output**, otherwise the
test only proves the script parses our invention. Where the repo or the docs
already contain sample output it is used; where it does not, the fixture is
marked `# UNVERIFIED SHAPE` so the gap is visible in the report.

## Phase 1 — core, no extra containers

| ID | Script | Strategy | What gets driven | Status |
| --- | --- | --- | --- | --- |
| 01 | diskusage | REAL-OS | tmpfs filled to a known % | **done** (28 tests) |
| 03 | memory-usage | FAKE-BIN `free` + REAL-OS | mem/swap over and under `MEM_PERCENT`/`SWAP_PERCENT`, `HUMAN_READABLE` on/off | |
| 05 | pcscd | REAL-OS | long-lived process + pidfile present / stale pidfile / absent | |
| 07 | syslog | REAL-OS | real `rsyslogd` in the image; write a marker and confirm the round trip, plus dead-daemon path | |
| 09 | firewall | FAKE-BIN `iptables` | rule present / missing / `iptables` failing | |
| 12 | mysql (process) | REAL-OS | fake `mysqld` process + pidfile | |
| 14 | sw_raid | FAKE-BIN `mdadm` | `active sync`, `faulty`, missing array | |
| 15 | apache | REAL-OS | process + pidfile | |
| 16 | ldap | REAL-OS | process + pidfile | |
| 19 | alive | REAL-OS | single INFO message — **already known broken, see REPORT.md** | |
| 20 | errors_ejbcalog | FIXTURE | real `lib/tail_errors_from_ejbca_log.py` against a crafted server.log; position-file resume; `IGNORE[]` filtering | |
| 22 | boks_replica | REAL-OS | 4 fake processes, each combination of up/down | |
| 23 | rsa_axm | REAL-OS | fake processes + `pid:` style pidfiles | |
| 27 | dss | FAKE-BIN `signserver.sh` | N active workers vs expected | |
| 30 | check_running_procs | REAL-OS | process down → restart command runs → success and failure | |
| 41 | ra_verifier | FAKE-BIN `verify-factoryra.sh` | VALID/OK/VALID, and each of the three failure texts | |
| 42 | receipts | FAKE-BIN `checkreceipts.sh` | per-`TYPE[]` present/missing | |
| 04 | pcsc_readers | FAKE-BIN `list-pcsc-readers.py` | reader count match/mismatch, `ModuleNotFoundError` path | |
| 17 | ntp | FAKE-BIN `chronyc`/`timedatectl` | synchronised, unsynchronised, no reachable sources, both backends | |
| 32 | check_db_sync | REAL-OS | **script contains a hard-coded `echo "This script is broken"; exit`** — test pins current behaviour only | |

## Phase 2 — real service containers

| ID | Script | Strategy | Container | Notes |
| --- | --- | --- | --- | --- |
| 34 | redis | REAL-SVC | `redis:7` with `requirepass` | PONG, wrong password, port closed, per-instance array |
| 18 | sqlselect | REAL-SVC | `mariadb:11` | table present, table missing, server down, wrong credentials |
| 38 | mysql_connections | REAL-SVC | `mariadb:11` | open N real connections, assert `WARN_PERCENT`/`ERROR_PERCENT` crossings |
| 40 | cluster | REAL-SVC + FAKE-BIN | `mariadb:11` | real server for the liveness half; `wsrep_*` variables faked for the Galera half |
| 12 | mysql | REAL-SVC | `mariadb:11` | upgrade the process check to a real server |
| 02 | ejbca | MOCK-SRV | repo's dummy health server | `ALLOK` / `ERROR` / 500 / timeout / connection refused |
| 29 | signserver | MOCK-SRV | same | as above |
| 33 | healthchecker | MOCK-SRV + FAKE-BIN | dummy health server + fake `systemctl` | the restart state machine: failure → stop → start, `MAX_RESTARTS`, 24h window |
| 37 | monitor_jnlp | MOCK-SRV | nginx serving a JNLP file | valid JNLP, truncated, 404, wrong `Host` header |
| 08 | crl_from_webserver | REAL-SVC + FIXTURE | nginx + openssl-generated CRLs | fresh CRL, CRL inside `MINUTES`, inside `ERRMIN`, expired, 404, malformed |
| 44 | cert_from_webserver | REAL-SVC + FIXTURE | `openssl s_server` with generated certs | valid, expiring within `WARNTIME`, within `ERRTIME`, expired, wrong host, port closed |
| 10 | ocsp | REAL-SVC + FIXTURE | real `openssl ocsp` responder + generated CA | good, revoked, unknown, responder down, responder cert near expiry |
| 43 | rittal_rack_sensors | REAL-SVC | `snmpsim` | each `SNMP[]` OID at expected and unexpected values |
| 28 | check_vip | REAL-SVC | `linuxserver/openssh-server` ×2 | VIP on node1, node2, both, neither — also exercises `related/915` |
| 32 | check_db_sync | REAL-SVC | `mariadb:11` ×2 | only meaningful once the script is unbroken |

## Phase 3 — vendor hardware CLIs (fake binaries, captured fixtures)

| ID | Script | Faked tool | Fixture cases |
| --- | --- | --- | --- |
| 06 | raid_check | `ssacli` | logical/physical drive OK, Failed, Rebuilding, tool absent |
| 31 | hp_health | `ilorest` | PSU state/condition matrix, each `HPTEMP` sensor, lockfile contention |
| 35 | dell_raid | `omreport` | pdisk/vdisk Ok, Degraded, Failed, Non-Critical |
| 36 | dell_health | `omreport` | fans, temps, CPU, PSU — Ok and each failure state |
| 39 | hsm_health | `lunacm` | Luna 7 activation, battery, temperature, storage %, `Command Result` errors |

These are the lowest-fidelity tests in the suite: they prove the parsing and
threshold logic, not that the real tool speaks that dialect. Capturing one real
output sample per tool from production hardware would raise their value more
than any additional test case would.

## Phase 4 — related scripts (900–942)

| Group | Scripts | Strategy |
| --- | --- | --- |
| ssh / remote | 906, 915, 918, 923, 924, 930, 907 | REAL-SVC sshd container with a generated keypair |
| mysql backup/restore | 904, 920, 922, 931, 935, 936, 937, 938, 940, 914, 933 | REAL-SVC `mariadb:11`; round-trip dump → restore → verify row counts |
| S3 | 941, 942 | REAL-SVC **MinIO** — replaces the fake-`curl` stub in `test/test-s3-backup-restore.bats`, which currently tests the stub's idea of S3 rather than S3 |
| Elasticsearch | 939 | REAL-SVC `elasticsearch:8` — create dated indices, assert only old ones are deleted |
| EJBCA CLI | 900, 901, 902, 905, 909, 910, 919, 925, 927 | FAKE-BIN `ejbca.sh` / `clientToolBox`; fidelity gap flagged |
| filesystem/archive | 908, 916, 917, 921, 926, 913 | REAL-OS with a populated temp tree |
| HSM backup | 903, 928 | FAKE-BIN vendor tool |
| VIP | 911, 912 | FAKE-BIN `ip`/`ifconfig` |
| syscheck plumbing | 929, 930, 932 | REAL-OS on a crafted `var/last_status` |

## Cross-cutting suites

- **`test_packaging.py`** — every script answers `--scriptid`/`--scriptname`,
  ids are unique, a fresh install has no pre-existing status. *(done)*
- **`test_libsyscheck.py`** — argument parsing (`-c` hang), `initscript`,
  `isSyscheckOnHold`, `addOneToIndex` past 99, language-file fallback,
  `getconfig` on a missing/unreadable file.
- **`test_printlogmess.py`** — the three output formats × four sinks, message
  truncation at `MESSAGELENGTH`, `%s` argument substitution, and the behaviour
  when a required argument is empty (the root cause of the sc_01 defects).
- **`test_syscheck_sh.py`** — `--testall`, `scripts-enabled` ordering,
  `last_status` truncation per run, the filter/send hooks.

`printlogmess` and `libsyscheck` are worth doing right after Phase 1: three of
the six sc_01 defects are actually shared-library defects that will otherwise be
rediscovered once per script.

## Ordering rationale

Phase 1 needs no new containers and covers 20 of 38 scripts, so it converts the
existing smoke-level bats coverage into real assertions fastest. Phase 2 is
where testcontainers earns its keep and where the highest-risk logic lives
(PKI: CRL freshness, certificate expiry, OCSP). Phase 3 is mechanical. Phase 4
is the largest body of work and the one with real destructive potential
(backup/restore scripts), so it runs entirely against throwaway containers.
