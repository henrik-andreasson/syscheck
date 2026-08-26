# syscheck test report

Date: 2026-08-25
Scope of this pass: test infrastructure, `sc_01_diskusage.sh`, and the shared
library every script depends on. The plan for the remaining 37 `sc_` scripts and
43 `related` scripts is in [PLAN.md](PLAN.md).

## Summary

| | |
| --- | --- |
| Tests written | 92 |
| Passing (behaviour verified correct) | 84 |
| Strict xfail (confirmed open defect) | 8 |
| Failing unexpectedly | 0 |
| Defects found | 18 (D5 withdrawn on review) |
| Defects fixed in this pass | 7 |
| Scripts fully covered | 2 of 38 (`sc_01`, `sc_20`) + `logbook.sh` |
| Runtime | ~100s |

```
$ ./run.sh -q
84 passed, 8 xfailed in 140.63s
```

Every defect below was reproduced in a container, not inferred from reading.
Open defects have a test asserting the *correct* behaviour marked
`xfail(strict=True)`, so fixing one turns the test into a failure — that is the
signal to delete the marker.

---

# Fixed in this pass

## D1 — `printlogmess` aborted its caller and swallowed the message ✅ FIXED
`lib/printlogmess.sh`

The four validation guards ended in `exit`, not `return`. Since `printlogmess`
is a *function*, that terminated the **calling script**. Verified: with one
empty `FILESYSTEM[0]` and two healthy filesystems configured, `sc_01` produced
**zero messages and exited 0** — a single typo in `config/01.conf` silently
disabled disk monitoring for the whole host.

Compounding it, arguments are passed unquoted at every call site
(`-x ${SCRIPTINDEX}`), so an empty variable does not arrive as an empty string —
it vanishes, and the *next* flag is consumed as its value. `-x "" -l E` became
`-x -l`, so `LEVEL` was never assigned and the function died at
`wrong type of LEVEL ()`.

**Fix:** each guard now reports the missing flag, the calling script and the
offending call on stderr, then `return 1`. No `exit`, and no invented
substitute values — a fabricated log line is worse than none. The getopt-failure
path also returns instead of calling `schelp`, which used to dump help text into
the log stream and then log a garbage message anyway. `-9` also gained its
missing colon in the option string, without which `ARG9` — referenced in
`JSONSTRING` — could never be set.

Covered by 9 tests: one per missing field, both bad-level cases, the caller
surviving, and a well-formed call still returning 0.

## D2 — a typo'd command-line flag hung the script forever ✅ FIXED
`lib/libsyscheck.sh:17`, `syscheck.sh:30`

`default_script_getopt` declared short options `"hsvcin"` while the `case`
handled `s v i n a h`. The two sets disagreed in both directions:

- **`c` declared, no case arm.** getopt accepted `-c`, no branch matched, so
  nothing shifted and `while true` spun on the same argument forever at 100%
  CPU. `timeout 5 sc_01_diskusage.sh -c` → exit 124. `syscheck.sh -c` had the
  identical bug via its `"hsvct"` string. From cron that pins one core per tick.
- **`a` had a case arm but was not declared.** GNU getopt writes a usable `--`
  to stdout even when it fails, and there was no `exit` after `schelp`, so a
  bogus flag printed the help text *and then ran the check anyway* — `-z`, `-a`
  and a normal run all wrote the same 4 lines to `last_status`. `-a`, the
  intended short form of `--scripthumanname`, could therefore never work.

**Fix:** option string aligned to `"hsvain"` (`syscheck.sh` to `"hsvt"`), a
`*)` backstop arm added so an unhandled option can never reach the top of the
loop, and `exit 1` after `schelp` on getopt failure.

Covered by 11 tests: four unknown-flag variants against `sc_01` and `syscheck.sh`,
a check that a rejected flag writes nothing to any sink, and both the short and
long form of all three metadata flags.

## D3 — unquoted config expansion corrupted the check identity ✅ FIXED
`scripts-available/sc_01_diskusage.sh:69`

```bash
diskusage ${FILESYSTEM[$i]} ${USAGEPERCENT[$i]} ${WARN_PERCENT[$i]} ${SCRIPTINDEX}
```

With `FILESYSTEM[0]="/mnt/data/dir with space"` the four arguments became seven
and everything shifted: `ERRLIMIT` became the word `with`, and `SCRIPTINDEX`
became `95`. The index is not cosmetic — `send_mess_to_monitoring` builds the
service name as `sc_${SCRIPTNAME}_${SCRIPTID}_${SCRIPTINDEX}`, so a corrupted
index submits the result against a service that does not exist in Icinga/OP5.
And the disk that was supposed to be checked never was.

**Fix:** quoted the call site, the two `df` invocations, and the `-gt`
comparisons.

## D4 — a config entry with an empty or missing value produced no message ✅ FIXED
Consequence of D1 + D3.

The guard clauses at `sc_01:33` and `sc_01:37`, written precisely to catch this,
were **unreachable** — word splitting removed the empty argument before the
function saw it. With D1 and D3 fixed they now fire:

```
01-01-E-013-PKI ... ERROR - diskusage Diskusage problems (No filesystem specified : )
01-02-I-011-PKI ... INFO - diskusage Diskusage ok (/mnt/tfs_a is 61 percent used...)
01-03-I-011-PKI ... INFO - diskusage Diskusage ok (/mnt/tfs_b is 0 percent used...)
```

The bad entry alarms, later entries are still checked, and the indexes are right.

## D6 — `sc_20_errors_ejbcalog.sh` reported a clean log it never read ✅ FIXED
`lib/tail_errors_from_ejbca_log.py:1`, `scripts-available/sc_20_errors_ejbcalog.sh:38`

The helper's shebang was `#!/usr/bin/python`, which does not exist on Debian, so
it exited 127. Verified against a log containing two genuine errors:

```
2026-08-25 10:00:02,200 ERROR [org.ejbca.core] CA Token is disconnected
2026-08-25 10:00:03,300 ERROR [org.ejbca.core] Error Connecting to EJBCA Database

  -> 20-02-I-201-PKI ... INFO - ejbcaerrorlog No new errors in ejbca server log
```

A disconnected CA token and a dead database connection, reported to monitoring
as green. Commit `b8c636f` fixed the other two helpers and missed this one, so
this check has been dead on every Debian host since the Python 2 sunset.

Two things made it silent rather than loud: `sc_20:38` sent the helper's stderr
to `/dev/null`, and it never checked the exit status — an empty `NEWERRORS`
could not be told apart from "the helper never ran", and both took the INFO
branch.

**Fix:** shebang to `python3`; stderr captured instead of discarded; exit status
checked, with a new `ERRNO[5]` / `DESCR[5]` ("Log checker tool failed") so
"tool broken" is distinguishable in monitoring from "log missing" (`ERRNO[3]`)
and from "log clean" (`ERRNO[1]`). The helper's `deltat` first-run notice moved
from stdout to stderr, where its three sibling diagnostics already went — on
stdout it was counted as a matched error line.

Covered by 10 tests: clean log, errors found, position-file resume across runs,
appended errors, `IGNORE[]` filtering, missing logfile, a helper that cannot
start, a helper that crashes, and the diagnostics-not-counted-as-errors case.

**Watch out when patching these scripts:** `initscript` sets `set -o noclobber`
(`libsyscheck.sh:53`), so a plain `2>"$file"` into an existing `mktemp` file
fails with "cannot overwrite existing file". The fix needs `2>|`. The test suite
caught this in the first version of the patch.

## D7 — `logbook.sh` could not display any entry, and `--read` never terminated ✅ FIXED
`logbook.sh:91`, `logbook.sh:108`, `logbook.sh:123`

Two independent defects on the same code path.

The JSON renderer was

```bash
echo $row | python -c 'import json,sys;obj=json.load(sys.stdin);print obj["LEGACYFMT"]'
```

which is wrong twice over: bare `python` does not exist on Debian, and
`print obj[...]` is Python 2 syntax that would be a `SyntaxError` anywhere it
did exist. Every logbook entry was invisible.

Separately, `logbook.sh:123` looped on `while [ true ]` with a bare `read a`.
Whenever stdin is not a terminal — cron, a pipe, `< /dev/null` — `read` returns
immediately at EOF and the loop spins forever, walking one day further back on
each pass and spawning a `date`, a `grep` and a `python` every time. This is the
same shape as D2 and it was found the hard way: it hung the test suite for the
full 600s timeout.

Verified before and after against the same logbook file:

```
HEAD (before fix)    exit=124   renders_entry=False
     | logbook.sh: line 108: python: command not found
fixed                exit=0     renders_entry=True
     | 701-00-I-7011-PKI 20260825 09:00:00 h: INFO - logbook restarted the CA service
```

**Fix:** the two duplicated one-liners replaced by a single
`render_logbook_entries` helper that runs one `python3` for the whole batch
rather than one process per row, and prints an unparseable row verbatim instead
of dying on it, so one corrupt line cannot hide the rest of the day. `read a`
became `read a || break`. `logbook.sh` also got the D2 treatment its getopt
block was missing: `exit 1` after `schelp`, and a `*)` backstop arm.

Covered by 7 tests in `test_logbook.py`, all driven as an unprivileged user
because `logbook.sh` refuses to run as root.

**A note on the evidence:** the original D7 entry cited
`test_packaging.py::test_logbook_list_renders_entries`. That test was invalid —
it passed a `--list` flag that does not exist and ran as root, so it never
reached the renderer at all. It has been deleted and replaced by the real suite.
The defect itself was genuine, as the before/after above shows.

---

# Open defects

## ~~D5 — scripts exit 0 regardless of what they found~~ ❌ WITHDRAWN, not a defect

I originally filed this on the assumption that syscheck scripts are nagios
plugins whose exit status nagios reads. They are not. Syscheck runs from cron
and **pushes** a passive check result to the Icinga/OP5 HTTP API via
`send_mess_to_monitoring`, which maps the message level to a `status_code`.
Nothing consumes the scripts' exit status, so exiting 0 is correct and
deliberate.

The real integration contract is the API payload, which was untested. Testing it
turned up D17 and D18 below. `sc_01`'s exit code is now pinned at 0 by
`test_exit_code_is_zero_even_when_an_error_is_reported` so nobody "fixes" it.

## D8 — the "syscheck is on hold" notice prints the literal string `00`
`lib/libsyscheck.sh:82`

```bash
printf "00" "0" $WARN "00" "SYSCHECK IS ON HOLD BY: ${ONHOLDBY} OPERATION CANCELED SCRIPTID: ${SCRIPTID}"
```

The format string has no conversion specifiers, so `printf` writes `00` and
discards all five arguments. When maintenance puts syscheck on hold the operator
sees `00` and no explanation of why every check went quiet.

`test_shared_library.py::test_syscheck_on_hold_tells_the_operator_who_holds_it`

## D9 — the on-hold path hard-depends on `sudo`
`lib/libsyscheck.sh:81`

The hold notice is logged via `sudo ${SYSCHECK_HOME}/lib/printlogmess-cli.sh`.
Where `sudo` is absent — or where syscheck already runs as root, the normal
case — this prints `sudo: command not found` and the hold is never recorded.

`test_shared_library.py::test_syscheck_on_hold_is_logged_without_requiring_sudo`

## D10 — `sc_19_alive.sh` reports `[3]` instead of a message
`scripts-available/sc_19_alive.sh:27`

`-d "$DESCR[3]"` should be `-d "${DESCR[3]}"`. Bash expands `$DESCR` as
`${DESCR[0]}` (unset) followed by the literal `[3]`:

```
19-01-I-193-PKI ... INFO - alive [3]
```

The heartbeat message the script exists to send is empty.

*Confirmed by observation; test lands with the `sc_19` suite in Phase 1.*

## D11 — `sc_32_check_db_sync.sh` is disabled in place
`scripts-available/sc_32_check_db_sync.sh:33`

A hard-coded `echo "This script is broken"` followed by `exit`, with the real
comparison logic stranded as dead code below. In a default install it exits even
earlier, because the `808-test-table-update-and-check-master-and-slave.sh` it
requires is not shipped, and emits a permanent ERROR into monitoring. Note the
index is `00`, not `01` — the early-exit path returns before `addOneToIndex`, so
this is the only message in the system using index `00`.

*Confirmed by observation; test lands with the `sc_32` suite in Phase 1.*

## D12 — the package ships 291 lines of someone else's status
`var/last_status`

Committed to git containing status from a Nov-2025 build container
(`eba9e0811f66`, `b998b92e8ac5`), including `ERROR` lines. `lib/release.sh:83`
copies `var/` into the package, so a freshly installed syscheck reports
historical failures from another machine before it has run once. Anything
reading `last_status` — `console_syscheck.sh`, `929_filter`, `930_send…` — picks
them up.

`test_packaging.py::test_fresh_install_has_no_pre_existing_status`

## D13 — `df` is executed twice per filesystem
`sc_01:45` and `sc_01:51`

The first call captures output for the error path, the second re-runs `df` for
the percentage. On a hung NFS mount that doubles the stall, and the percentage
reported is not the one the threshold was evaluated against.

`test_sc_01_diskusage.py::test_df_is_only_executed_once_per_filesystem`

## D14 — `diskusage()` uses `return -1`
`sc_01:34`, `sc_01:38`

Not valid in bash; wraps to 255. The caller ignores it either way. Cosmetic, but
it signals the guards were meant to do something they did not (see D4).

*No test; noted for the cleanup pass.*

## D15 — `sc_41_ra_verifier.sh` references a variable that does not exist
`scripts-available/sc_41_ra_verifier.sh:29`

```bash
-d "$DESCR_3"
```

There is no `DESCR_3`; the lang file defines `DESCR[3]="RA : health check tool
failure"`. Same class as D10. Under the old library this hit the `DESCR must be
passed` guard and **killed the script**; with D1 fixed it now surfaces:

```
printlogmess: missing description (-d), called by sc_41_ra_verifier.sh: -n ra_verifier -i 41 -x 00 -l E -e 413 -d
```

Found by sweeping all 38 scripts after the D1 fix — it was invisible before.
Note `-x 00`: `SCRIPTINDEX` is also never incremented on this path.

*Found this pass; test lands with the `sc_41` suite in Phase 1.*

## D16 — `sc_44_cert_from_webserver.sh` hangs indefinitely on an unreachable host
`scripts-available/sc_44_cert_from_webserver.sh:66`

```bash
echo "" | openssl s_client -connect $ARGCONNECT -servername $SERVICENAME >> $outname 2>&1
```

No timeout. Against the shipped config (`192.168.99.21`, unroutable here) the
script runs past 120s with zero output and has to be killed. **Verified
pre-existing** — it behaves identically with the `HEAD` versions of
`libsyscheck.sh`/`printlogmess.sh`/`syscheck.sh` restored, so it is not a
regression from this pass. `sc_10_ocsp.sh` passes `-timeout` to `openssl ocsp`;
`sc_44` passes nothing.

Same failure mode as D2 from a monitoring standpoint: a stuck process per cron
tick.

*Found this pass; test lands with the `sc_44` suite in Phase 2.*

## D17 — every Icinga check result is submitted as literal, unexpanded text
**Scope: the entire Icinga integration.** `lib/printlogmess.sh:105`

```bash
curl ... -d '{ "exit_status": $status_code, "plugin_output": "${MESSAGE}", "check_source": "${check_source}" }'
```

The payload is **single-quoted**, so bash never expands any of it. Verified
against a mock endpoint — this is the exact body Icinga receives:

```
POST /v1/actions//process-check-result?host=syscheck-test
{ "exit_status": $status_code, "plugin_output": "${MESSAGE}", "check_source": "${check_source}" }
```

No status, no message, and not even valid JSON — `$status_code` is a bare token
where a number belongs. Anyone running with `SENDTO_ICINGA=1` gets nothing
usable, for every check, on every host.

The OP5 branch fifteen lines above builds the same thing correctly with escaped
double quotes, which is presumably where the working version lives.

`test_monitoring_integration.py::test_icinga_maps_syscheck_level_to_exit_status`

## D18 — the shipped OP5 URL is doubled
`lib/printlogmess.sh:86` + `config/monitoring.conf`

`config/monitoring.conf` sets

```
OP5_API_URL="https://op5servername/api/command/PROCESS_SERVICE_CHECK_RESULT"
```

and line 86 posts to `"${OP5_API_URL}/PROCESS_SERVICE_CHECK_RESULT"`, producing
`.../PROCESS_SERVICE_CHECK_RESULT/PROCESS_SERVICE_CHECK_RESULT`. Either the code
should not append the endpoint or the shipped config should not include it;
today they disagree, so the out-of-the-box config posts to the wrong URL.

Cosmetic sibling: `ICINGA_API_URL` ends with `/` and line 105 adds another, so
the Icinga path contains `//`. Harmless, but the same inconsistency.

`test_monitoring_integration.py::test_op5_url_from_the_shipped_config_is_not_doubled`

---

# What is verified working

`sc_01_diskusage.sh` — 27 passing tests against real tmpfs filesystems filled to
known percentages:

- INFO / WARN / ERROR selection across the `USAGEPERCENT` / `WARN_PERCENT` pair
- boundary semantics: usage exactly at the limit is not an error (`-gt`), one
  percent over is
- `WARN_PERCENT` omitted, and the literal `default` keyword, both fall back to
  the error limit
- a non-existent filesystem reports ERROR 013 and forwards the `df` error text
- a filesystem path containing spaces is checked correctly (D3 regression guard)
- an empty entry or missing limit reports a config error and does not stop later
  entries (D1/D4 regression guard)
- a broken entry does not stop the remaining filesystems
- script indexes are per-filesystem, zero-padded, and keep counting past 9
- all four output sinks: screen, `var/last_status` (OLDFMT), the plain logfile
  (NEWFMT), and syslog via a real `rsyslogd`
- all three formats: NEWFMT, OLDFMT, and JSON with correct `EXTRAARG*` mapping
- silence without `--screen`, while still writing the other sinks
- `--help` does not emit a fake check result

Monitoring integration — 5 passing tests against a mock Icinga/OP5 endpoint:
the OP5 payload maps I/W/E to `status_code` 0/1/2 correctly, carries
`sc_<name>_<id>_<index>` as the service description and the rendered message as
`plugin_output`, and is valid JSON. This is the path that actually feeds
monitoring and it had no coverage at all before this pass.

Shared library — 20 passing tests: `addOneToIndex` padding, refusal to run with a
missing config or language file, `MESSAGELENGTH` truncation, the on-hold file
suppressing the check, the full `printlogmess` validation contract, and the
argument parser (unknown flags rejected without hanging or running the check;
short and long metadata flags).

Install-wide — every script answers `--scriptid`/`--scriptname`, and all 38 ids
are unique.

# Notes on the test infrastructure

pytest + testcontainers under `test/containers/`. It does not replace the
existing bats suites; those check that each script prints *a* line starting with
its id. These check *which* line, at which level, with which error number, in
which sink.

**Real filesystems over a stubbed `df`.** `sc_01` runs against tmpfs mounts the
harness fills to a measured percentage. The same principle applies through the
plan: real MariaDB, Redis, nginx, MinIO and a real OpenSSL OCSP responder
wherever the dependency can be containerised.

**Vendor tooling is the fidelity gap.** `omreport`, `ilorest`, `ssacli`,
`lunacm` and `mdadm` cannot be containerised, so Phase 3 fakes them. Those tests
will prove the parsing and threshold logic but not that the real tools speak that
dialect. One captured output sample per tool from production hardware is the
single most useful thing to collect before Phase 3.

**`--screen` now goes to stderr.** `lib/printlogmess.sh` was changed during this
work to write screen output to stderr and to stop leaking `IFS=$'\n'` into the
caller. The harness reads both streams. Worth checking `console_syscheck.sh` and
any downstream consumer that pipes script stdout, since they will now see an
empty pipe.

# Recommended order for the remaining fixes

1. **D17** — one pair of quotes. If anyone runs with `SENDTO_ICINGA=1`, every
   check result they have ever submitted was unexpanded literal text. Nothing
   else on this list is silently wrong at that scale.
2. **D16** — add a timeout to `sc_44`; a hanging check is worse than a failing
   one. Audit the other `openssl`/`curl` call sites for the same gap.
3. **D18** — decide whether the endpoint lives in the code or the config.
4. **D15 + D10** — one-word fixes, both currently losing a message.
5. **D12** — `git rm --cached var/last_status`, add to `.gitignore`.
6. **D8 + D9 + D13 + D14** — small and independent.
7. **D11** — decide whether `sc_32` is repaired or removed; today it is neither.

A `shellcheck` step in `.github/workflows/ci.yml` would have caught D1, D3, D10,
D15 and D17 statically (SC2016 flags exactly the D17 single-quote mistake), and
is the cheapest guard against the whole class returning.
