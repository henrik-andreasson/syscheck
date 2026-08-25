# syscheck test report

Date: 2026-08-25
Scope of this pass: test infrastructure, `sc_01_diskusage.sh`, and the shared
library every script depends on. The plan for the remaining 37 `sc_` scripts and
43 `related` scripts is in [PLAN.md](PLAN.md).

## Summary

| | |
| --- | --- |
| Tests written | 47 |
| Passing (behaviour verified correct) | 34 |
| Strict xfail (confirmed defect) | 13 |
| Failing unexpectedly | 0 |
| Distinct defects found | 14 |
| Scripts fully covered | 1 of 38 (`sc_01`) |
| Runtime | ~90s |

```
$ ./run.sh -q
34 passed, 13 xfailed in 92.81s
```

Every defect below was reproduced in a container, not inferred from reading.
Each has a test that asserts the *correct* behaviour and is marked
`xfail(strict=True)`, so fixing the bug turns the test into a failure — that is
the signal to delete the marker.

## Defects

Ordered by blast radius. "Scope" is how many scripts the defect affects.

### D1 — `printlogmess` silently discards the message when any required argument is empty
**Scope: all 38 scripts.** `lib/printlogmess.sh:150-167`

If `-n`, `-i`, `-x` or `-d` receives an empty value, `printlogmess` prints a
diagnostic and returns without writing to *any* sink — screen, syslog,
`var/last_status`, the plain logfile, and the OP5/Icinga API all get nothing.

Worse, the arguments are passed unquoted at every call site
(`-x ${SCRIPTINDEX}`), so an empty variable does not arrive as an empty string;
it vanishes and the *next* flag is consumed as its value. `-x "" -l E` becomes
`-x -l`, `LEVEL` is never assigned, and the function aborts at `wrong type of
LEVEL ()`.

Net effect: **a misconfigured check reports nothing at all rather than
reporting that it is misconfigured.** For a monitoring system this is the worst
possible failure mode — the operator sees a green board.

`test_shared_library.py::test_printlogmess_with_an_empty_scriptindex_still_reports_something`

### D2 — a typo'd command-line flag hangs the script forever
**Scope: all 38 scripts + `syscheck.sh`.** `lib/libsyscheck.sh:17`

`default_script_getopt` declares short options `"hsvcin"` but the `case`
statement has no arm for `-c` (`syscheck.sh:30` has the same problem with `-t`
declared as `hsvct`). An unmatched arm means nothing shifts, and the enclosing
`while true` loop spins on the same argument forever, burning a core.

```
$ timeout 10 scripts-available/sc_01_diskusage.sh -c
$ echo $?
124
```

If this runs from cron the process accumulates: one stuck process per tick.

`test_shared_library.py::test_declared_but_unhandled_short_option_does_not_hang`

### D3 — unquoted config expansion corrupts the check identity
**Scope: `sc_01`, and the same pattern appears in every array-driven script.**
`scripts-available/sc_01_diskusage.sh:69`

```bash
diskusage ${FILESYSTEM[$i]} ${USAGEPERCENT[$i]} ${WARN_PERCENT[$i]} ${SCRIPTINDEX}
```

With `FILESYSTEM[0]="/mnt/data/dir with space"` the four arguments become seven,
and every parameter shifts:

| intended | actual |
| --- | --- |
| `FILESYSTEM=/mnt/data/dir with space` | `/mnt/data/dir` |
| `ERRLIMIT=95` | `with` |
| `WARNLIMIT=90` | `space` |
| `SCRIPTINDEX=01` | `95` |

Observed output: `01-95-E-013-PKI ... Diskusage problems (/mnt/data/dir : df:
/mnt/data/dir: No such file or directory)`. The script index is what
nagios/icinga correlate alerts on, so this silently reassigns the alert to a
different check id — and the disk that was supposed to be checked never was.

`test_sc_01_diskusage.py::test_filesystem_path_containing_spaces_is_checked_correctly`

### D4 — a config entry with an empty or missing value produces no message
**Scope: `sc_01`, likely all array-driven scripts.** Consequence of D1 + D3.

| config | intended | actual |
| --- | --- | --- |
| `FILESYSTEM[0]=""` | ERROR 013 "No filesystem specified" | nothing |
| `USAGEPERCENT[0]` unset | ERROR 013 "No limit specified" | nothing, plus `[: default: integer expression expected` on stderr |

The two guard clauses at `sc_01:33` and `sc_01:37` that exist precisely to catch
this are **unreachable** through the loop, because word splitting removes the
empty argument before the function sees it.

`test_sc_01_diskusage.py::test_empty_filesystem_entry_reports_a_config_error`,
`::test_missing_usagepercent_reports_a_config_error`

### D5 — scripts exit 0 regardless of what they found
**Scope: 31 of 38 scripts.**

Every `sc_*.sh` header says the script name is "used when integrating with
nagios/icinga", and nagios decides state from the **exit code**. `sc_01` exits 0
after emitting `ERROR - Diskusage exceeded`. Only 7 scripts ever exit non-zero
(`sc_07`, `sc_10`, `sc_12`, `sc_17`, `sc_18`, `sc_22`, `sc_23`) and they do not
agree on a convention — `sc_18` uses `exit 3`, which in nagios terms is
UNKNOWN, not CRITICAL.

Any integration that shells out to these scripts and checks `$?` sees success
100% of the time.

`test_sc_01_diskusage.py::test_exit_code_is_nonzero_when_an_error_is_reported`

### D6 — `sc_20_errors_ejbcalog.sh` cannot run on Debian at all
**Scope: `sc_20`.** `lib/tail_errors_from_ejbca_log.py:1`

The shebang is `#!/usr/bin/python`, which does not exist on Debian (or any
distro since the Python 2 sunset). The helper exits 127 with *"cannot execute:
required file not found"*, `NEWERRORS` is empty, and `sc_20` reports "no new
errors" — for an EJBCA log it never read.

Commit `b8c636f` ("Fix unambigous/incorrect python shebang") fixed
`cmp_dates.py` and `list-pcsc-readers.py` and missed this one.

`test_packaging.py::test_python_helpers_are_executable_on_a_stock_debian`

### D7 — `logbook.sh --list` is dead code
**Scope: `logbook.sh`.** Lines 91 and 108

```bash
echo $row | python -c 'import json,sys;obj=json.load(sys.stdin);print obj["LEGACYFMT"]'
```

Two problems at once: bare `python` (absent on Debian) and Python 2 `print`
syntax (a `SyntaxError` even where `python` exists). Listing the logbook emits
nothing.

`test_packaging.py::test_logbook_list_renders_entries`

### D8 — the "syscheck is on hold" notice prints the literal string `00`
**Scope: all 38 scripts.** `lib/libsyscheck.sh:82`

```bash
printf "00" "0" $WARN "00" "SYSCHECK IS ON HOLD BY: ${ONHOLDBY} OPERATION CANCELED SCRIPTID: ${SCRIPTID}"
```

The format string contains no conversion specifiers, so `printf` writes `00` and
throws away all five arguments. When maintenance puts syscheck on hold the
operator sees `00` and no explanation of why every check went quiet.

`test_shared_library.py::test_syscheck_on_hold_tells_the_operator_who_holds_it`

### D9 — the on-hold path hard-depends on `sudo`
**Scope: all 38 scripts.** `lib/libsyscheck.sh:81`

The hold notice is logged via `sudo ${SYSCHECK_HOME}/lib/printlogmess-cli.sh`.
Where `sudo` is not installed — or where syscheck already runs as root, which is
the normal case — this prints `sudo: command not found` and the hold is never
recorded in syslog.

`test_shared_library.py::test_syscheck_on_hold_is_logged_without_requiring_sudo`

### D10 — `sc_19_alive.sh` reports `[3]` instead of a message
**Scope: `sc_19`.** `scripts-available/sc_19_alive.sh:27`

`-d "$DESCR[3]"` should be `-d "${DESCR[3]}"`. Bash expands `$DESCR` as
`${DESCR[0]}` (unset) followed by the literal text `[3]`:

```
19-01-I-193-PKI 20260825 16:08:55 syscheck-test: INFO - alive [3]
```

The heartbeat message the script exists to send is empty.

*Confirmed by observation; the test lands with the `sc_19` suite in Phase 1.*

### D11 — `sc_32_check_db_sync.sh` is disabled in place
**Scope: `sc_32`.** `scripts-available/sc_32_check_db_sync.sh:33`

The script contains a hard-coded `echo "This script is broken"` followed by
`exit`, with the real comparison logic stranded as dead code below it. In a
default install it never reaches that line either — it exits earlier because
`$SYSCHECK_HOME/database-replication/808-test-table-update-and-check-master-and-slave.sh`
is not shipped, and reports:

```
32-00-E-322-PKI ... ERROR - db_sync DB not in sync ... missing script
```

So a check that is *known broken* emits a permanent ERROR into monitoring.
Note also the script index is `00`, not `01` — the early-exit path returns
before `addOneToIndex`, so this message is the only one in the system using
index `00`.

*Confirmed by observation; the test lands with the `sc_32` suite in Phase 1.*

### D12 — the package ships 291 lines of someone else's status
**Scope: install / packaging.** `var/last_status`

`var/last_status` is committed to git containing status from a Nov-2025 build
container (`eba9e0811f66`, `b998b92e8ac5`), including `ERROR` lines.
`lib/release.sh:83` copies `var/` into the package, so a freshly installed
syscheck reports historical failures from another machine before it has run
once. Anything that reads `last_status` — `console_syscheck.sh`, `929_filter`,
`930_send_filtered_result_to_remote_machine` — will pick them up.

`test_packaging.py::test_fresh_install_has_no_pre_existing_status`

### D13 — `df` is executed twice per filesystem
**Scope: `sc_01`.** `sc_01:45` and `sc_01:51`

The first call captures output for the error path, the second re-runs `df` to
extract the percentage. On a hung NFS mount that doubles the stall, and the
percentage reported to the operator is not the one the threshold was evaluated
against.

`test_sc_01_diskusage.py::test_df_is_only_executed_once_per_filesystem`

### D14 — `diskusage()` uses `return -1`
**Scope: `sc_01`.** `sc_01:34`, `sc_01:38`

`return -1` is not valid in bash; the status wraps to 255. The return value is
never checked by the caller either way, so this is cosmetic — but it signals the
guard clauses were meant to do something they do not do (see D4).

*No test; noted for the cleanup pass.*

## What is verified working

`sc_01_diskusage.sh` — 22 passing tests against real tmpfs filesystems filled to
known percentages:

- INFO / WARN / ERROR selection across the `USAGEPERCENT` / `WARN_PERCENT` pair
- boundary semantics: usage exactly at the limit is not an error (`-gt`), one
  percent over is
- `WARN_PERCENT` omitted, and the literal `default` keyword, both fall back to
  the error limit
- a non-existent filesystem reports ERROR 013 and forwards the `df` error text
- a broken entry does not stop later entries from being checked
- script indexes are per-filesystem, zero-padded, and keep counting past 9
- all four output sinks: screen, `var/last_status` (OLDFMT), the plain logfile
  (NEWFMT), and syslog via a real `rsyslogd`
- all three formats: NEWFMT, OLDFMT, and JSON with correct `EXTRAARG*` mapping
- silence without `--screen`, while still writing the other sinks
- `--scriptid`, `--scriptname`, `--scripthumanname`, `--help`
- `--help` does not emit a fake check result

Shared library — 5 passing tests: `addOneToIndex` padding, refusal to run with a
missing config or language file, `MESSAGELENGTH` truncation, and the on-hold file
genuinely suppressing the check.

Install-wide — every script answers `--scriptid`/`--scriptname`, and all 38 ids
are unique.

## Notes on the test infrastructure

The suite is pytest + testcontainers under `test/containers/`. It does not
replace the existing bats suites; those check that each script prints *a* line
starting with its id, which is a smoke test. These check *which* line, at which
level, with which error number, in which sink.

Two decisions worth flagging:

**Real filesystems over a stubbed `df`.** `sc_01` is driven against tmpfs mounts
that the harness fills to a measured percentage, so `df -Ph` parsing is covered
for real. The same principle applies through the plan: real MariaDB, Redis,
nginx, MinIO and a real OpenSSL OCSP responder rather than fake binaries,
wherever the dependency can be containerised.

**Vendor tooling is the fidelity gap.** `omreport`, `ilorest`, `ssacli`,
`lunacm` and `mdadm` cannot be containerised, so Phase 3 fakes them. Those tests
will prove the parsing and threshold logic but not that the real tools speak
that dialect. One captured output sample per tool from production hardware would
be worth more than any number of additional invented cases — that is the single
most useful thing to collect before Phase 3.

**Mid-session change picked up.** `lib/printlogmess.sh` was edited during this
work to send `--screen` output to stderr (and to stop leaking `IFS=$'\n'` into
the caller). The harness reads both streams, so the suite covers the new
behaviour. Worth checking `console_syscheck.sh` and any downstream consumer that
pipes script stdout, since they will now see an empty pipe.

## Recommended order of fixes

D1 and D3 are the same root cause — unquoted expansion — and fixing them
requires quoting call sites throughout, so they are best done as one pass with
`shellcheck` wired into CI to keep them from coming back. That single pass also
resolves D4.

1. **D1 + D3 + D4** — quote every expansion; add `shellcheck` to `.github/workflows/ci.yml`
2. **D2** — add the missing `case` arms, or a `*) shift;;` fallback
3. **D6 + D7** — `python` → `python3`, and port the two `logbook.sh` one-liners
4. **D5** — decide a convention (nagios: 0/1/2/3) and apply it uniformly
5. **D12** — `git rm --cached var/last_status`, add to `.gitignore`
6. **D8 + D9 + D10 + D13 + D14** — small, independent
7. **D11** — decide whether `sc_32` is repaired or removed; today it is neither
