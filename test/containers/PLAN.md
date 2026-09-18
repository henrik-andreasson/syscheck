# Test plan: every syscheck script

Derived from reading every `scripts-available/sc_*.sh`, all 43
`related-available/9*.sh` and their `config/*.conf`. Each script is classified
by what it actually talks to, which determines how it gets tested.

## Status

Last reconciled against the tree: 2026-09-14.

| Phase                               | Planned    | Done                            | Remaining |
| ----------------------------------- | ---------- | ------------------------------- | --------- |
| Phase 1 — core, no extra containers | 15 scripts | **15 — complete**               | —         |
| Phase 2 — real service containers   | 13 scripts | **13 — complete**               | —         |
| Phase 3 — vendor hardware CLIs      | 5 scripts  | **5 — complete**                | —         |
| Phase 4 — related scripts           | 30 scripts | **30 — complete**               | —         |
| Cross-cutting suites                | 4 planned  | **4 — complete** + 3 unplanned  | —         |

**Every script in the tree is covered**: 32 of 32 `sc_` checks plus
`syscheck.sh` and the shared library they run on, and 30 of 30 surviving
`related` scripts. Thirteen `related` scripts were deleted along the way rather
than tested — see the deletion notes below.

Phase 4 was the last outstanding phase, and it is now closed.

```
$ ./run.sh -q
553 passed, 18 xfailed in 952.03s (0:15:52)
```

**571 tests, 18 strict xfails.** All but one of the xfails is an open defect;
the exception is `test_packaging.py`'s `--help` formatting guard. None of them
xpassed, so every defect they describe is still reproducible.

**Phase 4 is the active phase**, and it is all that is left: every `sc_` script
now has a suite. `934` is its first, landed 2026-09-15. Phase 4 is the largest body of work in the plan and the one
with real destructive potential — backup and restore scripts — so it runs
entirely against throwaway containers.

**Phases 1, 2 and 3 are complete.** 32 of 32 `sc_` scripts, every line of them.

**Phase 2 closed on 2026-09-13.** All of its scripts have a suite. The harness
gained two service helpers along the way — `start_http_server` (made usable:
rewritable routes and binary bodies) and `start_ocsp_responder` (a real CA plus
a real `openssl ocsp` responder).

**Eleven defects were fixed on 2026-09-14**: `sc_33`'s D43–D47, `sc_37`'s D48
and D49, and `sc_08`'s D50–D52. `sc_33` now passes with no xfails; `sc_37` and
`sc_08` have one open defect each. **`sc_28`'s D56 and D57 were fixed on 2026-09-14**; its suite now passes with
no xfails.

**`sc_43_rittal_rack_sensors.sh` was deleted on 2026-09-14** at the maintainer's
direction, with its config, language file, bats case and testcontainers suite —
and with the `snmpsim`/`pysmi`/`snmp` packages and the `start_snmp_agent` helper
that existed only to drive it. It was the only SNMP check in the tree. D58–D61
go with it. Phase 2 was 14 scripts and is now 13.

**Five scripts were deleted on 2026-09-12** at the maintainer's direction:
`sc_22_boks_replica.sh`, `sc_23_rsa_axm.sh`, `sc_41_ra_verifier.sh`,
`sc_27_dss.sh` and `sc_29_signserver.sh` — each with its config, language file,
ansible tasks, bats cases and testcontainers suite. Phase 1 was 19 scripts and
is now 15; Phase 2 was 15 and is now 14. D22, D23 and D32 went with them, and
SignServer is no longer monitored at all.

**The shared plumbing is fully covered.** `test_syscheck_sh.py` landed after
Phase 1 closed, so every Phase 2 suite starts on top of an orchestrator whose
behaviour is pinned rather than assumed.

## Mock strategies

| Strategy     | When                                                                                                                                                                                                                           | Cost                                   |
| ------------ | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ | -------------------------------------- |
| **REAL-OS**  | the script reads state the container genuinely has (`df`, `free`, processes, syslog)                                                                                                                                           | free, highest fidelity                 |
| **REAL-SVC** | the dependency is a service with an official image (MariaDB, Redis, nginx, MinIO, sshd, Elasticsearch) or a real server binary the image already has (`openssl ocsp`)                                                            | one extra container, high fidelity     |
| **MOCK-SRV** | the dependency is an HTTP API we control the shape of (EJBCA healthcheck, JNLP, a published CRL) — served by the harness's own `start_http_server`, not the repo's `test/pyhton-dummy-health-web-server.py`: that one needs Flask in the image and serves three fixed routes, while each check requests a path of its own | one small container |
| **FAKE-BIN** | the dependency is vendor hardware tooling that cannot be containerised (`omreport`, `ilorest`, `ssacli`, `lunacm`, `mdadm`, `iptables`, `systemctl`, `chronyc`) — an executable early on `PATH` replaying captured real output | free; fidelity limited by the fixtures |
| **FIXTURE**  | the script parses a file (EJBCA server.log, CRL, certificate)                                                                                                                                                                  | free, high fidelity                    |

For FAKE-BIN the fixtures must be **captured from real output**, otherwise the
test only proves the script parses our invention. Where the repo or the docs
already contain sample output it is used; where it does not, the fixture is
marked `# UNVERIFIED SHAPE` so the gap is visible in the report.

## Phase 1 — core, no extra containers

| ID     | Script              | Strategy                         | What gets driven                                                                                                                                                                                                    | Status              |
| ------ | ------------------- | -------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------- |
| 01     | diskusage           | REAL-OS                          | tmpfs filled to a known %                                                                                                                                                                                           | **done** (28 tests) |
| 03 | memory-usage | FAKE-BIN `free` + REAL-OS | mem/swap over and under `MEM_PERCENT`/`SWAP_PERCENT`, both sides of the boundary, `HUMAN_READABLE` on/off, a swapless host, and one case against the container's real `free` | **done** (15 tests) |
| 05 | pcscd | REAL-OS | long-lived process, stale pidfile, absent pidfile with a name fallback | **done** (in `test_sc_process_checks.py`) |
| 07 | syslog | REAL-OS | real `rsyslogd` in the image; the marker round trip asserted from both ends, dead daemon, message lost, log file absent | **done** (9 tests) |
| 09 | firewall | FAKE-BIN `iptables` | required rule present / missing, forbidden rule present, a near-miss rule (`dpt:2222` vs `dpt:22`), `iptables` failing, `iptables` absent | **done** (10 tests) |
| 12 | mysql (process) | REAL-OS | fake `mysqld` process + pidfile | **done** (in `test_sc_process_checks.py`) |
| 14 | sw_raid | FAKE-BIN `mdadm` | `active sync`, `faulty`, missing array, absent tool. The fake validates the array it is asked about, without which D30 is invisible | **done** (8 tests) |
| 15 | apache | REAL-OS | process + pidfile | **done** (in `test_sc_process_checks.py`) |
| 16 | ldap | REAL-OS | process + pidfile | **done** (in `test_sc_process_checks.py`) |
| 19     | alive               | REAL-OS                          | the single INFO heartbeat, and that it carries its text — the message body was itself the defect (D10)                                                                                                              | **done** (3 tests)  |
| 20     | errors_ejbcalog     | FIXTURE                          | real `lib/tail_errors_from_ejbca_log.py` against a crafted server.log; position-file resume; `IGNORE[]` filtering                                                                                                   | **done** (10 tests) |
| 30 | check_running_procs | REAL-OS + FAKE-BIN | process up / down / stale pidfile; the restart command is a fake that records that it ran and with what argv, so "it restarted" is asserted from evidence | **done** (13 tests) |
| 42 | receipts | FAKE-BIN `checkreceipts.sh` | per-`TYPE[]` present/missing, tool absent, and the recorded argv of every call. Exit status is the whole contract here, so there is no fixture to get wrong | **done** (10 tests) |
| 04 | pcsc_readers | FAKE-BIN `list-pcsc-readers.py` | count match/mismatch, no readers, dead pcscd, and the `ModuleNotFoundError` path against the **real** lib script — the image has python3 and no pyscard, so that traceback is genuine | **done** (10 tests) |
| 17 | ntp | FAKE-BIN `chronyc`/`timedatectl`/`systemctl` | both backends end to end: synchronised, leap not normal, local-reference-only (refid 7F7F0101), no reachable sources, kernel out of sync, query failures, and the two-clients / no-client arms | **done** (16 tests) |
| ~~32~~ | ~~check_db_sync~~   | —                                | **superseded.** The row existed only to pin the behaviour of a script disabled in place by a hard-coded `echo "This script is broken"; exit`. That script was rewritten (D11) and is now tested properly in Phase 2 | **n/a**             |

## Phase 2 — real service containers

| ID  | Script              | Strategy            | Container                                    | Notes                                                                                                                                                                          | Status              |
| --- | ------------------- | ------------------- | -------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ | ------------------- |
| 34  | redis               | REAL-SVC            | `redis:7` with `requirepass`                 | PONG, wrong password, port closed, per-instance array                                                                                                                          | **done** (11 tests) |
| 18  | sqlselect           | REAL-SVC            | `mariadb:11`                                 | table present, table missing, server down, wrong credentials                                                                                                                   | **done**            |
| 38  | mysql_connections   | REAL-SVC            | `mariadb:11`                                 | open N real connections, assert `WARN_PERCENT`/`ERROR_PERCENT` crossings                                                                                                       | **done** (D36, D37) |
| 40  | cluster             | REAL-SVC + FAKE-BIN | `mariadb:11`                                 | real server for the liveness half; `wsrep_*` variables faked for the Galera half                                                                                               | **done** (D38, D39) |
| 12  | mysql               | REAL-SVC            | `mariadb:11`                                 | upgrade the process check to a real server                                                                                                                                     | **done** (D40)      |
| 02  | ejbca               | MOCK-SRV            | harness mock HTTP server                     | `ALLOK` / `ERROR` / 500 / timeout / connection refused; verdict follows the body, never the status code                                                                         | **done** (20 tests, D41, D42) |
| 33  | healthchecker       | MOCK-SRV + FAKE-BIN | mock server + fake `systemctl`               | the restart state machine: failure → stop → start, `MAX_RESTARTS`, 24h window, all asserted from the fake's recorded argv                                                       | **done** (29 tests, D43–D47 all fixed) |
| 37  | monitor_jnlp        | MOCK-SRV            | harness mock HTTP server                     | valid JNLP, truncated, 404, and the `Host` header proved from the server side                                                                                                  | **done** (20 tests, D48 and D49 fixed) |
| 08  | crl_from_webserver  | MOCK-SRV + FIXTURE  | mock server + openssl-generated CRLs         | fresh CRL, inside `MINUTES`, inside `ERRMIN`, expired, 404, malformed. Thresholds move rather than the clock, since `openssl ca` cannot backdate `lastUpdate`                   | **done** (26 tests, D50–D53 all fixed) |
| 44  | cert_from_webserver | REAL-SVC + FIXTURE  | `openssl s_server` with generated certs      | valid, expiring within `WARNTIME`, within `ERRTIME`, expired, wrong host, port closed                                                                                          | **done** (9 tests)  |
| 32  | check_db_sync       | REAL-SVC            | `mariadb:11` ×2                              | per-table checksum across nodes, settle window, lag-vs-divergence, unreachable node, missing table, config errors. Harness gained `create_network` / `start_mariadb_node` here | **done** (13 tests) |
| 10  | ocsp                | REAL-SVC + FIXTURE  | real `openssl ocsp` responder + generated CA | good, revoked, unknown, responder down, responder cert near expiry. Certificates are globbed as `test_*_cert*` and the expected status is **parsed out of the filename** (`cut -f4 -d_`) | **done** (18 tests, D54, D55) |
| 28  | check_vip           | FAKE-BIN            | a stub `related/915`                         | VIP on node1, node2, both, neither. No sshd needed: `sc_28` delegates every remote call to `915`, so that call is the seam. 915's ssh transport is Phase 4's | **done** (12 tests, D56 and D57 fixed) |

## Phase 3 — vendor hardware CLIs (fake binaries, captured fixtures)

**Complete, 2026-09-14.** All five scripts have suites.

| ID  | Script      | Faked tool | Fixture cases                                                               | Status |
| --- | ----------- | ---------- | --------------------------------------------------------------------------- | ------ |
| 06  | raid_check  | `ssacli`   | logical/physical drive OK, Failed, Rebuilding, tool absent                  | **done** (14 tests, D62) |
| 31  | hp_health   | `ilorest`  | PSU state/condition matrix, each `HPTEMP` sensor, lockfile contention       | **done** (16 tests, D63–D66) |
| 35  | dell_raid   | `omreport` | pdisk/vdisk Ok, Degraded, Failed, Non-Critical                              | **done** (17 tests, D67–D69) |
| 36  | dell_health | `omreport` | fans, temps, power draw, PSU — Ok and each failure state                    | **done** (22 tests) |
| 39  | hsm_health  | `lunacm`   | Luna 7 activation, battery, temperature, storage %, `Command Result` errors | **done** (23 tests, D70) |

These are the lowest-fidelity tests in the suite: they prove the parsing and
threshold logic, not that the real tool speaks that dialect. Capturing one real
output sample per tool would raise their value more than any additional test
case would — `sc_39` now has one, the other four do not.

**HP is closed.** There is no access to HP systems and none is being sought, so
`ssacli` (sc_06) and `ilorest` (sc_31) stay on `UNVERIFIED SHAPE` fixtures
permanently. Their defects are logged (D62-D65) and the scripts are not being
investigated further. The only capture still worth having is one
`omreport chassis fans index=0 -fmt ssv`, to settle the fan column order below.

### sc_35 — the best-grounded Phase 3 suite

`sc_35` carries **real `-fmt ssv` captures in its own comments**, including the
42-column pdisk header and a full data row, so the column indices it `cut`s
(`f20` capacity, `f24` vendor, `f26` serial) are pinned against genuine output.
It reuses the fake `omreport` pattern from `sc_36`.

Three defects, none dependent on fixture shape:

* **D67** — `raiddiskcheck` ends its not-found branch with `continue`, but
  `continue` inside a *function* does not continue the caller's loop: bash
  rejects it with `continue: only meaningful in a 'for', 'while', or 'until'
  loop` and carries on. Execution falls into the `cut` block with an empty
  `$DISCSTAT`, so the disk is reported as not-OK a **second** time. One absent
  disk produces two error messages and a bash diagnostic. `return` was meant.
* **D68** — that first message interpolates `$DISK_INFO`, which is assigned
  further down the same function. It is a plain global, so the message about a
  missing disk carries the *previous* disk's name, capacity and serial. Same
  class as D51.
* **D69** — `ERRNO[5]` ("LogicalDiscs has some other error — investigate ASAP")
  is never used. Every non-Ok virtual disk is reported with `DESCR[4]`,
  "LogicalDiscs is rebuilding", whose help says to check back later. A failed
  RAID volume is described as a transient state that will clear itself. Exact
  mirror of D62 in `sc_06`, and the more dangerous direction.

### sc_06 and sc_31 — basic suites, no HP hardware available

There is no access to HP systems, so `ssacli` and `ilorest` output cannot be
captured. Both suites are written as **basic** coverage and their fixtures are
marked `UNVERIFIED SHAPE`: reconstructed from what each script's own parsing
requires, not from a real controller or iLO. They prove branching, indexing and
summary behaviour — not that the vendor tools emit that layout.

What they establish holds regardless of the fixture shape, because each is a
logic error rather than a parsing assumption:

* **D62 (`sc_06`)** — the rebuilding branch is
  `elif [ "xRebuilding" = "x$COMMAND" ]`, comparing the *whole* matched line
  against the bare word. It can never be taken, so a rebuilding array is
  reported as "some other error ... investigate ASAP" instead of "check back
  later". An operator gets paged for a normal rebuild.
* **D63 (`sc_31`)** — `TEMPNO` is used six times and assigned nowhere, so every
  temperature message names a blank sensor.
* **D64 (`sc_31`)** — `HPTEMP`, the configured sensor filter, appears once:
  `echo ${HPTEMP}|egrep -q "${TEMPNO} "`, on a line of its own with the exit
  status discarded. The setting selects nothing; all 21 sensors in the shipped
  config are decorative.
* **D65 (`sc_31`)** — `WARNSTATUS` is initialised to 0 and never incremented, so
  the WARNING summary branch and `ERRNO[6]` are dead. `GLOBALERRMESSAGE` is
  likewise never appended to, so the error summary's detail is always empty.
* **D66 (shared library)** — found here but not a `sc_31` bug. `printlogmess`
  ends with `printf "${NEWFMTSTRING}\n"`, using the assembled message as the
  *format*, so a `%` in a message argument is reinterpreted:
  `20% is OK` prints as `20 0s OK`. `sc_33` works around it by escaping `%` to
  `%%`; nothing else does. Affects any script reporting a percentage.

`sc_31`'s lockfile protocol needs no fixture and is covered properly — a stale
lock is waited out, reported and removed, and the wait is bounded by
`LOCKFILE_MAX_WAIT_SEC`. Note the age is read with `stat --format=%Z`, which is
ctime, so a lock cannot be aged with `touch -d`.

**Not pursuing captures.** No HP hardware is available and none is being
sought, so the parsing in both scripts stays unverified by decision, not by
oversight. `sc_31`'s three-PSU positional assumption is the most likely place a
further defect hides; it is recorded and left. The defects above are logged and
these two scripts are done as far as this effort takes them.

### sc_36 — `omreport` fixtures, and an unresolved column order

[`sc_36_dell_health_sample_output.txt`](sc_36_dell_health_sample_output.txt)
holds a real `omreport` capture in its **default human-readable** format,
supplied 2026-09-14. `sc_36` does not read that format — every call it makes
passes `-fmt ssv` and the result is read with `cut -f N -d\;`. So the suite uses
two sources:

* the sample file, for realistic **values** — statuses, readings, probe names,
  threshold figures;
* the `#`-comments inside `sc_36_dell_health.sh`, which are real `-fmt ssv`
  captures **including the column headers**, for **column order**.

For temperatures, PSUs and power monitoring the two agree and the fixtures are
well grounded. **For fans they do not:**

```
ssv header (in the script)   Index;Status;Probe Name;Reading;...
                             0;Ok;System Board Fan2A;7200 RPM;840 RPM;...

human-readable (the sample)  Index : 0 / Status : Ok / Reading : 5400 RPM
                             Location : Fan 1
```

`Reading` comes *before* the name in one and *after* it in the other. The
fixtures follow the ssv header, because that is the format the script parses.
If the human-readable order turns out to be right for ssv as well, then
`cut -f3`/`cut -f4` are swapped and every fan message names a speed where the
name should be — verified by deliberately swapping the fixture, which produces
`Fan id: 0 status: Ok name: 5400 RPM rpm: Fan 1`. One real
`omreport chassis fans index=0 -fmt ssv` settles it.

Two other things the suite pins:

* `omreport` failing is not distinguished from a component being unhealthy —
  the script only ever looks at the parsed status field.
* `config/36.conf` defines `CPU[0]` under a `# check cpus with omreport chassis
  processors` comment, but the script has no processor check and never reads
  `CPU[]`. Dead setting, no warning.

The fake `omreport` dispatches on subcommand and replays a per-subcommand
fixture file, so **`sc_35` can reuse it** — it drives the same binary with
`storage pdisk` / `storage vdisk`.

### sc_39 — `lunacm` fixtures

[`sc_39_luna7_sample_output.txt`](sc_39_luna7_sample_output.txt) holds real
Luna 7 output, taken from the Thales
[LunaCM Command Reference](https://www.thalesdocs.com/gphsm/luna/7/docs/pci/Content/PDF_PCI/LunaCM%20Command%20Reference.pdf).
Build the fake `lunacm` from it rather than inventing a dialect.

`sc_39` drives two non-interactive sessions, piping commands into `lunacm` and
grading the combined output:

| session | commands | covered by the capture |
| --- | --- | --- |
| application (`LUNA_APPLICATION_SLOT`) | `slot set -slot N`, `slot list`, `role show -name co`, `partition showinfo` | `slot set` ✓, `role show` ✓, `partition showinfo` ✓ (two variants), **`slot list` missing** |
| environmental (`LUNA_ADMIN_SLOT`) | `slot set -slot N`, `slot list`, `hsm envshow` | **`hsm envshow` missing** — the capture has `hsm showinfo`, whose `Environmental:` block carries the same field names |

**What the capture already confirms.** Checked by running the script's own
extractors against the file:

* `parse_voltage` and `parse_temperature` accept the real unit suffixes —
  `Battery Voltage : 3.093 V` → `3.093`, `System Temp : 64 deg. C` → `64`. The
  threshold fields parse too (`2.750 V`, `75 deg. C`).
* `Partition Status -> L3 Device` is an arrow field and matches the literal the
  script compares against.
* `Fan 1 Status : active`, and the partition storage figures, extract cleanly.
* Every command in the capture ends `Command Result : No Error`, which is what
  the session guard counts.

**One suspected defect to confirm first.** `slot set` answers

```
Current Slot Id: 1 (Luna User Slot 7.0.1 (PW) Signing With Cloning Mode)
```

and `extract_colon_field ... "Current Slot Id"` returns the whole tail —
`1 (Luna User Slot 7.0.1 (PW) Signing With Cloning Mode)` — which is then
compared with `[[ ${APP_CURRENT_SLOT} != ${LUNA_APPLICATION_SLOT} ]]` against a
bare slot number. That can never match, and the session is failed with
"LunaCM did not select application slot".

It is *not* filed as a defect yet, because the extractor keeps the **last**
match and `slot list` runs after `slot set` — if `slot list` emits its own bare
`Current Slot Id:` line, the value is clean and the comparison works. Getting
`slot list` output settles it either way, and it is the first thing to establish
when this suite is written.

## Phase 4 — related scripts (900–942)

All 30 of these scripts now have suites. **Phase 4 is complete**, and with it
every phase of this plan. **The code moved under the plan as it was written**: 13 scripts were
modified on 2026-09-14/15 while working through
`related-available/BUGFIXES_AND_IMPROVEMENTS.md` — `905`, `906`, `915`, `917`,
`918`, `923`, `930`, `931`, `934`, `938`, `939`, `940`, `941` — and `918`, `923`
and `939` have since been deleted outright. Read that report, and the addenda in
`REPORT.md`, before designing a suite for `941` or `942`: both were touched in
that pass.

The groups account for all 30 scripts, each listed exactly once.

**`913_copy_ejbca_conf.sh` was deleted on 2026-09-14** at the maintainer's
direction, with its config, language file, ansible entries and docs section. It
called `906_ssh-copy-to-remote-machine.sh` positionally, which `906` does not
accept — so every one of its transfers already exited without doing anything.
Same defect class as D56 in `sc_28`.

**`921_copy_htmf_conf.sh` was deleted on 2026-09-16** for the same reason and in
the same way: it called both `915_remote_command_via_ssh.sh` and `906` with
positional arguments, and both take named options only, so it exited at its
first return-code check having copied nothing.

`917_archive_file.sh` had the same call-site defect but was **fixed rather than
deleted**, because `916` depends on it. Its own argument parsing was broken too:
the option loop `break`s on `--` without shifting past it, so every positional
landed one place to the right and it tried to archive a file literally named
`--`. `--keep-org` — which `916` passes — was not in the `getopt` long list
either, so `getopt` rejected it and the script carried on with no arguments at
all. Fixed as D75.

**`914_compare_master_slave_db.sh` was deleted on 2026-09-16**, for a different
reason from `913` and `921`: it ran perfectly well, but reported nothing to
monitoring (D86) and was superseded by `sc_32_check_db_sync.sh`, which answers
the same question with a content checksum rather than row counts, a settle
window for replication lag, retries, timeouts and full `printlogmess`
reporting. Its suite was deleted with it. Two cross-references that recommended
it — `lang/32.english` HELP[2] and `docs/db-consistency-check.md` — now point at
`pt-table-checksum` alone.

**Five more were deleted on 2026-09-16** at the maintainer's direction:
`926_local_htmf_copy_conf`, `928_check_dsm_backup`, `935_mysql_console_as_root`,
`936_mysql_console_as_db_user` and `937_delete_old_CRLData`. The suites for
`936` and `937` went with them.

`903_make_hsm_backup` was deleted the same day, emptying the HSM backup group.

`918_server_alive` was deleted on 2026-09-16 (D112/D113: no configuration
in which it answers correctly).

`923-rsync-to-remote-machine` and `924-backup-this-machine-to-remote-machine`
were deleted on 2026-09-16 (D118-D122: `923` could not transfer anything, and
`924` called it positionally).

`939_delete_old_elastic_index` was deleted on 2026-09-17; it never had an
ansible entry, so Elasticsearch is no longer a dependency of this phase.

Phase 4 was 43 scripts, then 42, 41, 40, 35, 34, 33, 31, and is now 30.

| Group                | Scripts                                          | Strategy                                                                                                                                                                                                                                                        | Status |
| -------------------- | ------------------------------------------------ | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------ |
| ssh / remote         | **complete** — 906, 907, 915, 930 | REAL-SVC sshd container with a generated keypair, via `start_sshd_node`. 930 is a composition test — it delegates the transfer to `906`                                                                                                                                                |        |
| mysql backup/restore | **complete** — 904, 920, 922, 931, 933, 938, 940 | REAL-SVC `mariadb:11`; round-trip dump → restore → verify row counts. Note `922` is named `922-simple-…` with a hyphen, unlike every other script                                                                                                                                                                                            |        |
| S3                   | **complete** — 941, 942                          | FAKE-BIN `curl` for now; REAL-SVC **MinIO** — replaces the fake-`curl` stub in `test/test-s3-backup-restore.bats`, which currently tests the stub's idea of S3 rather than S3                                                                                                            |        |
| EJBCA CLI            | **complete** — 900, 901, 902, 905, 909, 910, 919, 925, 927 | Mixed, not FAKE-BIN throughout: 900/901/902/919 drive real `openssl` (FIXTURE), 905/909/910/927 use `ejbca.sh` (FAKE-BIN), 925 shells out to `906`. 900/901/902 hang on their own input option — D82                                                                                                                                                                                                     |        |
| certificate validity | 934                                              | FIXTURE — `openssl` over PEM / DER / PKCS12 keystores holding certs of a chosen lifetime, driving `WARNINGDAYS` / `ERRORDAYS`. **JKS additionally needs `keytool`, i.e. a JDK in the base image** — the other three formats do not. Three defects were fixed here on 2026-09-15, see below | **in progress** |
| filesystem/archive   | **complete** — 908, 916, 917                          | REAL-OS with a populated temp tree                                                                                                                                                                                                                              |        |
| VIP                  | **complete** — 911, 912                          | FAKE-BIN `ifconfig`/`route`/`ping`/`arping`                                                                                                                                                                                                                                        |        |
| syscheck plumbing    | **complete** — 929, 932                          | REAL-OS on a crafted `var/last_status`, FAKE-BIN for the vendor message tool                                                                                                                                                                                                                          |        |

**Watch the filenames.** Three scripts use a dash rather than the
`NNN_name.sh` convention the rest follow, so a `9*_*.sh` glob silently misses
them: `922-simple-database-replication-check.sh`,
`923-rsync-to-remote-machine.sh`,
`924-backup-this-machine-to-remote-machine.sh`.

**`938` was rewritten after this plan was drafted** (`3a5e22c` cut 338 lines).
Derive its test design from the current script, not from this table — and note
that until 2026-09-15 it **did not parse at all** (an unterminated `${`), its
dispatch called both functions before either was defined, and its `elif` tested
`"full"` twice so `--incremental` was unreachable. All three are fixed, but the
incremental path has, as far as anyone can tell, never run. See item #32 in
`related-available/BUGFIXES_AND_IMPROVEMENTS.md`.

### 934 — three defects fixed 2026-09-15, suite in progress

Found while checking report item #14 and fixed before writing the suite:

* **`cmp_dates.py`'s result was never checked** despite a `# TODO check error`.
  On failure `timeDiffMin` is empty, `let timeDiffDays=...` errors and leaves
  the variable *unset*, the `-le` comparison then errors and is false, and the
  run falls through to the `else` — reporting the certificate as **INFO, fine**,
  with a blank day count. A certificate whose expiry could not be read was
  reported healthy. (Measured; the intuitive guess that it would report
  `0` days and therefore *expired* is wrong.)
* **`%m` where `%M` was meant** in `nowDate=$(TZ="GMT" date +"%b %d %H:%m:%S ...")`
  — that is the *month* in the minutes field, so "now" was wrong by up to 59
  minutes and every reported day count was quietly skewed.
* **Debug code and a dead guard**: `if [ $? -ne 0 ] ; then echo asdf ; exit ; fi`
  printed `asdf`, exited with **no code** (so 0, success), and tested `$?` after
  a pipeline ending in `sed`, so it never fired anyway.

All three live in `checkPEM`, which `checkJKS`, `checkDER` and `checkP12` all
funnel into, so one fix covers every format. The remaining `# TODO check error`
markers on the format conversions are now covered indirectly: a failed
conversion leaves no readable certificate, which the new `notAfter` guard
catches.

## Cross-cutting suites

- **`test_packaging.py`** — every script answers `--scriptid`/`--scriptname`,
  ids are unique, a fresh install has no pre-existing status, and two static
  guards that `NO_OF_ERR` covers every `ERRNO[]` index used and that each has a
  `DESCR[]`. _(done, 7 tests + 1 strict xfail)_
- **`test_shared_library.py`** — planned as `test_libsyscheck.py` and
  `test_printlogmess.py`; landed as one file covering both. Argument parsing
  (the `-c` hang), `initscript`, `isSyscheckOnHold`, the output formats across
  the four sinks, and `printlogmess` rejecting a malformed call rather than
  killing its caller. _(done, 17 tests)_
- **`test_monitoring_integration.py`** — not in the original plan. The
  Icinga/OP5 push path against a mock endpoint: level → status_code mapping for
  both backends, JSON validity, and hostile content in a message argument. This
  is the real integration contract, since nothing reads a script's exit status.
  _(done, 7 tests)_
- **`test_proc_checker.py`** — not in the original plan. `lib/proc_checker.sh`,
  the process lookup behind seven Phase 1 scripts (05, 12, 15, 16, 22, 23, 30):
  pidfile mode, stale pidfile, the name fallback, and the fact that it does not
  match its own command line. *(done, 8 tests, 2 strict xfail)*
- **`test_logbook.py`** — not in the original plan. `logbook.sh` rendering
  entries and `--read` terminating on a non-tty stdin. _(done, 7 tests)_
- **`test_syscheck_sh.py`** — `--testall`, `scripts-enabled` ordering,
  `last_status` truncation per run, the filter/send hooks. _(done, 28 tests,
  3 strict xfail)_ Also covers `--screen` reaching the child scripts, the
  OLDFMT of `last_status`, hook ordering 929 → 930 → 932, and the hold file
  stopping the orchestrator itself. It found D33 — an install with nothing
  enabled runs no checks, says so only in a raw shell error, and exits 0.

The mock HTTP server (`start_http_server`) was written during Phase 1 but first
used on 2026-09-13. It gained two things Phase 2 needed: routes that can be
rewritten without restarting the container — every web-facing check hard-codes
its URL path, so changing the response is the only way to drive its branches —
and `body_b64`, since a DER-encoded CRL cannot travel as a JSON string.

Still unplanned and uncovered: **`getroot.sh`** (patched for D19, the hold-file
delimiter, with no suite of its own) and **`console_syscheck.sh`**.

The original plan put `printlogmess` and `libsyscheck` right after Phase 1,
because three of the six sc_01 defects were shared-library defects that would
otherwise be rediscovered once per script. That paid off — D1, D2, D9, D17, D18
and D19 all came out of it — and the same argument carried `test_syscheck_sh.py`
to completion right after Phase 1 closed, which produced D33 and D34.

Both pieces of plumbing are done, so nothing in Phase 2, 3 or 4 is now blocked
on shared work. What is left uncovered is `getroot.sh` and
`console_syscheck.sh`, neither of which anything else runs on top of.

## Ordering rationale

Phase 1 needs no new containers and covers 19 of 38 scripts, so it converts the
existing smoke-level bats coverage into real assertions fastest. Phase 2 is
where testcontainers earns its keep and where the highest-risk logic lives
(PKI: CRL freshness, certificate expiry, OCSP). Phase 3 is mechanical. Phase 4
is the largest body of work and the one with real destructive potential
(backup/restore scripts), so it runs entirely against throwaway containers.
