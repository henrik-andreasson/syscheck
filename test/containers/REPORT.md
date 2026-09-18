# syscheck test report

Date: 2026-08-25, with addenda through 2026-09-14.
Scope of the first pass: test infrastructure, `sc_01_diskusage.sh`, and the
shared library every script depends on. The plan for the remaining `sc_` scripts
and 43 `related` scripts is in [PLAN.md](PLAN.md).

---

# Addendum 2026-09-15 (third) — `sc_35`, and Phase 4 opens

```
$ ./run.sh -q
553 passed, 18 xfailed in 952.03s (0:15:52)
```

## Phase 4 opens — `934_check_validity_of_installed_certs.sh`

**The first `related-available` suite**: 18 tests, 2 strict xfails. Certificates
are minted by `openssl req -x509` in the container, with `-not_after` producing
genuinely expired ones rather than simulated. PEM, DER and PKCS12 are covered;
**JKS is not** — `checkJKS` needs `keytool`, i.e. a JDK layer in the image. All
four formats funnel into `checkPEM`, so the verdict logic is covered regardless.

### Three defects fixed before the suite was written

* **`cmp_dates.py`'s result was used unchecked**, despite a `# TODO check error`
  on the next line. The intuitive reading of this is wrong and worth recording:
  an empty `timeDiffMin` does *not* yield `0` days and therefore "expired". `let
  timeDiffDays="$timeDiffMin / 60 / 24"` **errors and leaves the variable
  unset**, the `-le` comparison then errors and is false, and control falls to
  the `else` — reporting the certificate as **healthy**, with a blank day count.
  A certificate whose expiry could not be read was reported fine. Now guarded
  with `case ''|*[!0-9-]*`; the `-` matters, because an expired certificate
  returns negative minutes and must still reach the comparison.
* **`%m` where `%M` was meant** — `nowDate=$(TZ="GMT" date +"%b %d %H:%m:%S ...")`
  put the *month* in the minutes field, so "now" was wrong by up to 59 minutes
  and every reported day count was skewed.
* **Debug code and a dead guard** — `if [ $? -ne 0 ] ; then echo asdf ; exit ; fi`
  printed `asdf`, exited with no code (so 0, success), and tested `$?` after a
  pipeline ending in `sed`, so it never fired.

All three are in `checkPEM`. A useful consequence: the remaining
`# TODO check error` markers on the keytool/openssl format conversions are now
covered indirectly, since a failed conversion leaves no readable certificate and
the new `notAfter` guard catches it.

### Two new defects the suite found

**D71** — `checkDER` and `checkP12` each register `trap "rm -f -- '$certFile'"
EXIT`. Bash traps are global and a second `trap ... EXIT` *replaces* the first,
so with several DER or P12 entries only the last temp file is removed. Same leak
`sc_08` had; the same answer applies — a `RETURN` trap, which scopes to the
function and fires once per call.

**D72** — all three descriptions read `"File: %s subj: %s days until expiry: %s"`
but every call passes `-1 file -2 days -3 subject`, so the labels are attached
to the wrong values:

```
File: /tmp/certs/fresh.pem subj: 364 days until expiry: subject=CN=fresh.example.com
```

The information is all present, which is why it survived, but anything reading
or parsing the line gets the fields transposed. Fixed by swapping the last two
placeholders in `lang/934.english`, or the `-2`/`-3` arguments at the three call
sites.

## `sc_35` — D67 and D69 fixed, D68 postponed

**D69** was the one worth doing first. `ERRNO[5]` — "LogicalDiscs has some other
error", whose help says *investigate this error ASAP* — was never used, so every
non-Ok virtual disk got `ERRNO[4]`, *"check back in a while to see this error
goes away"*. A failed RAID volume was described as a transient state that
resolves itself.

```diff
+	elif echo "$vdisk_state" | grep -qiE "rebuild|resync|initializ" ; then
+                printlogmess ... -e ${ERRNO[4]} ... "vdisk: $vdisk REBUILDING $VDISK_INFO"
 	else
-                printlogmess ... -e ${ERRNO[4]} ... "vdisk: $vdisk NOT OK $VDISK_INFO"
+                printlogmess ... -e ${ERRNO[5]} ... "vdisk: $vdisk NOT OK $VDISK_INFO"
```

The `rebuild|resync|initializ` pattern is **UNVERIFIED SHAPE** — neither the
script's embedded ssv sample nor the supplied Dell capture shows a rebuilding
volume, both say `Ready`. It is inferred from OMSA's documented vdisk states.
The guess is safe in the only direction that matters: anything the pattern does
not recognise now falls to `ERRNO[5]`, "investigate", rather than to "wait and
see". Even if it never matches, the fix is strictly an improvement.

**D67** — `continue` became `return 1`. `continue` inside a function is not loop
control for the caller's loop; bash rejects it and carries on, so a disk
`omreport` does not report was logged as failed **twice**, with a bash
diagnostic in the output.

**D68 is deliberately left open** at the maintainer's request: the not-found
message still interpolates `$DISK_INFO`, a global assigned further down the
function, so it carries the previous disk's name and serial. One line
(`local DISK_INFO=""`) when it is wanted.

---

# Addendum 2026-09-15 (second) — D53 fixed, and `sc_08` stops leaking temp files

```
$ ./run.sh -q
532 passed, 20 xfailed in 920.03s (0:15:20)
```

**`sc_08` now has no open defects.** D50, D51, D52 and D53 are all closed.

## D53 — two missing `return`s

Both parse guards logged an error and fell through:

```diff
     GLOBALERRMESSAGE="${GLOBALERRMESSAGE};$CRLNAME (Cant parse file,lastupdate)"
+    return 5
   fi
```

so `cmp_dates.py` was still called with two empty date strings. It raised
`ValueError`, dumped a Python traceback into the check's output, and exited 1 —
which is its code for **warn**. A CRL that could not be retrieved was therefore
reported as `CRL has past the WARN level` with an empty detail, as the third and
least severe of three messages.

The guard at line 146, `if [ "x$CRLCHECK" = "x" ]`, could never have caught it:
`CRLCHECK=$?` is always set, so that branch is unreachable regardless.

## The temp file leaked on five paths

`checkcrl` creates its download target with `mktemp` and removed it only on the
success path. Each of the five early `return`s leaked a file — and a CRL that
cannot be fetched takes one of them on **every** run, so a host with one broken
CRL URL grew `/tmp` on every cron tick.

```diff
   outname=$(mktemp)
+  trap 'rm -f "$outname"' RETURN
 ...
-  rm "$outname"
 }
```

**`RETURN`, not `EXIT`, and the distinction matters.** Bash traps are global, and
`checkcrl` is called once per configured CRL — an `EXIT` trap would only clean up
after the last one. `RETURN` scopes to the function and fires on all six exit
paths. Verified before relying on it.

Pinned by `test_the_temporary_file_is_removed_on_every_exit_path`, which counts
`/tmp/tmp.*` across a run with two failing CRLs and one good one.

---

# Addendum 2026-09-15 — `sc_31`'s lock made atomic, D65 fixed

Scoped deliberately to what is verifiable **without HP hardware**: the lockfile
protocol and the summary plumbing. Neither touches the `ilorest` parsing, which
stays on `UNVERIFIED SHAPE` fixtures.

```
$ ./run.sh -q
530 passed, 21 xfailed in 968.19s (0:16:08)
```

## The trap belongs at the top, and ownership in the lock

First cut put the `trap` after the acquire, to stop a *waiting* run from
deleting a lock it never owned. The maintainer's convention is traps at the top,
and the reasoning is sound: a trap registered late does nothing about a failure
on the way to it.

Both are satisfiable at once by making ownership a property of the lock rather
than of a flag — the acquire writes the holder's pid into it, and the trap only
removes a lock whose contents are its own pid:

```bash
trap '[ "$(cat "${LOCKFILE}" 2>/dev/null)" = "$$" ] && rm -f "${LOCKFILE}"' EXIT
until ( set -o noclobber ; echo $$ > "${LOCKFILE}" ) 2>/dev/null ; do
```

A `LOCK_HELD=0/1` flag would still leave a window between the file being created
and the flag being set. Writing the pid closes it, because the write is part of
the same atomic create.

Verified three ways: killed while waiting leaves the other run's lock intact and
unmodified; killed while holding cleans up; with no trap at all the lock leaks.
Pinned by `test_a_run_killed_while_waiting_does_not_steal_another_runs_lock`.

**Applies to `931_mysql_backup_encrypt_send_to_remote_host.sh` too**, which had
the identical defect as report item #12 and is now fixed the same way. `931` also
gained an `ENCBACK_LOCK` variable — the path had been repeated inline six times.

**Limit worth stating:** `trap` cannot catch `SIGKILL`, so a `kill -9` still
leaves a stale lock. The timeout-and-steal path remains necessary; the trap makes
it rare rather than routine.

## The lock was not atomic

`lockfilewait` tested with `[ -f ]` and then created with `touch` — two steps, so
two runs could both pass the test and both proceed. Measured with 200 concurrent
acquires:

| pattern | winners |
| --- | --- |
| `[ ! -f ] ; touch` | **6** |
| `( set -o noclobber ; : > "$LOCKFILE" )` | **1** |

`noclobber` rather than the `mkdir` normally recommended for this: `mkdir` would
change the lock from a file to a directory, and a lock left behind by the *old*
version is a regular file that `rmdir` cannot remove — the stale path would spin
forever on an upgraded host. `noclobber` is equally atomic and keeps the lock a
file, so `stat`, `rm` and any pre-existing stale lock all keep working.

A `trap 'rm -f "${LOCKFILE}"' EXIT` was added at acquisition. There is no `exit`
between acquire and release, so the only way to leak a lock was a crash — which
is what made the stale path routine rather than exceptional.

## D65 needed two changes, not one

`WARNSTATUS` was never incremented, so the WARNING summary and `ERRNO[6]` were
dead. Setting it in `lockfilewait` alone would **not** have worked:

```
155  lockfilewait ${LOCKFILE}     <- the stale-lock WARN happens here
160  WARNSTATUS=0                 <- reset it immediately afterwards
```

The `ERRSTATUS`/`WARNSTATUS`/`GLOBALERRMESSAGE` initialisation had to move above
the call as well. Easy to miss by reading the defect rather than the ordering.

## Left alone on purpose

**D64** — making the `HPTEMP` filter work is the most dangerous change available
here. It currently selects nothing, so every sensor is checked. Enable it while
`TEMPNO` is empty (D63) and the match runs against a bare space; the likely
result is every sensor filtered out and the check reporting all-clear having
examined nothing. That is precisely the failure mode `sc_43` was deleted for.

**D63** — any value for `TEMPNO` is a guess. The shipped
`HPTEMP="#1 #2 #5 #8 ..."` is a sparse list of real sensor numbers, so a
sequential counter would be wrong.

Both stay logged until an iLO is available to capture from. A blank sensor
number in a message is cosmetic; a silently blind check is not.

---

# Addendum 2026-09-14 (fourth) — D66 fixed in the shared library

```
$ ./run.sh -q
528 passed, 22 xfailed in 1038.01s (0:17:18)
```

Zero failures, no xpasses. D56, D57 and D66 moved from strict xfail to passing;
the test count is unchanged at 550, so nothing was dropped to get there.

**The highest-blast-radius fix of the session.** `lib/printlogmess.sh` is what
every one of the 32 `sc_` scripts and 42 `related` scripts logs through, feeding
all four sinks plus the JSON payload pushed to Icinga/OP5.

It built the message correctly and then emitted it with the *message itself* as
a printf format string:

```diff
-            printf "${NEWFMTSTRING}\n" >&2
+            printf '%s\n' "${NEWFMTSTRING}" >&2
```

**14 emit sites** across screen, file, syslog, `last_status` and logbook, for
`NEWFMTSTRING`, `OLDFMTSTRING`, `JSONSTRING` and `LOGBOOK_JSONSTRING`.

Lines 193 and 326 are deliberately **unchanged**:

```bash
DESCR_W_ARGS=$(printf "${LONGLEVEL} - ${SCRIPTNAME} ${DESCR}\n" "$ARG1" ... )
```

That one is correct — `$DESCR` genuinely *is* a format and its `%s` must expand.
The bug was the second pass, by which point the arguments were already
substituted, so any `%` arriving from caller data got reinterpreted:

```
before: ... in normal operation 20 0s OK
after:  ... in normal operation 20% is OK
```

`JSONSTRING` mattered most of the four: it embeds `${NEWFMTSTRING}` as
`LEGACYFMT`, so a mangled message was corrupting the monitoring payload too.

## `sc_33`'s workaround had to go with it

`sc_33_healthchecker.sh` pre-escaped `%` to `%%` precisely to survive the old
behaviour. Left in place it would now print a literal `%%`:

```diff
-    FIXED_FULL_STATUS=$(echo "${FULLSTATUS}" | tr -d '\\' | tr -d "'" | sed 's/%/%%/gi' | tr '\n' ';' | tr -d '"')
+    FIXED_FULL_STATUS=$(echo "${FULLSTATUS}" | tr -d '\\' | tr -d "'" | tr '\n' ';' | tr -d '"')
```

Checked before changing: `sc_33` was the **only** caller escaping, and no
`lang/*` file contains `%%`, so nothing else depended on the old behaviour.

## Verification

The four suites with the most exposure to the library — `test_shared_library.py`
(the output formats across all four sinks), `test_monitoring_integration.py`
(JSON validity and hostile content in a message argument), `test_logbook.py` and
`test_sc_33_healthchecker.py` — were run first: **93 passed, 3 xfailed**, the
three being `sc_31`'s unrelated D63/D64/D65.

`test_sc_31_hp_health.py::test_a_fan_percentage_survives_into_the_message` was
the strict xfail pinning this defect; its marker is removed.

## A flaky test fixed alongside

`test_a_stale_lockfile_is_waited_out_then_removed_with_a_warning` failed once
under full-suite load and passed 3/3 in isolation. The cause was in the test,
not the script: it touched the lockfile and asserted the run took at least
`LOCKFILE_MAX_WAIT_SEC`, but under load the gap between that `touch` and the
script's `stat` can exceed the window, leaving nothing to wait for. Split into a
behavioural test (warning emitted, lock removed — no timing) and a timing test
with a 10s window wide enough to absorb container overhead. Stable 3/3 since.

---

# Addendum 2026-09-14 (third) — `sc_28` fixed

**D56 and D57 are fixed.** `sc_28_check_vip.sh` was the most broken check left
in the tree: between them the two defects left it with exactly one possible
outcome — "None of the nodes has the VIP" — regardless of where the VIP actually
sat, so it paged on every cron tick against a healthy cluster.

Two lines:

```diff
-CHECK_VIP_NODE1=$(... /915_remote_command_via_ssh.sh ${HOSTNAME_NODE1} "${IFCONFIG} | grep ${HOSTNAME_VIRTUAL}" ${SSH_USER} ${SSH_KEY} | ...)
+CHECK_VIP_NODE1=$(... /915_remote_command_via_ssh.sh --host="${HOSTNAME_NODE1}" --command="${IFCONFIG} | grep ${HOSTNAME_VIRTUAL}" --user="${SSH_USER}" --key="${SSH_KEY}" | ...)
```

```diff
-if [ ! "$NODE1" = "${HOSTNAME_VIRTUAL}" -a ! "$CHECK_VIP_NODE2" = "${HOSTNAME_VIRTUAL}" ] ; then
+if [ ! "$CHECK_VIP_NODE1" = "${HOSTNAME_VIRTUAL}" -a ! "$CHECK_VIP_NODE2" = "${HOSTNAME_VIRTUAL}" ] ; then
```

The `$NODE1` fix needed no restructuring: with the right variable, the existing
`if/elif/elif` plus the trailing guard cover all four states correctly — node 1,
node 2, both, neither — each with exactly one message.

**The suite is now 12 tests with no xfails**, and three of them had to be
rewritten because they pinned the broken behaviour rather than the intended one:

* `test_node_one_holding_the_vip_currently_raises_a_false_error` asserted
  `["281", "284"]` — the contradiction itself. Now
  `test_the_vip_on_node_one_does_not_also_raise_the_nobody_error`, asserting
  one message.
* `test_only_node_two_gets_a_correct_verdict` asserted the asymmetry (node 2
  gives one message, node 1 gives two). Now `test_both_nodes_get_the_same_treatment`.
* `test_the_shipped_check_can_only_ever_report_that_nobody_has_the_vip` asserted
  the single-outcome behaviour end to end. Now
  `test_the_check_asks_the_real_helper_with_named_options`.

The suite's **stub `915` also had to change**: it matched on `$1`, which only
worked because `sc_28` was calling positionally. It now matches on `--host=`,
so the stub would not answer a positional call either — the same contract the
real helper enforces.

Worth noting for the `related-available` work: `915` itself is unchanged. D56
was entirely `sc_28` calling it wrongly, and `930` had the identical defect
against `906` (report item #11), fixed separately.

---

# Addendum 2026-09-14 (second) — Phase 3 complete

Five suites, 92 tests, **nine new defects (D62-D70)**. **Phase 3 is complete**,
and with it every `sc_` script in the tree has a suite.

```
$ ./run.sh -q
525 passed, 25 xfailed in 932.12s (0:15:32)
```

550 tests covering 32 of 32 `sc_` scripts — all 3127 lines. Only the 43
`related` scripts of Phase 4 remain uncovered.

**`test_sc_36_dell_health.py` — 22 tests, no xfails.** The first Phase 3 suite,
and the first one written from a capture the maintainer supplied rather than
from invented output.

## Fixture provenance is the interesting part

`sc_36` reads Dell OMSA through `omreport`, faked as a binary on `PATH` that
records its argv and replays captured output per subcommand. Two sources feed
the fixtures, and they do not fully agree:

* [`sc_36_dell_health_sample_output.txt`](sc_36_dell_health_sample_output.txt) —
  real `omreport` output in its **default human-readable** format. Authority for
  *values*: statuses, readings, probe names, thresholds.
* the `#`-comments inside `sc_36_dell_health.sh` — real **`-fmt ssv`** captures
  including column headers. Authority for *column order*, because `-fmt ssv` is
  what every call actually passes and `cut -f N -d\;` is how the result is read.

For temperatures, PSUs and power monitoring the two agree field for field, so
those fixtures are well grounded. Checked explicitly: `cut -f6` on a temperature
row is the Maximum *Warning* Threshold (42.0 C), not the failure threshold
(47.0 C), and `cut -f6` on a PSU row is Maximum Output Wattage, the column after
Rated Input.

## The one thing left unresolved

The two captures disagree about fans:

```
ssv header (in the script)   Index;Status;Probe Name;Reading;...
                             0;Ok;System Board Fan2A;7200 RPM;...

human-readable (the sample)  Index : 0 / Status : Ok
                             Reading : 5400 RPM / Location : Fan 1
```

`Reading` sits *after* the name in one and *before* it in the other. The
fixtures follow the ssv header, since that is the format the script parses — but
if the human-readable order is also the ssv order, then `cut -f3`/`cut -f4` are
swapped and every fan message names a speed where the name should be.

Not filed as a defect, because the evidence points both ways and the script's
own captured ssv header is the better authority for the format it actually
requests. What it *would* look like is verified: swapping the fixture columns
produces

```
Fan id: 0 status: Ok name: 5400 RPM rpm: Fan 1
```

and the suite's column-order test fails, so the assertion is load-bearing rather
than incidentally true. **One real `omreport chassis fans index=0 -fmt ssv`
settles it.**

## Two limitations pinned, neither filed as a defect

* **A failing `omreport` is indistinguishable from an unhealthy component.** The
  script only ever looks at the parsed status field, so a tool that exits
  non-zero and prints nothing yields an empty status, which is "not Ok". The
  verdict is defensible; the diagnosis is not, because the message blames the
  component.
* **`config/36.conf` defines `CPU[0]`** under a `# check cpus with omreport
  chassis processors` comment, but the script has no processor check and never
  reads `CPU[]`. An operator adding CPUs to that list gets no coverage and no
  warning. PLAN.md's Phase 3 row said "fans, temps, CPU, PSU" — the CPU half
  does not exist, and the row is corrected.

## `sc_06` and `sc_31` — basic suites, and five more defects

No HP hardware is available, so `ssacli` and `ilorest` output cannot be
captured. Both suites are deliberately **basic**, with fixtures marked
`UNVERIFIED SHAPE` — reconstructed from what each script's parsing requires
rather than from a real device. They prove branching, indexing and summary
behaviour, not that the vendor tools emit that layout.

| File | Tests | Covers |
| --- | --- | --- |
| `test_sc_06_raid_check.py` | 14 (1 strict xfail) | `sc_06` |
| `test_sc_31_hp_health.py` | 16 (4 strict xfail) | `sc_31` |

Everything below is a **logic** error rather than a parsing assumption, so it
holds whatever the real tools print.

### D62 — `sc_06`'s rebuilding branch can never be taken

`ERRNO[4]`/`DESCR[4]` exist for a logical drive that is rebuilding — a state
that resolves itself, whose help text says to check back later. The guard is

```bash
elif [ "xRebuilding" = "x$COMMAND" ]
```

but `$COMMAND` is the entire line `grep` matched, e.g.
`logicaldrive 1 (558.9 GB, RAID 1, Rebuilding)`. It can only equal the bare word
if `ssacli` prints nothing else on that line, which it never does — any line
containing the word also contains the drive identifier the `grep` matched on.

So a rebuilding array is reported as `065` "LogicalDiscs has some other error",
whose help says *"you need to investigate this error ASAP"*. An operator is
paged for a routine rebuild.

### D63 — `sc_31`'s temperature messages name a blank sensor 🔧 WONT FIX 2026-09-18

`TEMPNO` appears six times — in five messages and in the `HPTEMP` filter — and
is assigned nowhere. `grep -n TEMPNO sc_31_hp_health.sh` returns only uses. Every
temperature line reads `TEMP  Ambient Current: 21 ...`, with a doubled space
where the identifier belongs. A temperature alert that cannot name its sensor
sends whoever reads it through every probe on the chassis.

**Closed as WONT FIX at the maintainer's direction, 2026-09-18.** No HP hardware
is available to capture real `hpasmcli` output from, so any value chosen for
`TEMPNO` would be a guess at a format nobody here can check — and guessing wrong
in a temperature check means either silence or false alarms on real hardware.
The standing instruction for `hp*` scripts has been to log what is found and
move on.

The strict xfail in `test_sc_31_hp_health.py` stays. It is not waiting for a
fix: it pins the current behaviour so that anyone who does change this, with
real hardware to verify against, is told immediately that the behaviour moved.

### D64 — `sc_31`'s configured sensor list selects nothing 🔧 WONT FIX 2026-09-18

`HPTEMP` is documented as the list of sensors to watch and the shipped config
names 21 of them. Its only appearance is

```bash
echo ${HPTEMP}|egrep -q "${TEMPNO} "
```

on a line of its own. The exit status is never tested — no `if`, no `&&` — so
the result is discarded and every sensor `ilorest` reports is checked regardless
of the setting. With `TEMPNO` empty (D63) the pattern is a bare space anyway.

**Closed as WONT FIX at the maintainer's direction, 2026-09-18**, with D63.
Making the filter work is the more dangerous of the two changes: it would start
*excluding* sensors, and with no HP hardware to verify the match against, a
wrong pattern silently stops watching probes that are currently watched. Leaving
it inert means everything is checked, which fails safe.

Its strict xfail stays for the same reason as D63's — pinning the behaviour, not
waiting on it.

### D65 — `sc_31`'s WARNING summary is unreachable ✅ FIXED 2026-09-15

`ERRSTATUS` and `WARNSTATUS` decide the summary. `ERRSTATUS=1` is set on every
failure path, but **nothing assigns `WARNSTATUS`** — initialised to 0 at line
160 and never touched — so the `elif` guarding the WARNING summary can never be
taken and `ERRNO[6]` is dead code.

The stale-lockfile notice is the case that should reach it: reported at WARN via
`ERRNO[5]`, and an otherwise healthy run that had to clear a stale lock is
exactly "not an error, but not nothing". Instead it summarises as fully OK.

`GLOBALERRMESSAGE` has the mirror problem: declared, passed to both summary
branches, never appended to, so the error summary's detail is always empty.

### D66 — a `%` in any message argument is eaten by the shared library ✅ FIXED 2026-09-14

Found through `sc_31` but **not a `sc_31` defect**. `lib/printlogmess.sh`
assembles the message and then emits it with

```bash
printf "${NEWFMTSTRING}\n"
```

using the assembled message as the printf *format*. A `%` that reached it from a
message argument is reinterpreted as a conversion specifier, so `sc_31`'s fan
line `... in normal operation 20% is OK` prints as `... 20 0s OK` — the
percentage destroyed and the following text with it. Confirmed directly:

```
$ NEWFMT="INFO - hp_health Sensor of FAN is OK in normal operation 20% is OK"
$ printf "${NEWFMT}\n"
INFO - hp_health Sensor of FAN is OK in normal operation 20 0s OK
```

`printf '%s\n' "$msg"` would be immune. `sc_33` works around it per-caller by
escaping `%` to `%%` before calling `printlogmess`; nothing else does, and no
caller should have to. Any script putting a percentage in a message argument is
affected — worth fixing in the library rather than in each script.

## What the two suites do cover well

`sc_31`'s lockfile protocol needs no fixture and is genuinely verified: the lock
is taken and released, a stale lock is waited out, reported via `ERRNO[5]` and
removed, and the wait is bounded by `LOCKFILE_MAX_WAIT_SEC`. Worth noting the
age is read with `stat --format=%Z` — ctime, not mtime — so a lock cannot be
aged with `touch -d`, and the clock runs from the last inode change. For a lock
left by a killed process that is its creation time, which is the intent.

`sc_06`'s summary correctly resets `SCRIPTINDEX` to `00`, avoiding D50.

**Still unverified in both:** all of the parsing. `sc_31`'s `hppsu` in
particular flattens the whole power section into one string and reads fixed
offsets 1-6, hard-assuming three PSUs in Health-then-State order; a capture of
`ilorest serverinfo --power` from a two-PSU chassis would likely produce a sixth
defect.

## `sc_35` — the best-grounded suite of the phase

`sc_35` carries **real `-fmt ssv` captures in its own comments**, including the
42-column pdisk header and a full data row, so the column indices it `cut`s are
pinned against genuine output rather than a guess. It reuses the fake
`omreport` written for `sc_36`. **17 tests, 3 strict xfails.**

### D67 — `continue` inside a function does not continue the caller's loop ✅ FIXED 2026-09-15

`raiddiskcheck` ends its not-found branch with `continue`. Bash rejects that:

```
continue: only meaningful in a `for', `while', or `until' loop
```

and execution **carries on** rather than returning. It falls into the `cut`
block with an empty `$DISCSTAT`, so `STATUS` is empty, which is not `Ok`, and
the same disk is reported as not-OK a second time. One absent disk produces two
error messages at the same index plus a bash diagnostic in the check's output.
`return` is what was meant. Confirmed against bash 5.2.37 directly.

### D68 — the not-found message describes the previous disk

That first message interpolates `$DISK_INFO`, which is assigned further down the
same function. It is a plain global with no `local`, so on the first disk it is
empty and on every later one it still holds the previous disk's name, state,
capacity and serial. A message about a missing disk carries a healthy disk's
serial number. Same class as D51 in `sc_08`.

### D69 — a failed RAID volume is reported as rebuilding ✅ FIXED 2026-09-15

`lang/35.english` defines three outcomes for a virtual disk: OK, rebuilding
("check back in a while"), and some other error ("investigate ASAP").
`raidlogiccheck` only ever uses the first two. Every non-Ok virtual disk —
Failed, Degraded, Offline — is reported as **rebuilding**, and the help text
tells the operator to wait for it to clear. `ERRNO[5]` is dead code.

This is the exact mirror of D62 in `sc_06`, where the rebuilding branch was the
unreachable one and everything became "some other error". Here a genuinely
failed volume is described as a transient state, which is the more dangerous
direction of the two.

## `sc_39` — real Luna fixtures, and one command still unknown

Fixtures come from the supplied Luna 7 capture, so field names, value formats
and the `Command Result : No Error` trailer are genuine. The suite drives all
six checks across OK, warning and error thresholds. **23 tests, 1 strict
xfail.**

Worth noting what the capture already validated: `parse_voltage` and
`parse_temperature` accept the real unit suffixes (`3.093 V` → `3.093`,
`64 deg. C` → `64`), `Partition Status -> L3 Device` is an arrow field matching
the literal compared against, and the session guard's `Command Result` counting
works against real output.

### D70 — the real `slot set` answer breaks the session guard

`slot set` answers, verbatim from the capture:

```
Current Slot Id: 1 (Luna User Slot 7.0.1 (PW) Signing With Cloning Mode)
```

`extract_colon_field ... "Current Slot Id"` returns the whole tail, parenthetical
included, and the guard compares it against a bare slot number. That can never
match, so both sessions fail with "LunaCM did not select application partition
slot" and every check reports the session error instead of the HSM's state.

**Every other test in the suite only passes because the fixture has `slot list`
emit a second, bare `Current Slot Id:` line** — the extractor keeps the last
match, so that one wins. `slot list` output is not in the capture, so whether a
real Luna emits it is unknown.

Filed as a defect but flagged as conditional: if a real `lunacm slot list` does
emit a bare line, `sc_39` works and the xfail should be deleted. If it does not,
`sc_39` cannot complete a session at all. **One capture of `lunacm slot list`
settles it**, and it is the only capture still worth having in Phase 3.

## Reusable

The fake `omreport` dispatches on subcommand and replays a per-subcommand
fixture file, so **`sc_35` can reuse it directly** — same binary, different
subcommands (`storage pdisk`, `storage vdisk`). The supplied capture also
contains `storage pdisk` and `storage vdisk` output, so `sc_35` is the natural
next one.

---

# Addendum 2026-09-14 — `sc_33`, `sc_37` and `sc_08` fixed, `sc_43` deleted

Several maintainer decisions, acted on together.

## `sc_43_rittal_rack_sensors.sh` deleted

The Rittal rack-sensor check is gone, following the precedent of the five
scripts removed on 2026-09-12. Deleted with it:

* `config/43.conf`, `lang/43.english`
* its `test/test-scripts.bats` case
* `test/containers/test_sc_43_rittal_rack_sensors.py` (12 tests)
* the `start_snmp_agent` harness helper and the `SnmpAgent` class
* the `snmpsim`, `pysmi` and `python3-pip` layers from `Dockerfile.syscheck`,
  and the `snmp` package — `sc_43` was the only caller of `snmpwalk` anywhere
  in the tree, so nothing else needed an SNMP stack

There was no ansible template for 43 and no entry in `docs/syscheck-scripts.md`,
so nothing else referenced it. **D58, D59, D60 and D61 are moot**: they had no
code left to affect. The one commented-out line in
`test/test-syscheck-console.bats` that mentions "43" is about redis and was
already mislabelled; it is untouched.

This removes the only SNMP check in the tree. Anyone who later wants rack
monitoring back should start from the defect record below rather than from the
deleted script — it never worked, so there is no working behaviour to restore.

For the record, since the code is gone: `sc_43` wrote its walk to
`/tmp/${HOST}.txt` and graded `/tmp/snmp.txt` (D58); its reachability test
`if [ $? != 1 ]` reported "Can't connect" when `snmpwalk` *succeeded* (D59); its
`awk '{print $9}'` and the config's `enterprises.` OID prefix matched neither
the field count nor the naming of real `snmpwalk` output (D60); and
`NO_OF_ERR=2` left the healthy branch printing `DESCR[2]`, "Wrong value in
Rittal" (D61). Compounded, an unreachable rack was reported as seven healthy
sensors.

## `sc_33_healthchecker.sh` — D43 through D47 fixed

All five defects are fixed and the suite passes with **no xfails**: 29 tests,
up from 25, the four new ones covering the identity flags that the option fix
also repaired.

Across the whole suite, after both changes:

```
$ ./run.sh -q
442 passed, 16 xfailed in 753.89s (0:12:33)
```

458 tests, down from 465: minus `sc_43`'s 12, plus the tests added for the
option flags and the `sc_37` cleanup paths. **Fifteen strict xfails became
passes** — `sc_33`'s D43–D47, `sc_37`'s D48 and D49, `sc_08`'s D50–D52, and the
four that went with the deleted `sc_43`. No xpasses, so nothing regressed and
every remaining defect is still reproducible.

| Defect | Fix |
| --- | --- |
| D43 | `--options "hsvcinf"` → `"hsvainf"`; added a `* )` catch-all that exits 1; added `exit 1` after the `schelp` that runs when getopt rejects an argument |
| D44 | `-gt` → `-ge` when comparing `restartsin24h` against `MAXRESTARTS` |
| D45 | `lang/33.english` `DESCR[1]` gained a second placeholder: `"app: %s ok (%s)"` |
| D46 | the wget branch gained `-O -` on both fetches |
| D47 | the unknown-`CHECKTOOL` branch gained `continue`, and now names the app in its message |

### D43 — the option loop

The `--options` string listed `c`, which no case arm handled, so `-c` matched
nothing, shifted nothing, and spun forever. It did *not* list `a`, which a case
arm did handle, so `-a` was rejected by getopt and fell through to the same
spin. Both are fixed by correcting the string to `"hsvainf"` — the set the case
arms actually implement — and the `* )` arm now catches anything that still
slips through, matching what `default_script_getopt` grew when D1 was fixed.

Separately, `if [ $? != 0 ] ; then schelp ; fi` had no `exit`, so an invalid
option printed the help text and then **ran the checks and restarted services**.
That now exits 1.

`-a` working again is a side effect worth noting: it had been broken for as long
as the options string has been wrong, silently, because the failure mode was a
hang rather than an error.

### D46 — the wget branch

`STATUS=$(wget "$URL" -T "$TIMEOUT" -t 1 2>/dev/null)` without `-O -` writes the
body to a file named after the URL path and prints nothing to stdout. `STATUS`
was therefore always empty, never equalled `ALLOK`, and every healthy
application was reported down — and, because that is the branch that restarts,
bounced on every cron tick. With `-O -` the body reaches stdout and the wget
path now reaches the same verdict as curl, which the suite asserts directly.

### D47 — and the shape it shares with D42

The unknown-`CHECKTOOL` branch reported the error and fell through to
`[[ $STATUS == ALLOK ]]` with `STATUS` never assigned, took the failure arm, and
restarted the service. A typo in one config value bounced every configured
application. It now `continue`s.

This is the same report-and-continue shape as **D42 in `sc_02`** and the
unnumbered one in **`sc_37`**, both still open. `sc_33` was the dangerous
instance because its continuation has side effects; the other two only produce a
spurious second message. Worth fixing together the next time those two are
touched.

## `sc_37_monitor_jnlp.sh` — D48 and D49 fixed

`HEADER` is now a bash array rather than a string containing escaped quotes:

```diff
-HEADER="--header \"Host: public.domain.com\""
+HEADER=(--header "Host: public.domain.com")
```

```diff
-${CHECKTOOL} ${URL} ${HEADER} --max-time ${CURL_TIMEOUT} --retry 1 --output $OUTPUT -v 2>/dev/null
+${CHECKTOOL} "${URL}" "${HEADER[@]}" --max-time ${CURL_TIMEOUT} --retry 1 --output $OUTPUT 2>/dev/null
```

Quoting at the *use* site could not have fixed this. Expansion results are not
re-parsed for quoting, so the `\"` in the config survived as a literal
character no matter how the variable was referenced: unquoted it split into
three words, quoted it would have become one malformed header. The value had to
stop being a string that needs re-parsing.

Measured against a mock that echoes back the header it received:

| form | server saw |
| --- | --- |
| before | `Host: httpd-c5f413a4:8080` — the default vhost |
| after | `Host: public.domain.com` |

curl had been reporting `curl: (3) URL rejected: Bad hostname` on every single
run, for the stray `public.domain.com"` word it read as a second URL. The
script's `2>/dev/null` discarded it, which is why this lasted. The fetch still
exited 0 because the first URL succeeded.

Two properties of the array form worth keeping in mind, both verified:

* **`HEADER=()` expands to nothing**, not to an empty argument. The obvious
  alternative — two scalars, `${ARG1} "${ARG2}"`, which is what `sc_08` does —
  is exactly **D52**: the quoted empty scalar becomes a literal blank argument
  and curl aborts with `option : blank argument where content is expected`
  before making any request. `sc_08` should get the same array treatment, as
  its own change.
* **An unmigrated config fails loudly.** A leftover scalar read as
  `"${HEADER[@]}"` becomes a single argument and curl exits 2 with
  `option --header "Host: ...": is unknown`. Since the defect being fixed is
  *silently monitoring the wrong vhost*, a silent migration would have been
  worse than the bug. Pinned by
  `test_a_legacy_string_header_fails_loudly_rather_than_silently`.

The discarded `-v` went with the fix: its output was redirected to `/dev/null`,
so it only ever made the suppressed stderr larger.

### D49 — the stale response file

`/tmp/internal-error.txt` was only removed at the *end* of a run, and a curl
that never connects writes nothing — so a leftover file decided the verdict.
Seeded with a valid JNLP and pointed at a host that does not resolve, the check
reported OK for a server it could not reach.

```diff
 OUTPUT="/tmp/internal-error.txt"

+rm -f "$OUTPUT"
+trap 'rm -f "$OUTPUT"' EXIT
+
 if [ "x${CHECKTOOL}" = "xcurl" ] ; then
```

and the trailing `rm $OUTPUT` is gone — the trap owns cleanup now, and that
`rm` had no `-f`, so it also errored whenever the file was already absent.

The `rm -f` before the fetch is what closes the defect: no leftover can reach
the grading step. The trap is the belt-and-braces half — it guarantees the file
does not outlive the run on any exit path, including a signal.

Worth recording honestly, because the obvious test for it is a trap: `curl
--output` does not create the file until the first byte of the response
arrives. A run killed while curl is still waiting therefore has no file to clean
up, and an end-to-end "killed mid-fetch" test passes whether or not the trap
exists. The suite asserts the trap's presence in the source instead, with that
reasoning written down. (Bash does run an EXIT trap when killed by TERM —
verified separately with a seeded file.)

So the trap currently defends paths that do not exist yet: the `CHECKTOOL`
guard will gain an early exit when the D42-class defect is fixed.

**The underlying weakness is untouched.** `/tmp/internal-error.txt` is still a
fixed, predictable path in a world-writable directory, so an unprivileged local
user can still win the race between the `rm -f` and curl's create, e.g. by
planting a symlink. `mktemp`, which `sc_08` already uses, would close that; it
is a larger change than this one and belongs on its own.

`sc_37`'s suite is now 20 tests, 1 xfail — only the D42-class
report-and-continue is left.

**Not part of this change:** suppressing curl's stderr is what hid D48 for as
long as it lasted. Capturing it and reporting it on the failure path would be a
real improvement, but it changes what `DESCR[2]` carries and needs its own test
updates.

## `sc_08_crl_from_webserver.sh` — D50, D51 and D52 fixed

Three fixes, two of them the maintainer's and one mine.

**D50** — `export SCRIPTINDEX="00"` before the summary, so it stops being pushed
to the same monitoring service as the last CRL's verdict. `sc_10` always did
this; `sc_08` now matches.

**D51** — `local` declarations for the per-CRL settings, so each `checkcrl` call
starts clean instead of inheriting the previous entry's thresholds and `Host:`
header.

**D52** — the two header scalars became one array, the same shape as `sc_37`:

```diff
-    CHECK_HOST_ARG1="--header"
-    CHECK_HOST_ARG2="Host: ${HOSTNAME_FROM_URL}"
+    CHECK_HOST_ARG=(--header "Host: ${HOSTNAME_FROM_URL}")
```

```diff
-${CHECKTOOL} ${CRLNAME} --retry ${RETRIES} ${CHECK_HOST_ARG1} "${CHECK_HOST_ARG2}" ...
+${CHECKTOOL} ${CRLNAME} --retry ${RETRIES} "${CHECK_HOST_ARG[@]}" ...
```

An empty array expands to nothing; a quoted empty scalar expands to a blank
argument, which is what made curl abort before sending anything. The bare-URL
config — no `CRL_HOST_IP` at all — now works, where before it could not fetch a
single CRL.

### A regression the suite caught on the way

The D51 fix initialised the thresholds to `0` rather than empty:

```bash
local ARGWARNMIN=0
local ARGERRMIN=0
```

`ARGWARNMIN` is expanded unquoted into the `cmp_dates.py` command line, so on
the "default thresholds" path — `MINUTES[i]` and `ERRMIN[i]` unset, which is
what the setting is *for* — argparse received two extra positionals:

```
error: unrecognized arguments: 0 0
```

and exited 2. `sc_08` reads 2 as `ERRNO[7]`, so **a perfectly fresh CRL on
default thresholds was reported as "CRL has past the ERROR level"**, with a
Python usage dump in the check's output. Verified by putting the `0` back and
re-running: `assert '087' == '082'`.

Changed to `=""`, which keeps the `local` scoping the fix was for while
restoring the empty default the expansion relies on.

`sc_08`'s suite is now 25 tests, 1 xfail — only D53 is left.

### What this leaves

`sc_33` has no open defects; `sc_37` and `sc_08` have one each. The remaining
strict xfails belong to `sc_02` (D41, D42), `sc_08` (D53), `sc_10` (D54, D55),
`sc_12` (D40), `sc_28` (D56, D57), `sc_37` (the D42-class one), `sc_38` (D36,
D37), `sc_40` (D38, D39) and `test_packaging.py`'s `--help` formatting guard.

**`sc_28` is the most valuable one left.** D56 and D57 together leave it with
exactly one possible outcome — "None of the nodes has the VIP" — regardless of
where the VIP actually is, so it pages on every cron tick against a healthy
cluster. Both fixes are small: call `915` with `--host`/`--command`/`--user`/
`--key` instead of positionally, and test `$CHECK_VIP_NODE1` instead of the
never-assigned `$NODE1`.

---

# Addendum 2026-09-13 (second) — Phase 2 closed

The last three Phase 2 scripts — **`sc_10` (OCSP), `sc_28` (VIP) and `sc_43`
(Rittal rack sensors)** — now have suites. **Phase 2 is complete: 14 of 14.**

| File | Tests | Strategy | Covers |
| --- | --- | --- | --- |
| `test_sc_10_ocsp.py` | 18 (2 strict xfail) | REAL-SVC `openssl ocsp` responder + real CA | `sc_10` |
| `test_sc_28_check_vip.py` | 12 (2 strict xfail) | FAKE-BIN stub for `related/915` | `sc_28` |
| `test_sc_43_rittal_rack_sensors.py` | 12 (4 strict xfail) | REAL-SVC snmpsim | `sc_43` |

42 more tests and **8 more defects, D54–D61**. The suite now stands at

```
$ ./run.sh -q
434 passed, 31 xfailed in 712.56s (0:11:52)
```

465 tests covering 28 of 33 `sc_` scripts — 2244 of their 3216 lines. All 31
xfails are strict and none of them xpassed, so every defect below is a
reproduction rather than a reading.

## Harness and image changes

* **`start_ocsp_responder`** — builds a throwaway CA (`OCSP_PKI_SH`), issues a
  good certificate, a revoked one, an OCSP-signing certificate and a leaf from
  an unrelated CA, then runs a real `openssl ocsp` responder in its own
  container. Its own container rather than the syscheck one, because the
  per-test `reset()` kills stray processes and would take the responder with it.
  Revocation is genuine — recorded in the CA database with `openssl ca -revoke`.
* **`start_snmp_agent`** — snmpsim serving a `.snmprec` file. net-snmp's `snmpd`
  cannot serve an arbitrary enterprise subtree without a `pass_persist` handler,
  and `sc_43` walks `1.3.6.1.4.1.2606`. The image gained `python3-pip`, `snmpsim`
  and `pysmi` (snmpsim 1.2.2 imports pysmi but does not depend on it); snmpsim
  refuses to run as root, so it drops to `nobody`.
* **`sc_28` needs no ssh server.** It delegates every remote call to
  `related/915`, so the seam is that call, not the transport. A stub 915 that
  records its argv and prints a chosen `ifconfig` line covers `sc_28`'s whole
  contract. 915's own ssh behaviour belongs to Phase 4.

## The defects

### D54 — `config/10.conf` documents an interface `sc_10` does not have

The shipped config's commented example is `OCSP_CONNECT_URL[]`, `OCSP_CERT[]`,
`OCSP_EXPECTED_STATUS[]`, `OCSP_ISSUER[]`, `OCSP_CACHAIN[]`, `OCSP_HOST_NAME[]`.
The script reads **none** of those. It iterates `OCSP_TEST[]` — a *directory* —
and `OCSP_URL[]`, and takes the certificate, issuer, chain and expected status
from filenames inside that directory:

```
test_<name>_cert_<expected-status>.pem
test_<name>_issuer.pem
test_<name>_cacerts.pem
```

An operator who uncomments and fills in the shipped example configures a check
that iterates zero times (`${#OCSP_TEST[@]}` is 0) and then reports `OCSP
Summary OK`. The responder is never contacted and the check is green — the
failure mode that is indistinguishable from a healthy system.

### D55 — `sc_10` reports a missing certificate as an ERROR and then summarises OK

The three `! -f` guards in `checkocsp` each print an ERROR and `return 1`, but
none increments `ERRSTATUS` — which is what the summary is computed from. A run
against an empty test directory ends:

```
10-01-E-101 ... Can NOT find OCSP_CERT /tmp/ocsp-tests/test_*_cert*
10-00-I-109 ... OCSP Summary OK
```

The summary contradicts the line above it, and (unlike D50) `sc_10`'s summary
*does* get its own index `00`, so it is a separate monitoring service — one that
stays green while the check queries nothing.

`sc_10` is otherwise the best-behaved script of this batch: it resets
`SCRIPTINDEX` to `00` before the summary, which is exactly what D50 says `sc_08`
should do. The fix for D50 is already written down in the tree.

### D56 — `sc_28` calls `915` with positional arguments it does not accept ✅ FIXED 2026-09-14

`sc_28` invokes the helper as

```
915_remote_command_via_ssh.sh $HOST "$CMD" $USER $KEY
```

but `915` parses its arguments with `getopt` and reads only `--host`,
`--command`, `--user` and `--key` — as its own `HELP` string documents. The four
positional arguments land after `--`, the option loop breaks immediately, and
`SSHHOST` is empty, so `915` gives up before running ssh.

Nothing surfaces. `915` does report "Host not found", but through
`printlogmess`, which without `--screen` writes to syslog and `last_status`
rather than stdout — and stdout is all `sc_28` captures. So `sc_28` reads an
empty string from both nodes on every run, with no indication why. Confirmed
directly: called with named options the helper reaches ssh and says
`Could not resolve hostname`; called positionally it emits nothing at all.

### D57 — `sc_28` tests `$NODE1`, a variable that is never assigned ✅ FIXED 2026-09-14

```
if [ ! "$NODE1" = "${HOSTNAME_VIRTUAL}" -a ! "$CHECK_VIP_NODE2" = ... ]
```

The variable holding node 1's answer is `$CHECK_VIP_NODE1`. `$NODE1` is empty on
every run, so the first half is always true and "none of the nodes has the VIP"
is decided by node 2 alone. When node 1 holds the address the check emits both

```
28-01-I-281 ... Node 1 has the VIP
28-02-E-284 ... None of the nodes has the VIP
```

in the same run, and the ERROR is the one that pages. A cluster sitting
healthily on its primary node raises a critical alert on every cron tick. Node 2
is unaffected, which is why this can survive a long time: it only misfires for
half the cluster.

**Together D56 and D57 leave the shipped check with exactly one possible
outcome**, whatever the cluster is doing: "None of the nodes has the VIP". Pinned
end to end in `test_the_shipped_check_can_only_ever_report_that_nobody_has_the_vip`.

### ~~D58–D61 — `sc_43` cannot work, for four independent reasons~~ 🗑 MOOT, script deleted 2026-09-14

* **D58** — `Sub_Get_Snmp_Info` writes the walk to `/tmp/${HOST}.txt`;
  `Sub_Check_Rittal` grades `/tmp/snmp.txt`. Nothing in the tree ever creates
  the second path, so every sensor is compared against an empty string.
* **D59** — `Sub_Get_Snmp_Info ...; if [ $? != 1 ]` reports "Can't connect" and
  `else` runs the checks. `snmpwalk` exits **0** on success, so a successful
  walk takes the error arm. The arms are swapped. The message also interpolates
  `${HOST}`, set in a different function, so it names no host.
* **D60** — `snmpwalk` prints
  `iso.3.6.1.4.1.2606.7.4.3.2.1.16.1.1 = STRING: "Ok"`: four fields, `iso.`
  prefix. The script reads the value from `$9` and the object from `$8` — both
  empty — and `config/43.conf` names OIDs `enterprises.2606...`, which never
  appears in that output. Whatever produced the expected format, it was not
  this `snmpwalk`.
* **D61** — `lang/43.english` defines `DESCR[3]="Rittal value ok: %s"`, but the
  script sets `NO_OF_ERR=2`, so `ERRNO[3]` is never initialised and the healthy
  branch prints `DESCR[2]` instead. Every sensor that is *fine* is logged at
  INFO with the text **"Wrong value in Rittal"**. `test_packaging.py`'s guard
  does not catch this: it checks that every `ERRNO[]` index used is covered by
  `NO_OF_ERR`, not that every `DESCR[]` defined is reachable.

**The compound result is the worst outcome in the tree.** A rack that is
switched off, unplugged or simply unreachable exits `snmpwalk` with 1, which
D59 routes into the sensor branch; D58 leaves `STATUS` empty; the comparison
becomes `test '' != Ok`, which bash rejects as malformed (`test: missing
argument after 'Ok'`); and a non-zero exit from `test` is read as "the value
matches". So an unreachable rack is reported as **seven healthy sensors**.

The comparison logic itself is sound —
`test_the_comparison_logic_works_when_the_input_file_is_in_the_expected_shape`
drives it against a hand-built file and it behaves correctly. That fixture is
marked `UNVERIFIED SHAPE`: no real Rittal walk output was available, so it
proves the script parses *a* shape, not that a Rittal CMC speaks it. **Capturing
one real `snmpwalk` from a rack would settle both that and D60**, and is the
single most useful thing anyone with access to the hardware could contribute.

---

# Addendum 2026-09-13 — Phase 2, the four web-facing checks

Phase 2 was already part done when this session started: suites for `sc_12`,
`sc_18`, `sc_34`, `sc_38` and `sc_40` existed on disk but were untracked and
PLAN.md had not been updated, so the status table understated progress by five
scripts. They were re-run first and they hold — 47 passed, 7 xfailed (D36–D40).

This addendum covers the four checks that talk to a web server: **`sc_02`
(EJBCA healthcheck), `sc_33` (application healthchecker), `sc_37` (JNLP
monitor) and `sc_08` (CRL freshness)**.

| File | Tests | Strategy | Covers |
| --- | --- | --- | --- |
| `test_sc_02_ejbca.py` | 20 (2 strict xfail) | MOCK-SRV | `sc_02` |
| `test_sc_33_healthchecker.py` | 25 (6 strict xfail) | MOCK-SRV + FAKE-BIN `systemctl` | `sc_33` |
| `test_sc_37_monitor_jnlp.py` | 19 (3 strict xfail) | MOCK-SRV | `sc_37` |
| `test_sc_08_crl_from_webserver.py` | 25 (4 strict xfail) | MOCK-SRV + real openssl CRLs | `sc_08` |

89 new tests and **13 new defects, D41–D53**. The suite now stands at

```
$ ./run.sh -q
400 passed, 23 xfailed in 658.54s (0:10:58)
```

423 tests covering 25 of 33 `sc_` scripts at that point in the session; see
the second addendum above for the final figures. That is a far higher defect
density than Phase 1 produced, and the reason is visible in the table: these
four scripts each hand-roll their own HTTP fetch, their own option parsing and
their own "and then act on it" logic, instead of sharing one. The same mistake
therefore appears three and four times over.

## Harness changes

`start_http_server` existed but had never been called. Two changes made it
usable:

* **Routes are now re-readable.** Every one of these checks hard-codes its URL
  path, so the only way to drive their branches is to change what a fixed path
  returns. The server re-reads its route table from a file on each request and
  `HttpServer.set_routes()` rewrites it, so one container serves a whole module
  instead of one container per scenario.
* **Binary bodies.** A DER-encoded CRL is not valid UTF-8 and cannot travel as a
  JSON string, so a route may now carry `body_b64`.

The CRLs in `test_sc_08` are real: a throwaway CA is built in the container with
`openssl req`, and each test mints a CRL with `openssl ca -gencrl -crlsec N`.
Because `openssl ca` cannot backdate `lastUpdate`, the tests hold the CRL
lifetime fixed and move the `MINUTES`/`ERRMIN` thresholds instead — which needs
no clock manipulation and exercises exactly the two settings an operator edits.

## The defects

### D41 — a connection failure is reported under a different service than the healthy check

`sc_02` initialises `SCRIPTINDEX` to `00` and raises it to `01` with
`addOneToIndex` — but that call sits *after* the curl error branch. So EJBCA
answering reports as `02-01` and EJBCA being unreachable reports as `02-00`.

`send_mess_to_monitoring` keys the passive check by `${SCRIPTID}-${SCRIPTINDEX}`,
so these are two different services. The one that was green simply stops being
updated — going stale rather than red — while a service nobody has defined goes
critical. Same class as D25 and D29, which were fixed elsewhere in the tree.

### D42 / D47 / (sc_37) — report-and-continue where the code needed report-and-stop

**D47 ✅ FIXED 2026-09-14** in `sc_33`; D42 and the `sc_37` instance are still open.

Three scripts guard against an unrecognised `CHECKTOOL`, report it, and then
carry on as though the fetch had happened:

* **`sc_02` (D42)** — emits the tool error, then `cat`s a file nothing wrote,
  leaking three `cat: ... No such file` lines to stderr and adding a second,
  false message claiming the *application server* is unavailable. It was never
  contacted.
* **`sc_37`** — identical shape, identical spurious second message.
* **`sc_33` (D47)** — the same missing `exit`, but here the continuation has
  side effects: the loop falls through to `[[ $STATUS == ALLOK ]]` with `STATUS`
  never assigned, takes the failure arm, and **restarts the service**. A typo in
  `CHECKTOOL` bounces every configured application on every run.

### D43 — `sc_33` carries a private copy of the getopt loop that predates the D1 fix ✅ FIXED 2026-09-14

`default_script_getopt` grew a `* )` arm that exits 1; that was the D1 fix.
`sc_33` does not call it. It inlines its own loop, whose `--options` string
still lists `c` even though no arm handles it:

* `-c` — getopt accepts it, no case matches, nothing shifts, `while true` never
  ends. Run from cron that is one syscheck process per tick that never exits.
* an invalid option — getopt rejects it and the script runs `schelp`, but
  `schelp` does not exit and there is no `exit 1` after it. The script prints
  its help text and then goes on to check the apps **and restart them**. A typo
  on the command line bounces a production service.

### D44 — `MAX_RESTARTS=N` permits N+1 restarts ✅ FIXED 2026-09-14

`if [ $restartsin24h -gt $MAXRESTARTS ]` blocks only once the count has already
passed the limit. One over budget sounds minor, but this setting is the only
guard against a crash-loop being amplified by the monitor.

### D45 — `sc_33` fetches a detail URL on every run and discards it ✅ FIXED 2026-09-14

`HEALTHCHECKURL_FULL` is fetched for every app on every tick and passed to
`printlogmess` as `-2`, but `DESCR[1]` is `"app: %s ok"` — one placeholder. On
the healthy path the detail is formatted away. The cost is a second HTTP request
against every monitored application, buying nothing.

### D46 — `CHECKTOOL=wget` turns `sc_33` into a service-bouncing machine ✅ FIXED 2026-09-14

The wget branch runs `STATUS=$(wget "$URL" -T "$TIMEOUT" -t 1 2>/dev/null)`
without `-O -`. wget writes the body to a *file* named after the URL path and
prints nothing to stdout, so `STATUS` is always empty. Empty never equals
`ALLOK`, so a perfectly healthy application is reported down — and, because
that is the branch that restarts, restarted on every cron tick.

`sc_02`'s wget branch gets this right (`-O $OUTPUT`). Verified directly: the
command prints nothing and leaves a file named `health` in the working
directory.

### D48 — `sc_37` never sends the `Host:` header it is configured with ✅ FIXED 2026-09-14

`HEADER="--header \"Host: public.domain.com\""` is expanded **unquoted** into
curl's argv. Word splitting yields `--header`, `"Host:`, `public.domain.com"` —
and the literal quotes are not removed, because expansion results are not
re-parsed for quoting. curl gets the header `"Host:` and a trailing word it
reads as a second URL.

This is the entire purpose of the setting: the shipped URL addresses the
application by IP, so the header is what selects the virtual host. Mangled,
every request lands on the default vhost — which may well answer, so the check
can pass while monitoring the wrong application. Asserted from the server side:
the mock reports back the `Host:` header it actually received.

### D49 — a stale response file makes `sc_37` report an unreachable server as healthy ✅ FIXED 2026-09-14

`sc_02` removes its output file *before* fetching. `sc_37` only removes it at
the end, and a curl that never connects writes nothing — so whatever
`/tmp/internal-error.txt` already held is what gets graded. Seeded with a valid
JNLP and pointed at a host that does not resolve, the check reports **OK**.

Any run killed between the fetch and the final `rm` arms this, and the file
lives at a fixed path in a world-writable directory, so an unprivileged local
user can arm it deliberately and hold the check green through a real outage.

### D50 — `sc_08`'s summary overwrites the verdict it is summarising ✅ FIXED 2026-09-14

The code is commented `# send the summary message (00)`, but the summary
`printlogmess` runs after the loop without resetting `SCRIPTINDEX`, so it
inherits the index of the CRL checked last. With one CRL configured, the
verdict and the summary are both `08-01` and are pushed to the same monitoring
service — the summary, arriving second, wins. A single CRL's detailed verdict
is never the value the monitoring system holds.

`sc_10_ocsp.sh` does this correctly (`export SCRIPTINDEX="00"` before its
summary), so the fix is already written down in the tree.

### D51 — `sc_08`'s per-CRL settings leak into the next CRL ✅ FIXED 2026-09-14

`checkcrl` sets `ARGWARNMIN`/`ARGERRMIN` only when the entry configures a
threshold, and they are plain globals — no `local`, and no reset on the
"default" path. An entry that omits `MINUTES` silently runs with the previous
entry's value. `CHECK_HOST_ARG1`/`ARG2` leak the same way, so a later CRL can be
fetched with an earlier one's `Host:` header — which is how a check ends up
validating a different file than the one it names.

### D52 — without `CRL_HOST_IP`, `sc_08` cannot fetch any CRL at all ✅ FIXED 2026-09-14

The fetch is built as

```
curl ${CRLNAME} --retry N ${CHECK_HOST_ARG1} "${CHECK_HOST_ARG2}" ...
```

and `CHECK_HOST_ARG2` is **quoted**. With no host override configured it is
unset, so the quotes survive as a literal empty argument and curl aborts with
`option : blank argument where content is expected` before making any request.
Every CRL is then reported as undownloadable.

The shipped `config/08.conf` does not hit this, but only by accident: it sets
`CRL_HOST_IP[0]`, and D51's leak carries those arguments forward to every later
entry. Remove the override from the first entry — the obvious way to configure
a bare list of CRL URLs — and the check stops working entirely.

This is the mirror image of D3/D20/D22: there an *unquoted* empty variable
vanished and shifted the following arguments; here a *quoted* one refuses to.

### D53 — a missing CRL is reported as a warning, derived from a Python crash ✅ FIXED 2026-09-15

`curl` runs without `-f`, so a 404 exits 0 and the error page is saved as if it
were the CRL. The cascade:

1. `openssl crl -lastupdate` fails → ERROR 081 "Cant parse file,lastupdate"
2. `openssl crl -nextupdate` fails → ERROR 081 "Cant parse file,nextupdate"
3. neither branch returns, so `cmp_dates.py` is called with two empty date
   strings, raises `ValueError`, and dumps a Python traceback into the check's
   output
4. Python exits 1 on an uncaught exception — and 1 is `cmp_dates.py`'s code for
   **warn**. The crash is reported as `CRL has past the WARN level`, with an
   empty detail.

One missing CRL yields three messages, and the last and least severe is a
fabricated verdict about a validity that was never computed. `if [ "x$CRLCHECK"
= "x" ]` cannot catch this: `$?` is always set, so the guard for "cmp_dates said
nothing" never fires.

## Two things worth recording that are not defects

**Message truncation is deliberate.** A real EJBCA healthcheck returns one line
per failing subsystem, but `lib/printlogmess.sh:193` pipes every message through
`| head -1`, which the one-line-per-record log format requires. So an operator
paged for the database is not told the HSM is also down. Pinned in
`test_sc_02_ejbca.py` as a characterisation test rather than filed as a bug,
because the truncation is the format working as intended — but the consequence
belongs on the record.

**The two health checks disagree about what "healthy" means.** `sc_02` greps for
`ALLOK` anywhere in the body; `sc_33` requires `[[ $STATUS == ALLOK ]]`, an
exact match. An application answering `ALLOK` plus a detail line is healthy to
one check and unhealthy — and therefore restarted — by the other.

## Numbering

There is no D35. It was never assigned; the gap is not a withdrawn defect.

---

# Addendum 2026-09-12 — Phase 1 closed, and the orchestrator covered

**The 61 tests of the previous addendum have now been run, and they hold.** The
whole suite as it stood — 193 tests — passes:

```
$ ./run.sh -q
187 passed, 6 xfailed in 451.93s (0:07:31)
```

No `xpass`, so D21, D22 and D23 are reproductions rather than readings, and the
caveat the previous addendum opened with is discharged. Nothing in it needed
correcting.

Getting there was environmental: this dev container ships
`.devcontainer/Dockerfile` with a Docker engine in it, but runs the stock
`mcr.microsoft.com/devcontainers/base:trixie` image — `devcontainer.json` sets
both `build.dockerfile` and `image`, and the `image` key is what takes effect.
So there is no `dockerd` to start and `start-docker.sh` fails at the last step
with a message blaming privileges. The container *is* privileged; installing
`docker-ce` into it is enough, and then the script works. Removing the `image`
key from `devcontainer.json` would fix this at the source for the next session.

## New suites

| File | Tests | Strategy | Covers |
| --- | --- | --- | --- |
| `test_sc_03_memory_usage.py` | 15 (1 strict xfail) | FAKE-BIN `free`, plus one real-`free` case | `sc_03` |
| `test_sc_07_syslog.py` | 9 | REAL-OS, real `rsyslogd` round trip | `sc_07` |
| `test_sc_09_firewall.py` | 10 (1 strict xfail) | FAKE-BIN `iptables` | `sc_09` |
| `test_sc_14_sw_raid.py` | 8 | FAKE-BIN `mdadm` | `sc_14` |
| `test_sc_30_check_running_procs.py` | 13 (3 strict xfail) | REAL-OS + FAKE-BIN restart command | `sc_30` |

55 new tests, taking the suite to 248 collected and Phase 1 from 10 of 19
scripts to 15 of 19 — before the deletions recorded below cut Phase 1 to 15
scripts in total.

## And the four that closed Phase 1

| File | Tests | Strategy | Covers |
| --- | --- | --- | --- |
| `test_sc_04_pcsc_readers.py` | 10 | FAKE-BIN `list-pcsc-readers.py`, plus the real one | `sc_04` |
| `test_sc_17_ntp.py` | 16 | FAKE-BIN `chronyc` / `timedatectl` / `systemctl` | `sc_17` |
| ~~`test_sc_27_dss.py`~~ | ~~10~~ | deleted with `sc_27_dss.sh` | — |
| `test_sc_42_receipts.py` | 10 | FAKE-BIN `checkreceipts.sh` | `sc_42` |

**Phase 1 is complete**: all 15 of its remaining scripts have a suite. With
`test_syscheck_sh.py` on top of it (below), and after the fixes and deletions
recorded further down, the suite stands at **280 tests** covering 17 of 33
`sc_` scripts — 1165 of their 3184 lines — plus the orchestrator and the shared
library they all run on.

```
$ ./run.sh -q
279 passed, 1 xfailed in 500.38s (0:08:20)
```

**One strict xfail left**, down from 22 at the peak of this addendum, and it is
not a defect in a check: `test_packaging.py`'s guard that `--help` does not list
codes the language file never defined. Every defect D21–D34 is fixed, withdrawn
as by design, or gone with the script that held it. Nothing fails unexpectedly,
and nothing `xpass`es.

Eleven new defects, D24 to D34, every one reproduced in a container before any
of them was acted on.

One fidelity note, recorded in the suite itself: the `sc_17` `chronyc -c` field
order comes from chrony's documentation, not from a capture, and a real sample
would be worth more than any further test case. (The `sc_27` fixture was worse —
derived from the script's own grep, so it could not fail to match — but that
script has since been deleted.)

## The orchestrator, finally covered

`test_syscheck_sh.py` — 28 tests, 1 strict xfail — closes the last piece of
shared plumbing. Until now one getopt regression test in `test_shared_library.py`
was the only thing touching `syscheck.sh`, which means every one of the other 294
tests ran *under* code nothing verified.

What it pins: which directory decides the run (`scripts-enabled`, not
`scripts-available`), that the run order is script-id order, `--screen` reaching
the child scripts through the exported `PRINTTOSCREEN`, `last_status` being
replaced rather than appended to and written in OLDFMT, `--testall` reading the
catalogue instead of the selection, the three after-run hooks firing only when
their flag is set and in the order 929 → 930 → 932, and the hold file stopping
the orchestrator itself.

Two harness changes this needed, both fixes rather than additions:

- **`reset()` did not restore `scripts-enabled` / `related-enabled`.** No test
  had ever written to them. A test that enables a check would have left it
  enabled for every test that followed — and `syscheck.sh` runs whatever it
  finds there, so the leak would have been silent and cumulative.
- **`script_path()` resolved every bare name under `scripts-available/`**, so
  `run_script("syscheck.sh")` looked for the orchestrator among the checks. The
  four entry points at the install root are now named explicitly.

One performance note, because it is the kind of thing that quietly makes a suite
unusable: the four `--testall` tests originally ran all 38 real checks each,
several of which block on a network timeout or a 5s sleep — 591s for 28 tests.
They now empty the catalogue down to what the assertion needs, which is 49s for
the same 28 results. What is under test there is which directory `--testall`
reads, not whether the checks work; they have their own suites for that.

Two new defects, D33 and D34, both in the orchestrator and both about it failing
quietly.

## What was decided about them

Every finding in this addendum was put to the maintainer. The outcome, in their
words as far as possible:

| Defect | Decision | What happened |
| --- | --- | --- |
| D30 — RAID check cannot detect a failed disc | **fix it** | `swraidcheck "${MDDEV[$i]}" "${HDDEV[$i]}"`, and `config/14.conf` renumbered; both xfails now pass and the companion pin is deleted |
| D21 — `proc_checker.sh` bare-pid mode dead | **fix it** | `elif isdigit "$1"` |
| D29 — messages under index `00` | **add index count up** | `sc_04`, `sc_07` raise the index once at the top; `sc_42` raises it first in the loop body |
| D31 — `sc_42` skips a 0-based first entry | **start at 0** | loop is `(( i = 0 ; i < ${#TYPE[@]} ))`, `config/42.conf` renumbered from 0 |
| D33 — a host that monitors nothing exits 0 | **as designed** | withdrawn; both behaviours still pinned by passing tests |
| D22, D23 — BoKS / RSA AXM | **scripts removed** | `sc_22_boks_replica.sh` and `sc_23_rsa_axm.sh` deleted |
| D32 — SignServer worker count | **script removed** | `sc_27_dss.sh` deleted, and `sc_29_signserver.sh` with it |
| D26 — multi-step `RESTARTCMD` restarts nothing | **fix it** | `FOO=$(eval "${RESTARTCMD[$i]}" 2>&1)` |
| D27 — "no restart command" reported as "restart failed" | **fix it** | `NO_OF_ERR=4` and the `ERRNO[4]` the language file already carried |
| D25 — `sc_30` burns a message index | **fix it** | the second `addOneToIndex` removed |
| D28 — an empty firewall rule reports any firewall correct | **fix it** | both rules checked before `iptables` runs; new `ERRNO[4]` names the unset setting |
| D24 — an unreadable `free` pages as a limit breach | **fix it** | the four figures validated as digits; new `ERRNO[5]` says the measurement failed |
| D34 — `--testall` pollutes `last_status` | **fix it** | `SAVELASTSTATUS=0` in the `--testall` branch, and the setting made overridable in `syscheck-scripts.conf` |

`sc_41_ra_verifier.sh` was deleted in the same pass, though it had no open
defect — D15 had already been fixed in it.

Three of the fixes added a message rather than changing one, because the right
answer was "this check could not run" and no code existed to say that: `ERRNO[4]`
in `sc_09` (firewall check not configured), `ERRNO[5]` in `sc_03` (memory usage
could not be read), and `ERRNO[4]` in `sc_30` — that last one already existed in
`lang/30.english` and had simply never been wired up.

**Five scripts, their configs, language files, ansible tasks, bats cases and
testcontainers suites are gone**, which is why the totals below are smaller than
they were an hour earlier. `sc_29_signserver.sh` had no suite; it was an
untested Phase 2 row, so deleting it shrank the plan rather than the coverage.
SignServer is no longer monitored by syscheck at all — worth saying plainly,
since `sc_02_ejbca.sh` still is and the two were a pair.

Six of the ten fixes were one line. The fourth, D29, was a judgement call
worth recording: in `sc_04` and `sc_07` the messages are mutually exclusive
outcomes of a *single* check, so they now share index `01` rather than getting
one index each. Separate indexes would have made the monitoring service name
flip depending on which way the check went, which is the D25 failure — and D25
is still open, so the two would have contradicted each other.

## Two things the first run of these suites got wrong

Worth recording, because both are the failure mode this whole exercise exists to
catch — a test that agrees with the tester rather than with the system.

- **The `mdadm` fake replayed its fixture whatever it was asked.** sc_14 calls
  `mdadm --detail 8` (D30), and a fake that ignores its arguments answers that
  happily, so the suite reported a healthy array and D30 was invisible. The fake
  now checks the array it was given and refuses anything else, as the real tool
  does. A fake binary that does not validate its input can only ever prove the
  script parses our invention.
- **`rsyslogd` in the test image wrote every message to `/var/log/syslog`
  twice**, because Debian's stock `*.*;auth,authpriv.none` rule and the image's
  own `*.*` rule both target that file. No existing test noticed — they all use
  substring matches — but `test_each_run_looks_for_its_own_marker` counts
  deliveries, and an image that doubles them makes "logged once" untestable.
  `Dockerfile.syscheck` now comments the stock rule out.

---

# Addendum 2026-09-11 — Phase 1, the process checks

**Written without ever being executed** — there was no Docker daemon and no
`python3` in that session, so `./run.sh` could not even collect them, and every
finding below was a code reading rather than a reproduction. ~~It needs a real
run before any of it is trusted.~~ **Resolved on 2026-09-12**: the suites were
run unchanged and all 61 tests behaved as written, with no `xpass`, so D21, D22
and D23 are confirmed and nothing here needs correcting. The paragraph is kept
rather than deleted because the gap between "read" and "run" is the point.

New suites:

| File | Tests | Covers |
| --- | --- | --- |
| `test_proc_checker.py` | 8 (2 strict xfail) | `lib/proc_checker.sh`, shared by 7 scripts |
| `test_sc_process_checks.py` | 28 | `sc_05`, `sc_12`, `sc_15`, `sc_16` |
| `test_sc_22_boks_replica.py` | 15 (1 strict xfail) | `sc_22` |
| `test_sc_23_rsa_axm.py` | 10 (2 strict xfail) | `sc_23` |

That is 61 new tests, taking the suite to **193** collected, and Phase 1 from 4
of 19 scripts to 10 of 19.

Harness changes this needed: `start_process()`, `free_pid()` and
`kill_stray_processes()`, plus `init=True` on the container. The last one is not
cosmetic — PID 1 was the image's `sleep infinity`, which never reaps, so every
process a test started and stopped stayed behind as a zombie, and `ps -ef` lists
a zombie as `[name] <defunct>`, which every name-based process check in these
scripts would have matched. Without it these tests would have contaminated each
other in a way that produces confident false passes.

`sc_05`, `sc_12`, `sc_15` and `sc_16` are the same check four times over, so
they share one parametrised file rather than four near-identical ones — the one
deliberate exception to the file-per-script convention.

## Summary of the first pass

| | |
| --- | --- |
| Tests written | 132 |
| Passing (behaviour verified correct) | 131 |
| Strict xfail (confirmed open defect) | 1 |
| Failing unexpectedly | 0 |
| Defects found | 21 (D5 and D8 withdrawn on review) |
| Defects fixed in this pass | 20 |
| Scripts fully covered | 6 of 38 (`sc_01`, `sc_19`, `sc_20`, `sc_32`, `sc_41`, `sc_44`) + `logbook.sh` |
| Runtime | ~215s |

```
$ ./run.sh -q
131 passed, 1 xfailed in 213.46s
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

## D17 — every Icinga check result was submitted as literal, unexpanded text ✅ FIXED
`lib/printlogmess.sh:105`

```bash
curl ... -d '{ "exit_status": $status_code, "plugin_output": "${MESSAGE}", "check_source": "${check_source}" }'
```

The payload was **single-quoted**, so bash never expanded any of it. Verified
against a mock endpoint - this is the exact body Icinga received:

```
POST /v1/actions//process-check-result?host=syscheck-test
{ "exit_status": $status_code, "plugin_output": "${MESSAGE}", "check_source": "${check_source}" }
```

No status, no message, and not valid JSON - `$status_code` is a bare token where
a number belongs. Anyone running with `SENDTO_ICINGA=1` got nothing usable, for
every check, on every host. The OP5 branch fifteen lines above built the same
object correctly with escaped double quotes.

**Fix:** double-quoted so the values expand, `exit_status` left unquoted so it
stays a JSON number, and a `content-type: application/json` header added to
match the OP5 call.

While verifying, a second defect surfaced on the same line: a `"` anywhere in
the message produced invalid JSON on **both** backends.

```
plugin_output":"ERROR - probe cert CN="my host" expired"   <- invalid
```

Certificate subjects, `lunacm` output and `curl` errors can all contain quotes,
so this was reachable in normal operation. A `json_escape` helper now escapes
backslashes, double quotes, tabs and carriage returns, and is applied to the
message, hostname, check name and check source on both the OP5 and Icinga
payloads.

Covered by 12 tests: the I/W/E to status_code mapping for both backends, JSON
validity, and hostile content (a quote, a backslash) passed through a
`printlogmess` argument.

**Worth knowing:** `-d` is the printf *format string* - it holds the `%s`
placeholders that `-1`..`-9` fill - so backslash escapes in a description are
interpreted by design (`C:\file` becomes a form feed). Volatile data belongs in
the numbered arguments, which printf substitutes without interpreting. Scripts
already do this; it is only a trap for anyone writing a new lang file.

## D18 — the shipped OP5 URL was doubled ✅ FIXED
`lib/printlogmess.sh:94`, `config/monitoring.conf`

`config/monitoring.conf` sets

```
OP5_API_URL="https://op5servername/api/command/PROCESS_SERVICE_CHECK_RESULT"
```

and the code posted to `"${OP5_API_URL}/PROCESS_SERVICE_CHECK_RESULT"`, giving
`.../PROCESS_SERVICE_CHECK_RESULT/PROCESS_SERVICE_CHECK_RESULT`. The code and
the shipped config disagreed about who owns the endpoint, so the out-of-the-box
configuration posted to the wrong URL.

**Fix:** the config owns the full URL. The code no longer appends the endpoint.

The Icinga side keeps the opposite split, because the code picks the *action*
(`process-check-result`) and other actions exist: `ICINGA_API_URL` is the base
`/v1/actions`, and its trailing slash was removed so the path no longer contains
`//`.

Covered by `test_op5_url_from_the_shipped_config_is_not_doubled`, and the whole
monitoring suite now uses the shipped URL shapes rather than convenient ones.

## D12 — the package shipped 291 lines of someone else's status ✅ FIXED
`var/last_status`

The file was committed to git containing status from a Nov-2025 build container
(`eba9e0811f66`, `b998b92e8ac5`), including `ERROR` lines, and
`lib/release.sh:83` copies `var/` into the package. A freshly installed syscheck
therefore reported historical failures from another machine before it had run
once, and everything that reads `last_status` - `console_syscheck.sh`,
`929_filter_syscheck_messages.sh`,
`930_send_filtered_result_to_remote_machine.sh` - would have picked them up.

**Fix:** truncated to the single `#placeholder` line it already began with. The
file stays tracked so the path exists in the package and on a fresh install;
only the stale content is gone. `syscheck.sh` recreates it on every run anyway.

Covered by `test_packaging.py::test_fresh_install_has_no_pre_existing_status`,
which copies `var/` straight from the source tree and asserts no non-comment
line survives.

## D19 — the hold notice named a date fragment instead of the user ✅ FIXED
`getroot.sh:95`, `lib/libsyscheck.sh:82`

`getroot.sh` wrote the hold file as `DATE:REASON:USER` and `isSyscheckOnHold`
read the user with `cut -f1 -d\:`. Field 1 is the *date*, and `date` output is
itself full of colons, so the variable named `ONHOLDBY` ended up holding a
truncated timestamp:

```
file:      Wed Aug 26 12:13:40 UTC 2026;disk maintenance;alice
old parse: ONHOLDBY = "Wed Aug 26 12"
```

The user and the reason were both discarded. Invisible until now because D8
prevents the message being displayed at all.

**Fix:** the delimiter is `;`, which cannot collide with `date` output, and the
user is read from field 3.

Covered by `test_syscheck_on_hold_identifies_the_user_who_set_it` and
`test_syscheck_on_hold_is_logged_as_a_warning`, which write the hold file
exactly as `getroot.sh` does. Three pre-existing hold tests were corrected at
the same time - they invented a `operator: maintenance` format rather than
using the real one, which is why this went unnoticed.

## D9 — the on-hold notice reached no sink when `sudo` was unavailable ✅ FIXED
`lib/libsyscheck.sh:81`

```bash
sudo ${SYSCHECK_HOME}/lib/printlogmess-cli.sh -n "common" -i "00" ...
```

This was the only route by which a hold reached syslog, `last_status` or the
monitoring API - the already-sourced local `printlogmess` was never called.
`isSyscheckOnHold` runs from `initscript`, i.e. at the top of all 38 scripts,
which under cron are already root; the `sudo` was redundant there and simply
failed on a host without it installed:

```
libsyscheck.sh: line 84: sudo: command not found
```

**Fix:** call `printlogmess` directly, as every other call site in the library
already does. No new dependency, no subprocess, and the hold now lands in all
four sinks.

**Scope note:** this was about `lib/libsyscheck.sh` only. `getroot.sh` also uses
`sudo` throughout, but that is an interactive operator tool for escalating
privilege - requiring `sudo` there is its purpose, not a defect.

`test_shared_library.py::test_syscheck_on_hold_is_logged_without_requiring_sudo`
now deletes `sudo` from the container before running, and asserts the hold
still reaches the log.

## D13 — `df` was executed twice per filesystem ✅ FIXED
`scripts-available/sc_01_diskusage.sh:45,51`

The first call captured output for the error path; the second re-ran `df` purely
to extract the percentage. On a hung NFS mount that doubled the stall, and the
percentage shown to the operator was not necessarily the one the threshold had
been evaluated against.

**Fix:** the percentage is parsed out of the output already captured in `DFPH`.

`test_sc_01_diskusage.py::test_df_is_only_executed_once_per_filesystem` puts a
counting `df` shim on PATH and asserts exactly one invocation.

## D16 — `sc_44_cert_from_webserver.sh` hung indefinitely on an unreachable host ✅ FIXED
`scripts-available/sc_44_cert_from_webserver.sh:66`

```bash
echo "" | openssl s_client -connect $ARGCONNECT -servername $SERVICENAME >> $outname 2>&1
```

No timeout. Against the shipped config (`192.168.99.21`, unroutable here) the
script ran past 120s with zero output and had to be killed. Verified
pre-existing, not a regression from this pass. `openssl s_client` has no
connect-timeout option, so a `timeout` wrapper is the reliable fix.

**Fix:** `TIMEOUT=5` added to `config/44.conf`, applied as
`timeout "${TIMEOUT:-5}"` so an older config file without the setting still
gets the 5s default.

Two further defects had to be cleared for that timeout to be of any use:

- `if [ "x$outname" == "x" ]` tested the `mktemp` *filename*, which is never
  empty, instead of `check_outname`, the grep result. The "Cant get server
  certificate" branch was therefore unreachable, and a failed handshake fell
  through to parsing an empty file with `openssl x509`. Now tests
  `check_outname`.
- `NO_OF_ERR=5` while the script uses `ERRNO[6]`, `ERRNO[7]` and `ERRNO[8]`,
  which `initscript` therefore never generated. Those three call sites passed an
  empty `-e`, and since the `-e` was unquoted the flag swallowed the following
  `-d` - the same argument-shifting failure as D3, visible in old logs as
  `E-44-d-PKI`. The lang file already defined `DESCR[1]` through `DESCR[8]`, so
  `NO_OF_ERR` is now 8.

Covered by 9 tests, including three against a real `openssl s_server` holding a
generated certificate of a chosen lifetime (valid / inside the warn window /
inside the error window), the timeout being configurable, and the 5s default
applying when the setting is absent.

## D24 — a `free` that cannot be read was reported as a memory limit breach ✅ FIXED
`scripts-available/sc_03_memory-usage.sh:55`

When `free` fails — missing, or blocked by a hardened `/proc` — every figure the
script computes is the empty string, and the test becomes

```bash
[  -gt  ]
```

which is `[` with the single argument `-gt`: a non-empty string, so it is
**true**. Both checks take the error arm:

```
03-01-E-031-PKI ... ERROR - memoryusage Memory limit exceded (Memory usage is  KB: Limit is  KB)
03-02-E-033-PKI ... ERROR - memoryusage Swap limit exceded (Swap usage is  KB: Limit is  KB)
```

Failing loudly is the right direction — unlike D4, nothing is silently dropped —
but a breach that states neither the usage nor the limit was never measured, and
the two cases need opposite responses: a real breach is a capacity problem on
the host, an unreadable `free` is a broken check. `expr` also prints two syntax
errors to stderr on the way, which reach the operator's terminal in `--screen`
mode.

**Fixed**: the four figures are checked for being digits before any comparison,
and anything else produces a new `ERRNO[5]`, "Memory usage could not be read
(%s)", instead of two breach alarms. `NO_OF_ERR` is 5 and `lang/03.english`
carries the message.

Verified by `test_a_failing_free_is_reported_as_a_measurement_failure` and
`test_a_free_that_prints_nothing_usable_is_a_measurement_failure` — the second
covering a `free` that exits 0 but prints no numbers, which the first would not
have caught.

### Also noticed, not filed

- `lang/22.english` has `DESCR[1]` and `HELP[1]` the wrong way round relative to
  every other script — `DESCR[1]="No action is needed"` is the remedy and
  `HELP[1]="all boks processes are running"` is the message — so the healthy line
  reads `INFO - boks No action is needed` instead of naming what is healthy.
  Cosmetic. `lang/23.english` has them the right way round.
- The two `sc_30` observations previously parked here — the unquoted
  `RESTARTCMD` and the burned index — were reproduced by the `sc_30` suite on
  2026-09-12 and are now filed as **D26** and **D25**.

## D25 — `sc_30`'s restart path burned a message index ✅ FIXED
`scripts-available/sc_30_check_running_procs.sh:39`

`addOneToIndex` is called once per configured process and a second time before
the restart, but only one message is emitted either way. So the indexes are
contiguous only while every process is up: one restart and the *next* process
reports under an index one higher than it used last time.

Each index is a distinct service name in the monitoring integration, so a
service that has been reporting under `30-02` silently starts reporting under
`30-03` — the old service name goes stale (and in Icinga, stale means it keeps
showing its last result) while the new one may not exist at all.

**Fixed**: the second `addOneToIndex` is gone, so one entry raises the index
once whatever happens to it.

Verified by `test_the_message_indexes_are_contiguous`.

## D26 — a multi-step restart command ran as one command with `;` as an argument ✅ FIXED
`scripts-available/sc_30_check_running_procs.sh:40`

```bash
FOO=$(${RESTARTCMD[$i]} 2>&1)
```

Unquoted, so it word-splits, but never re-evaluated, so the words are just
argv. The shipped `config/30.conf` documents the multi-step form:

```bash
RESTARTCMD[2]="/etc/init.d/cups stop ; sleep 3 ; /etc/init.d/cups start"
```

which runs `/etc/init.d/cups` **once**, with `stop ; sleep 3 ; /etc/init.d/cups
start` as seven arguments. The stop gets garbage arguments and the start never
runs, so the service sc_30 exists to recover is left down — and whether the
message says the restart succeeded depends on what the init script makes of the
junk.

**Fixed** as `FOO=$(eval "${RESTARTCMD[$i]}" 2>&1)`. `eval` is the right tool
here rather than a risk: `RESTARTCMD` is a shell command line by design — the
shipped config demonstrates the multi-step form — and `config/30.conf` is
root-owned input that the script already trusts to run as root.

Verified by `test_a_restart_command_with_several_steps_runs_every_step`, which
records the argv each invocation actually received.

## D27 — "no restart command defined" was reported as "restart failed" ✅ FIXED
`scripts-available/sc_30_check_running_procs.sh:35`

`lang/30.english` defines four messages. The fourth is

```
DESCR[4]="Process %s was not running, no restart command defined"
HELP[4]="No restart command defined, restart manually"
```

and the script never uses it: the branch for an empty `RESTARTCMD[$i]` sends
`ERRNO[3]`/`DESCR[3]`, "restart failed". `NO_OF_ERR=3` also means `ERRNO[4]` is
never generated, so the message could not be sent as written even if the branch
named it.

The operator is told a restart was attempted and failed when none was
configured — the opposite of the remedy the language file offers for that case,
which is to restart the process manually.

**Fixed**: `NO_OF_ERR=4`, and the branch sends `ERRNO[4]`/`DESCR[4]` — the
message the language file had been carrying unused since it was written.

Verified by `test_a_missing_restart_command_is_distinguishable_from_a_failed_restart`.

## D28 — an unconfigured firewall rule reported the firewall as correct ✅ FIXED
`scripts-available/sc_09_firewall.sh:36`

```bash
rule1check=$(echo "${IPTABLES_RULES}" | grep "$IPTABLES_RULE1")
```

`grep ""` matches every line. If `IPTABLES_RULE1` is empty — never filled in, or
emptied by a typo — the rule that *must exist* is found in any ruleset at all,
including an empty one, and the check reports `INFO 093`. The same expansion in
the other direction makes an empty `IPTABLES_RULE2` (the rule that must *not*
exist) match everything and pins the check to a permanent error.

This is the D4 class: an empty config value must produce a complaint, not a
verdict. It matters more here than most, because the config holds two long
literal `iptables -L -n` lines that a site is expected to edit by hand.

**Fixed**: both rules are checked for emptiness before `iptables` is even run,
and an empty one produces a new `ERRNO[4]`, "Firewall check is not configured
(%s)", naming which setting is missing. `NO_OF_ERR` is 4 and `lang/09.english`
carries the message and its remedy.

Verified by `test_an_unconfigured_rule_is_reported_as_a_config_error`,
parametrised over both rules.

## D34 — `--testall` wrote into `last_status` without resetting it ✅ FIXED
`syscheck.sh:52`

```bash
if [ "x$TESTALL" == "x1" ] ; then
  for file in ${SYSCHECK_HOME}/scripts-available/sc_* ; do
  	$file
  done
  exit
fi

rm -f ${SYSCHECK_HOME}/var/last_status
date > ${SYSCHECK_HOME}/var/last_status
```

`--testall` returns before the `rm -f` and the `date >` that start a normal run
— but the checks it runs still append to `last_status` on their own, through
`SAVELASTSTATUS=1` in `printlogmess`. So an operator running `syscheck.sh
--testall` by hand leaves the file holding the last *cron* run's date header
followed by a mixture of both runs, including results from checks this host has
deliberately not enabled.

Whatever reads `last_status` next takes that mixture for the current state of
the host: `929_filter_syscheck_messages.sh`, and through it
`930_send_filtered_result_to_remote_machine.sh`, which ships it to the central
machine. The date line still says when the cron run happened.

**Fixed**: the `--testall` branch now sets `SAVELASTSTATUS=0` before running the
catalogue, so a diagnostic run reports to the screen and syslog but leaves the
status file alone. That needed one more change — `config/syscheck-scripts.conf`
assigned `SAVELASTSTATUS=1` unconditionally, which would have overwritten the
export, so it now reads `SAVELASTSTATUS="${SAVELASTSTATUS:-1}"`, the same idiom
the `SAVELASTSTATUS_OUTPUTTYPE` line below it already used.

Verified by `test_testall_does_not_corrupt_the_last_status_of_the_real_run`; the
companion test that pinned the old behaviour is deleted.



## D30 — the software-RAID check could not detect a failed disk ✅ FIXED
`scripts-available/sc_14_sw_raid.sh:50`

```bash
for (( i = 0 ;  i < ${#MDDEV[@]} ; i++ )) ; do
    SCRIPTINDEX=$(addOneToIndex $SCRIPTINDEX)
    swraidcheck ${#MDDEV[$i]} ${#DDDEV[$i]} $SCRIPTINDEX
done
```

`${#MDDEV[$i]}` is the **length** of the element, not the element. With the
shipped `MDDEV[0]=/dev/md0` the function is called as `swraidcheck 8 0` and runs

```bash
mdadm --detail 8
```

Three distinct bugs share that one line:

1. `${#MDDEV[$i]}` where `${MDDEV[$i]}` was meant — the array name becomes `8`.
2. `${#DDDEV[$i]}` — `DDDEV` is not a variable this project has. The config sets
   `HDDEV`. So the disk operand is the length of an unset variable, `0`, and
   would be `0` even without bug 1.
3. `${#DDDEV[$i]}` is also the second `${#...}` of the same mistake, so fixing
   the name alone still yields a length.

`mdadm --detail 8` fails on every host, `COMMAND` comes back empty, neither
`active sync` nor `fault` is found, and the check takes its third arm:

```
14-01-E-143-PKI ... ERROR - swraid Disc Array is in an unknown state 8 / 0 ()
```

So the check is **permanently broken in both directions**: it never confirms a
healthy array, and a genuinely faulty disk produces byte-identical output to a
healthy one. Any site that has been seeing 143 and treating it as "sc_14 is
noisy" has no software-RAID monitoring at all.

**Fixed** as `swraidcheck "${MDDEV[$i]}" "${HDDEV[$i]}" "$SCRIPTINDEX"`. The
shipped `config/14.conf` also assigned `MDDEV[0]` three times over, so it
configured one disc while reading as if it configured three; it is now two
properly numbered pairs.

Verified: `test_a_healthy_array_is_reported_ok` and
`test_a_faulty_disk_is_reported_as_a_raid_fault` now pass, and the companion
test that pinned the broken output is gone.

## D31 — `sc_42_receipts.sh` skipped the first entry of a 0-based config ✅ FIXED
`scripts-available/sc_42_receipts.sh:32`

```bash
for (( i = 1 ; i <= ${#TYPE[@]} ; i++ )); do
```

The loop runs from 1 to the element *count*, which is correct only because the
shipped `config/42.conf` happens to number its entries from 1. Every other array
config in this project is 0-based — `FILESYSTEM[0]`, `PROCNAME[0]`, `MDDEV[0]`,
`SNMP[0]` — so an operator who follows that convention here gets:

* `TYPE[0]` never checked — a whole class of receipts silently unmonitored;
* one extra iteration at `TYPE[4]`, which is unset, so `checkreceipts.sh` is
  called with no type argument and its answer is reported against an empty name.

Both halves are silent. The count of messages even looks right, which is what
makes it hard to spot: four configured types still produce four messages.

**Fixed**: the loop is now the same `for (( i = 0 ; i < ${#TYPE[@]} ; i++ ))`
every other script uses, and `config/42.conf` is renumbered from 0 to match.
Verified by `test_a_zero_based_type_array_checks_every_configured_type`, whose
helper now generates 0-based configs by default.


## D29 — four scripts submitted messages under index 00 ✅ FIXED
`sc_07_syslog.sh:47`, `sc_04_pcsc_readers.sh:30`, `sc_27_dss.sh:27`,
`sc_42_receipts.sh:33`

`initscript` leaves `SCRIPTINDEX=00`, and the convention every other script
follows is to call `addOneToIndex` *before* its first `printlogmess`. These four
do not:

| Script | Message that lands under `00` |
| --- | --- |
| `sc_07` | "syslog is not running" — printed before the only increment |
| `sc_04` | "module not installed" — same, before the pyscard check returns |
| `sc_27` | "SignServer is not installed at this host" — same |
| `sc_42` | **every** message — the increment is the last statement in the loop body instead of the first, so all indexes are shifted down one and the highest one is never used |

The index is half of the service name the Icinga/OP5 integration submits
(`test_monitoring_integration.py`), so these messages arrive under a service
name no other message in the same script ever produces. For the first three that
means the tool-missing alarm is the only thing that ever reports on `NN-00`; for
`sc_42` it means every receipt type reports one service lower than the config
reads.

Note the three single-message cases are all on a *tool or product missing* path
— the one path a fresh or half-finished install takes, so it is the first thing
a new host does and the least likely to have been noticed in production.

**Fixed.** In `sc_04`, `sc_07` and `sc_27` the index is now raised once at the
top of the script and the later duplicate raise is removed, so both branches
report under `01`. (`sc_27` was deleted later the same day; the fix stands in
the other three.) That is deliberate rather than incidental: in all three the
messages are mutually exclusive outcomes of a *single* check, and giving them
separate indexes would make the monitoring service name flip depending on which
way the check went — the D25 failure. `sc_42` raises the index as the first
statement of its loop body instead of the last, so its types report 01, 02, 03.

Verified by `test_the_daemon_down_message_carries_a_real_index` (sc_07),
`test_the_module_missing_message_carries_a_real_index` (sc_04),
`test_the_not_installed_message_carries_a_real_index` (sc_27) and
`test_the_message_indexes_start_at_one` (sc_42).

## D21 — `proc_checker.sh`'s documented bare-pid mode was dead code ✅ FIXED
`lib/proc_checker.sh:42`

```bash
elif [ $(isdigit $1) ] ; then
	checkpid $1
```

`isdigit` reports through its **return status** and prints nothing:

```bash
isdigit(){
	case $1 in
    ''|*[!0-9]*) return 1 ;;
		*)           return 0 ;;
	esac
}
```

So `$(isdigit $1)` is always the empty string, `[ "" ]` is always false, and the
branch can never be taken. The usage line advertises

```
proc_checker.sh <pid-file>|<pid> <procname>
example: proc_checker.sh 1234 syslogd
```

but `proc_checker.sh 1234 syslogd` checks the *name* `syslogd`, never pid 1234,
and `proc_checker.sh 1234` with no name falls past every arm to
`proc_checker_help` and exits 1. The correct test is `if isdigit "$1" ; then`.

It went unnoticed because every caller but one passed a path plus a name, and
that one caller — `sc_23_rsa_axm.sh` — has since been deleted.

**Fixed** as `elif isdigit "$1" ; then`. Verified by the two tests in
`test_proc_checker.py` that distinguish the branches by passing a pid together
with a name that cannot match.

## D20 — 8 scripts silently dropped messages on real error paths ✅ FIXED
`NO_OF_ERR` in 7 scripts, plus 2 language files

`initscript` generates `ERRNO[1]`..`ERRNO[$NO_OF_ERR]`. A script referencing an
index above its own `NO_OF_ERR` passed an **empty** `-e`, and since the flag is
unquoted at every call site it swallowed the following `-d`, so `printlogmess`
rejected the call and the message was lost:

```
$ printlogmess -n ejbca -i 02 -x 01 -l E -e ${ERRNO[4]} -d "${DESCR[4]}" -1 arg
printlogmess: missing description (-d), called by bash: -n ejbca -i 02 -x 01 -l E -e -d EJBCA : application server unavailable -1 arg
rc=1
```

Before D1 was fixed the same calls emitted corrupted lines instead - the
`E-44-d-PKI` entries in the old `var/last_status`, with `-d` as the error
number, are this bug.

Found via `sc_44`, which was wrong by three; a scan of all 38 `sc_` and 43
`related` scripts found 13 more.

| script | was | now |
| --- | --- | --- |
| `sc_02_ejbca.sh` | 3 | 4 |
| `sc_31_hp_health.sh` | 5 | 6, `DESCR[6]` added |
| `905_publish_crl.sh` | 3 | 8 - five paths restored |
| `911_activate_VIP.sh` | 4 | 6 |
| `919_certpublisher_remotecommand.sh` | 3 | 4, `DESCR[4]` added |
| `925_publish_crl_from_file.sh` | 3 | 4 |
| `931_mysql_backup_encrypt_send_to_remote_host.sh` | 3 | 5 |
| `938_mariabackup.sh` | 23 | 23; 14 missing `DESCR[]` written |

Verified emitting again:

```
02-01-E-024-PKI ... ERROR - ejbca EJBCA : application server unavailable
31-01-E-316-PKI ... ERROR - hp_health Warning in HP Healthcheck (detail)
```

`938_mariabackup.sh` had a different form of the same fault: `NO_OF_ERR` was
high enough, but its language file defined only `DESCR[1..3]` against `ERRNO[]`
indexes up to 23, so 14 paths failed the `-d` guard rather than the `-e` one.
Descriptions were written from each call site's surrounding code and arguments.

`919` used `-e ${ERRNO[4]} -d "${DESCR[3]}"`; it now uses `DESCR[4]`, a new
entry describing the UID-extraction failure that path actually detects.

Two static guards in `test_packaging.py` now hold the line:
`test_no_of_err_covers_every_errno_index_used` and
`test_every_errno_index_used_has_a_description`. Neither needs a container.

### Still open: cosmetic only

`test_help_does_not_list_undefined_error_codes` remains xfail. `NO_OF_ERR`
promises more codes than the language file defines in `sc_07_syslog.sh`,
`903_make_hsm_backup.sh`, `927_create_crls.sh`, `928_check_dsm_backup.sh`,
`930_send_filtered_result_to_remote_machine.sh`,
`935_mysql_console_as_root.sh`, and now `938_mariabackup.sh` for the seven
indexes it never emits. `schelp` prints a blank entry for each. No runtime
effect.

### Error-code collision resolved

`938_mariabackup.sh` used `ERRNO[4]` for two unrelated outcomes - `INFO`
"incremental backup done" at line 112 and `ERROR` "full backup directory
missing" at line 97. One description could not serve both, so the error path
was given its own code from the free range (1, 8, 14, 15, 18, 20, 22):

```
938-01-E-9388-PKI ... ERROR - mariabackup Incremental backup: full backup directory does not exist (/backup/2026-08-26/FULL)
938-02-I-9384-PKI ... INFO  - mariabackup Incremental backup: /backup/2026-08-26/INC (time: 42 size: 1.2G)
```

`ERRNO[8]` sits alongside `ERRNO[13]`, which reports the same missing-full-backup
condition from the prepare step. Monitoring can now distinguish a successful
incremental backup from one that never ran.

## D10 — `sc_19_alive.sh` reported `[3]` instead of its heartbeat ✅ FIXED
`scripts-available/sc_19_alive.sh:27`

`-d "$DESCR[3]"` should have been `-d "${DESCR[3]}"`. Bash expanded `$DESCR` as
`${DESCR[0]}`, which is unset, followed by the literal text `[3]`:

```
19-01-I-193-PKI ... INFO - alive [3]
```

The one message this script exists to send carried no content. Now:

```
19-01-I-193-PKI ... INFO - alive I'm alive
```

Covered by 3 tests in `test_sc_19_alive.py`, including the round trip to syslog.

## D15 — `sc_41_ra_verifier.sh` dropped its "tool missing" message ✅ FIXED
`scripts-available/sc_41_ra_verifier.sh:29`

`-d "$DESCR_3"` named a variable that does not exist; the language file defines
`DESCR[3]`. `printlogmess` received an empty description and rejected the call,
so a missing RA verifier tool was reported nowhere. Found by the all-script
sweep after D1 was fixed - before that, the old guards killed the script here
instead.

Two further problems on the same three lines:

- `SCRIPTINDEX` was never incremented, so this was the only message in the
  script using index `00`.
- The script carried on and executed the tool it had just reported missing,
  producing a second, meaningless set of results from an empty output file. It
  now exits.

`DESCR[3]` gained a `%s` so the message names the path that was not found:

```
41-01-E-413-PKI ... ERROR - ra_verifier RA : health check tool failure (/opt/certificate-services/vcc-factoryra-verifier/verify-factoryra.sh)
```

Covered by 6 tests in `test_sc_41_ra_verifier.py` driving a fake verifier: all
three checks passing, all three failing, one failing in isolation, the missing
tool, and that a missing tool stops the run.

## D14 — `diskusage()` returned an invalid status ✅ FIXED
`scripts-available/sc_01_diskusage.sh:34,38`

`return -1` is not valid in bash; the status wraps to 255. Both guard clauses
now `return 1`.

The caller still ignores the value, so nothing observable changes today - but
the two guards were unreachable until D3/D4 were fixed, and a wrapped status
would have been the next thing to trip anyone who started checking it.

`test_sc_01_diskusage.py::test_a_rejected_config_entry_returns_a_valid_status`
sources the script with an empty config, so the main loop is a no-op and the
function can be called directly, then asserts both guards return 1 rather than
255.

## D11 — `sc_32_check_db_sync.sh` was disabled in place ✅ REWRITTEN
`scripts-available/sc_32_check_db_sync.sh`

The script contained a hard-coded `echo "This script is broken"; exit` with the
real comparison logic stranded as dead code below it. In a default install it
exited even earlier, because the
`database-replication/808-test-table-update-and-check-master-and-slave.sh` it
required is not shipped, and emitted a permanent ERROR into monitoring using
index `00`.

Rewritten to compare a configurable set of tables across two or three nodes.
The method is documented in `docs/db-consistency-check.md`; the short version:

- **Settle window.** Only rows older than `DBSYNC_SETTLE_SECONDS` are compared,
  so writes in flight cannot make two nodes look different. This is what makes
  the check deterministic on a database that is still moving.
- **Retry before reporting.** A mismatch is recomputed up to
  `DBSYNC_RECHECK_TRIES` times. Converging means replication lag and is reported
  as a WARNING; still differing after the last attempt is a real divergence and
  is an ERROR. This distinguishes "node2 is 3 seconds behind" from "node2 is
  missing 400 rows" without reading replication status at all.
- **Order-independent checksum.** `BIT_XOR(CRC32(CONCAT_WS(...)))` over the
  columns read from `information_schema` at runtime, compared alongside
  `COUNT(*)` because XOR cancels duplicate identical rows.

Eight error codes replace the previous two, so monitoring can tell a divergence
from lag, from an unreachable node, from a missing table, from a config error.

Covered by 13 tests in `test_sc_32_check_db_sync.py` running against **two real
MariaDB nodes** on a shared docker network: identical nodes, a missing row, a
changed value, two extra identical rows (the case the checksum alone misses), a
write inside the settle window being ignored and the same write outside it being
caught, a lagging node converging into a WARNING, whole-table comparison for a
table with no cutoff column, whole-table comparison for a table with no cutoff
column (which also covers several tables being reported separately with their
own script indexes), an unreachable node, a missing table, and both config
errors.

This is the first suite to use real service containers, so the harness gained
`create_network` and `start_mariadb_node`, and the base image gained
`mariadb-client`.

---

# Open defects

**None.** Every defect this report has raised is fixed, withdrawn, or gone with
the script that held it. What follows is the record of the ones that were not
fixed, and why. The only strict xfail left in the suite is
`test_packaging.py::test_help_does_not_list_undefined_error_codes`, which is a
shape problem in `--help` rather than a defect in a check: `NO_OF_ERR` may
promise more codes than a language file defines, and `--help` then prints blank
entries for them.

## ~~D33 — a syscheck that runs no checks at all reports success~~ ❌ WITHDRAWN, by design
`syscheck.sh:61` and `:67`

With nothing linked into `scripts-enabled` the glob matches nothing, bash leaves
the pattern unexpanded, and `$file` is executed as a filename containing a
literal `*`:

```
$ ./syscheck.sh ; echo $?
/opt/syscheck/syscheck.sh: line 62: /opt/syscheck/scripts-enabled/sc_*: No such file or directory
0
```

Exit status 0, no syscheck message, and a `last_status` holding only a date. The
same happens at line 67 when a hook flag is on and the `related-enabled` symlink
was never made.

Filed as a defect on the argument that a host monitoring nothing looks identical
to a healthy one. **Confirmed by the maintainer as intended**: syscheck reports
on the host, not on its own configuration, and an install with nothing enabled
is the operator's business, not something the tool should alarm about.

Both behaviours are still pinned — by
`test_an_empty_scripts_enabled_directory_runs_nothing_and_exits_zero` and
`test_an_enabled_hook_that_is_not_installed_exits_zero` — because "exits 0
having run nothing" is surprising enough to be worth stating on purpose rather
than leaving for the next reader to rediscover.

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

## ~~D8 — the "syscheck is on hold" notice prints the literal string `00`~~ ❌ WITHDRAWN, by design

`libsyscheck.sh:82` is `printf "00" "0" $WARN "00" "SYSCHECK IS ON HOLD BY: ..."`
- a format string with no conversion specifiers, so it prints `00` and discards
its five arguments. Confirmed by the maintainer as intentional, not a defect.

Context for anyone reading the code later: `isSyscheckOnHold` is called from
`initscript`, which runs *before* `default_script_getopt`, so `PRINTTOSCREEN` is
still 0 at that point and the message routed through `printlogmess` cannot
honour `--screen`. The bare `printf` is what an operator sees on stdout. The
message itself does reach syslog, `last_status` and the monitoring API - see D9
and D19.


---




## ~~D22 — `sc_23_rsa_axm.sh` reports healthy services as down~~ 🗑 MOOT, script deleted
## ~~D23 — a list of failed processes is reduced to its first entry~~ 🗑 MOOT, scripts deleted
## ~~D32 — a SignServer with more workers than expected is reported as not running~~ 🗑 MOOT, script deleted

All three lived in scripts deleted on 2026-09-12 — `sc_22_boks_replica.sh`,
`sc_23_rsa_axm.sh`, `sc_27_dss.sh` — and have no code left to affect. D22 was
the unquoted `$pid` argument vanishing so that `proc_checker.sh` received the
process name as `$1`; D23 was `-1 $NAMES_OF_NOT_RUNNING_PROCS` word-splitting so
that only the first dead process was named; D32 was the SignServer worker count
compared against a hard-coded 2, so a third worker read as an outage.

The underlying *classes* both survive elsewhere and are worth remembering:
an unquoted empty variable silently shifts every following argument (D3, D20,
D22), and an unquoted multi-word variable is truncated to its first word (D23).
`grep -n ' -1 \$[A-Z]' scripts-available/` is the cheap check for the second.







## 2026-09-16 — `917` argument passing fixed, `921` deleted

### D75 — `917_archive_file.sh` shifted every positional argument by one ✅ FIXED 2026-09-16

The option loop ended with

```bash
    --) break;;
```

`getopt` places the positionals after a `--` separator, so breaking without
shifting past it left `$1` as the literal string `--`:

```
FileToArchive=<-->   ArchiveServer=<myfile.log>   ArchiveDir=<host1>
```

Every argument landed one place to the right. `917` tried to archive a file
named `--`, which is unreadable, so the `[ ! -r $file ]` guard skipped it and
the script exited reporting nothing. The next line,
`if [ "x$1" = "x--keep-org" ]`, could never match for the same reason.

`--keep-org` was also absent from the `getopt` long-option list, so the one
caller that passes it — `916_archive_access_manager_logs.sh` — made `getopt`
fail. The failure branch was `schelp` with no `exit`, so the script continued
with `eval set -- ""` and no arguments at all.

Fixed by shifting past `--`, adding `keep-org` to `--long` with its own case
arm, and making the `getopt` failure branch `exit 1`.

### D76 — `917` called `915` and `906` positionally ✅ FIXED 2026-09-16

Same defect class as D56 (`sc_28`), `#11` (`930`) and the deleted `913`/`921`.
Both helpers take named options only; all four call sites in `transferFile`
passed positionals, so the remote transfer exited at its first return-code
check. Converted to `--host=`/`--command=`/`--user=`/`--key=` and
`--file=`/`--dir=`, and the two `printtoscreen` echo lines updated to match
(one still printed the old positional form, the other had unescaped quotes that
truncated the printed command).

Note that `915` requires a non-empty `--user`, while `917` documents its arg4
as optional. Passing an empty user now produces a visible "missing argument"
error instead of silence. Not changed here — `917`'s own documentation is what
disagrees with `915`'s contract.

### `921_copy_htmf_conf.sh` deleted 🗑

Dead for the same reason `913` was: positional calls to `915` and `906`. Removed
with `config/921.conf`, `lang/921.english`, the ansible template, task entries
and default, and its `docs/related-scripts.md` section.

### D77 — every message in `917` was the literal text `[N]` ✅ FIXED 2026-09-16

All 17 `printlogmess`/`printtoscreen` calls referenced `$ARCHIVE_DESCR[N]` and
`$ARCHIVE_PTS_N`. No `ARCHIVE_`-prefixed arrays exist anywhere in the tree —
`lang/917.english` defines the usual `DESCR[]`/`PTS_` names — so the expansion
was an undefined variable followed by a literal subscript:

```
$ARCHIVE_DESCR[9]  ->  [9]        ${DESCR[9]}  ->  Intransit dir not found
```

There was also no `-d` flag, so the stray `[9]` was passed to `printlogmess` as
a positional argument rather than as the description. Trailing arguments were
passed the same way instead of as `-1`/`-2`, so the `%s` placeholders in
`DESCR[1]`, `DESCR[2]` and `DESCR[7]` never filled either.

`917` was the only script in the tree using this form. Fixed by switching to
`-d "${DESCR[N]}"` with explicit `-1`/`-2` arguments, and adding the `PTS_3`
string that the "file not readable" branch referenced but which was never
defined in the language file.

### `917` — the remote transfer still needs a design decision ❌ OPEN

Not fixed, because it is a choice rather than a repair. `917` claims a unique
remote filename with `mktemp` and then asks `906` to copy to that exact path:

```bash
906_ssh-copy-to-remote-machine.sh --file="..." --dir="${ArchiveDir}/${remoteFileName}"
```

But `906` treats `--dir` strictly as a directory — it runs
`put ${SSHFILE}` into `${SSHDIR}` and then verifies `${SSHDIR}/$(basename
${SSHFILE})`. Passing a file path lands the file at
`${ArchiveDir}/${remoteFileName}/${basename}`, and `917`'s subsequent md5sum
check looks somewhere else again.

The two contracts cannot both hold. Either `906` grows a way to name the remote
file, or `917` drops the `mktemp` claim and accepts `906`'s naming. Since the
remote path has never executed (D76), there is no prior behaviour to preserve
and no evidence for which was intended.

`test_917_archive_file.py` covers everything up to this point — 15 tests, all
passing — and stops there deliberately. `916_archive_access_manager_logs.sh`
depends only on the covered part.

Knock-on: a failed transfer makes `archiveLocally` `exit 1` in the main shell,
so the remaining files in a multi-file run are abandoned with no message of
their own. Pinned as characterisation in
`test_one_failed_transfer_abandons_the_remaining_files_silently`.

## 2026-09-16 — Phase 4, EJBCA CLI group

The group's PLAN entry described it as FAKE-BIN `ejbca.sh` throughout. That is
wrong for most of it: `900`, `901`, `902` and `919` drive real `openssl` and
touch no EJBCA tooling at all, and `925` shells out to `906`. Only `905`, `909`,
`910` and `927` actually invoke `ejbca.sh`.

### D78 — `927_create_crls` loses the tool output on success ✅ FIXED 2026-09-17

`DESCR[1]` is `"Create CRL run successfully (%s)"`, one placeholder, but the
success branch passes the captured output as `-2`, so `ARG1` is empty and the
message reads `Create CRL run successfully ()`. The failure branch uses `-1`
correctly. Same family as D77 in `917`.

### D79 — `909_activate_CAs` cannot report a failure ✅ FIXED 2026-09-18

```bash
./bin/ejbca.sh ca activateca $NAME $PIN | tee ${SYSCHECK_HOME}/var/$0.output
error=$(grep -v "Enter authorization code:" ${SYSCHECK_HOME}/var/$0.output)
```

`$0` is the script's full path, so the tee target expands to
`var//opt/syscheck/related-enabled/909_activate_CAs.sh.output` — a directory
that does not exist. `tee` writes nothing, the `grep` reads a missing file and
returns empty, and empty is the success condition. **Every CA reports activated
regardless of what EJBCA did**, including the HSM-token failure that `HELP[2]`
tells the operator to look for. Structurally incapable of failing, like D38 in
`sc_40`. `910` has the same defect using `cat` instead of `grep -v`.

### D80 — `910_deactivate_CAs` never passes the CA name ✅ FIXED 2026-09-18

`909` opens its loop with `NAME=${CANAME[$i]}`; `910` does not, yet still runs
`./bin/ejbca.sh ca deactivateca $NAME`. `NAME` is unset and unquoted, so it
vanishes and the tool is invoked with no CA argument. The screen output shows
the correct CA name from `${CANAME[$i]}` while nothing is deactivated.

### D81 — `910` has no CA list at all as installed ✅ FIXED 2026-09-18

`config/910.conf` says *"none, CA:s and pins are defined in common.conf"*, but
`CANAME` appears nowhere in `common.conf` — it is in `config/909.conf`, which
`910` never reads (no `getconfig` call). `${#CANAME[@]}` is zero, the loop body
never runs, and `910` emits nothing whatsoever. Same root cause as D38.

### D82 — `900`, `901` and `902` hang forever on their own input option ✅ FIXED (900/901 2026-09-16, 902 2026-09-17)

All three declare the option carrying their only input without a trailing colon:

```bash
getopt --options "hsvc" --long "help,screen,verbose,crl"   # 902; 900/901 use "cert"
```

so `getopt` treats it as taking no argument and emits `--crl -- '/path/to.crl'`.
The case arm runs `CRLFILE=$2; shift 2`, assigning the `--` separator and
shifting past it, which leaves `$1` on the file path. That matches no arm,
nothing shifts, and `while true` spins forever. Measured: exit 124 under a
15-second `timeout`.

These three never terminate when given the option they exist to accept. Driven
from cron they leave a stuck process behind on every run. `925` declares the
equivalent option as `crlfile:` and is unaffected — the colon is the whole
difference.

### D83 — `902`'s missing-file guard has no command name ✅ FIXED 2026-09-17

```bash
if [ "x$CRLFILE" = "x" -o ! -r "$CRLFILE" ] ; then
	 -n ${SCRIPTNAME} -i ${SCRIPTID} -x ${SCRIPTINDEX} -l $ERROR -e ${ERRNO[3]} -d "${DESCR[2]}"
```

`printlogmess` was absent; the line started with `-n`, so the shell tried to
execute `-n`, failed, and the script exited silently. `902` called without an
input file reported nothing at all. The same line also paired `ERRNO[3]` with
`DESCR[2]`, so restoring the command name alone would still have printed the
wrong description.

Fixed together with the wider remapping `900` and `901` received on 2026-09-17:
`902` used `ERRNO[3]` at nine sites and `ERRNO[2]` nowhere, so every failure
reported "script called without file". Now `[3]` guards the missing file, `[2]`
covers processing failures with the file the failure is about, and `[1]` is
success. The `printtoscreen` beside it was also printing raw flags as text.

`test_902_export_crl.py` is now 9 passed, 0 xfailed — all four of its xfails
cleared, and two tests mirrored from `900`'s suite: that a corrupt CRL is not
described as a missing one, and that it produces no archive.

With this, every script in `related-available/` runs. `902` was the last one
that could not.

### `925_publish_crl_from_file` calls `906` positionally ❌ OPEN — needs a decision

Same class as `921` and `913`, but not silent: `906` refuses on the missing
`--file` and `925` reports `ERRNO[4]` for every host, so it always fails rather
than never running. Delete on the `921` precedent, or convert to named options —
not decided, so no suite written.

### Smaller items

- `900`/`901` check `$?` after `openssl … | sed`, reading **sed's** status, so an
  `openssl` failure is masked. `902` keeps the pipelines separate.
- All three pass `-1 "$?"` *inside* the `if` branch, where `$?` is the `[` test's
  own result — always `0`. The reported value is meaningless in both branches.
- `config/900.conf`, `901.conf` and `902.conf` build `DATE` with
  `date +'%Y-%m-%d_%H.%m.%S'` — `%m` is the month, not the minute, so archived
  filenames carry hour.month.second. Same defect as the `%H:%m` fixed in `934`
  on 2026-09-15.
- `900` and `902` invoke `917` through `related-enabled/` while `916` uses
  `related-available/`; the former fails if the script has not been enabled.
- `919` calls `getopt` twice (lines 24 and 40), the second discarding the first.

### Suites landed

`927` (8 passed, 1 xfail), `909` (6 passed, 1 xfail), `910` (4 passed, 3 xfail),
`902` (3 passed, 4 xfail). `916` also landed here (8 passed, 1 xfail).

## 2026-09-16 — Phase 4, mysql group opened with `933`

### D85 — `933_select_from_database` can only ever run once ✅ FIXED 2026-09-16

`initscript` sets `noclobber` for every syscheck script
(`lib/libsyscheck.sh:56`), and `933` writes each result with a plain truncating
redirect:

```bash
date +'...' > ${SYSCHECK_HOME}/var/${SQL_SUMMARY_FILE}
echo "${SQL_SELECT[$j]}" | $MYSQL_BIN ... > ${SYSCHECK_HOME}/var/${OUTFILE[$j]}
```

With `noclobber` on, `>` refuses an existing file:

```
var/out_users: cannot overwrite existing file
```

The redirection fails before the query runs, so `$?` is non-zero and every query
reports `9332`, "Could not get info from db". On a freshly installed host the
first run succeeds and every run after it fails — while the summary file, also
written with `>`, keeps sitting there holding the first run's data. A reader
sees a stale report with nothing indicating it is stale.

Fixed with `set +o noclobber` before the writes. `933` rewrites these files by
design on every run, so the protection `initscript` turns on is the wrong
default for this script. `sc_20_errors_ejbcalog.sh` meets the same constraint
and resolves it the other way, with `2>|` at the single redirect that needs it.

`test_it_can_run_twice` now passes rather than xfailing.

Exposure across the tree is narrow: `933` (now fixed) and
`911_activate_VIP.sh:66` (`date > ${SYSCHECK_HOME}/var/this_node_has_the_vip`),
where the same failure meant the VIP marker file was never refreshed after the
first activation — also fixed on 2026-09-16 with the same `set +o noclobber`.
No script in `scripts-available/` is affected.

The `911` fix is **not covered by a test**: the VIP group (`911`, `912`) has no
suite yet, so it rests on the mechanism proven by `933`'s
`test_it_can_run_twice` rather than on its own assertion. Worth a test when the
VIP group is written — the marker file is how the cluster answers "which node
holds the VIP", so a stale one is a misleading answer rather than a missing
one.

### D84 — `933`'s summary timestamp records the month as the minute ✅ FIXED 2026-09-17

```bash
date +'%Y-%m-%d_%H.%m.%S'
```

The middle field of the time is `%m`, the month, rather than `%M`. Every summary
is stamped `HH.<month>.SS`, so two reports an hour apart in the same month
differ only in seconds. Same mistake as `config/900.conf`, `901.conf` and
`902.conf`, and as the `%H:%m` fixed in `934` on 2026-09-15.

### Suite landed

`test_933_select_from_database.py` — 12 passed, 1 xfailed. REAL-SVC against
`mariadb:11`; failures produced by dropping the table and by a wrong password,
nothing mocked.

## 2026-09-16 — `914_compare_master_slave_db` 🗑 DELETED

The findings below stand as the record of why it went. `914` was removed on
2026-09-16: unlike `913` and `921` it ran correctly, but D86 meant it reported
nothing, and `sc_32_check_db_sync.sh` already does the same job properly —
content checksum rather than row counts, a settle window for replication lag,
retries, timeouts, and 11 `printlogmess` calls. Its test suite was deleted with
it.

### D86 — `914` reports nothing to monitoring 🗑 SCRIPT DELETED

The script contains **zero** `printlogmess` calls. It has `NO_OF_ERR=2` and
`lang/914.english` defines `DESCR[1]` "Data read successfully" and `DESCR[2]`
"Could not get table data", but neither is ever used. Everything `914` learns
goes to stdout as a `diff` and is discarded unless a human is watching.

So a replica that has silently diverged produces no alert, no syslog entry and
nothing in `last_status`. Enabling `914` buys no monitoring at all — it is a
manual diagnostic wearing a check's clothing. It also ignores `diff`'s exit
status, so even its own notion of "these differ" is never acted on.

Recorded as a defect rather than characterisation because the unused `DESCR[]`
entries show that reporting was intended.

### D87 — the `show tables` header filter hardcodes the `ejbca` database name 🗑 SCRIPT DELETED (`914`)

```bash
| grep -v Tables_in_ejbca
```

`Tables_in_<dbname>` is the column header MariaDB prints, so this only filters
when `DB_NAME` is literally `ejbca`. For any other configured name the header
survives into the table list, the script runs
`select count(*) from Tables_in_otherdb`, and the literal header lands in the
comparison file on both sides. `DB_NAME` is configurable in
`config/mariadb.conf`, so `914` works only for installations that kept the
default name.

### D88 — `914` ignores `MYSQL_BIN` ⚠️ OPEN, masked at runtime

It calls `getconfig "mariadb"`, which defines `MYSQL_BIN`, then runs the bare
command `mysql` four times. Debian's `mariadb-client` still ships
`/usr/bin/mysql` as a symlink to `mariadb`, so `914` does run in this image —
but only by that compatibility shim. A host that sets `MYSQL_BIN` to a
non-default path, or one without the shim, gets a script that cannot find its
client. Every other script in this group honours `MYSQL_BIN`.

### Suite landed

`test_914_compare_master_slave_db.py` — 5 passed, 3 xfailed. REAL-SVC with two
`mariadb:11` nodes; divergence created by inserting into one node only.

Worth recording about the suite itself: the D87 test initially **xpassed for the
wrong reason**. It created the alternative database as root without granting the
`ejbca` user access, so the run failed on privileges before the header filter
could matter. The grant is now part of the test, and the xfail is real.

### D89 — `sc_40_cluster` used the bare `mysql` command for the Galera status ✅ FIXED 2026-09-16

The script was inconsistent with itself. Line 44 validates that `MYSQL_BIN` is
set, line 48 uses `$MYSQL_BIN` for the SELECT keepalive, and line 77 then
ignored it:

```bash
STATUS=$(echo "show status like '${CLUSTER}';" | mysql 2>&1)
```

It survives only because Debian's `mariadb-client` still ships `/usr/bin/mysql`
as a symlink to `mariadb`. A host that sets `MYSQL_BIN` to a non-default path —
which the guard at line 44 exists to support — would pass its own check and then
query a different client, or none.

Found by comparing `sc_40` with `914`, which had the same defect as D88.

The `sc_40` suite stubbed exactly this seam, installing its wsrep wrapper as
`/usr/local/bin/mysql`, so the fix routed around the wrapper and broke 8 tests.
The seam moved rather than the fix: `MYSQL_BIN` now points at the wrapper, so
both the SELECT and the `show status` go through it, and
`test_an_inactive_cluster_on_a_real_server_is_reported` switches `MYSQL_BIN` to
the real client instead of deleting the wrapper file. 16 passed.

## 2026-09-16 — `940_mariadb_jobs`

### D90 — `--job` takes an array index, so a name silently runs job 0 ✅ FIXED 2026-09-16

The option is spelled `--job` and the configuration defines `DBJOBS_NAME[]`, but
the value is used as an array **subscript**:

```bash
sqlret=$(echo "${DBJOBS_SQL[${jobname}]}" | $MYSQL_BIN ...)
```

Bash evaluates a subscript as an arithmetic expression, in which a bare word is
read as a variable name and an unset variable is 0. So `--job prune` does not
fail — it runs **job 0**, whatever that happens to be, and reports success.

These jobs exist to delete rows. Running the wrong one because of a typo, while
being told it worked, is the worst available outcome. (A value containing a
space errors instead, which is louder; the dangerous case is the single word
that looks like a name.)

Fixed together with D91 by a digits-only `case` guard ahead of the subscript,
so the value is rejected before bash can evaluate it arithmetically.

### D91 — an out-of-range `--job` index reports success for a job that does not exist ✅ FIXED 2026-09-16

`--job 99` yields an empty `DBJOBS_SQL[99]`, so the script pipes an empty string
to the client, which exits 0. `940` then reports `9401` — "Job:  run ok:
returns:" — with a blank name, for a job that was never configured and never
ran. There was no bounds check against `${#DBJOBS_SQL[@]}`, which the script
already uses for its own loop.

Both fixed with a new `ERRNO[3]` / `DESCR[3]` rather than by reusing `ERRNO[2]`:
"the job ran and failed" and "you asked for a job that does not exist" are
different events, and conflating them is the habit behind D74 (`908` sharing a
code between a delete and a no-op) and D79 (`909` reporting success for
everything). `NO_OF_ERR` went 2 → 3.

D92 was **not** taken in the same change and remains open — the `help` builtin
call is untouched, and its xfail stands.

### D92 — a `getopt` failure calls bash's `help` builtin and does not exit ✅ FIXED 2026-09-16

```bash
if [ $? != 0 ] ; then help ; fi
```

`help` is the **bash builtin**, not the script's own `schelp` — no `help`
function is defined anywhere in the tree. A bad option therefore prints bash's
builtin help text rather than the script's usage, and with no `exit` the script
carries on with no arguments and runs **every** configured job. Same family as
D44 in `sc_33`, and worse here: mistyping the option that selects one pruning
job runs all of them.

### Suite landed

`test_940_mariadb_jobs.py` — 13 passed, 1 xfailed after the D90/D91 fixes
(11 passed, 3 xfailed as first written). REAL-SVC against
`mariadb:11`, with a job that really deletes a row so the SQL is proven to have
executed rather than merely reported.

Two bugs were mine, not the script's: the test config generator wrapped values
in single quotes while the SQL itself contained them, turning `fingerprint='bb'`
into the unknown column `bb`; and the first D90 test passed a two-word value,
which bash rejects with a syntax error rather than silently resolving to 0.

## 2026-09-16 — D82 partly fixed, `925` and `926` repaired

### D82 — `900` and `901` no longer hang ✅ FIXED 2026-09-16 (`902` still open)

```diff
-getopt --options "hsvc" --long "help,screen,verbose,cert"
+getopt --options "hsvc:" --long "help,screen,verbose,cert:"
```

Verified: the option loop now terminates and `CERTFILE` receives the path
instead of the `--` separator. Previously both spun forever (exit 124 under a
timeout).

`902` was fixed on 2026-09-17 with the same one-character change.

### `925_publish_crl_from_file` converted to named options ✅ FIXED 2026-09-16

```diff
-	$SYSCHECK_HOME/related-enabled/906_ssh-copy-to-remote-machine.sh -s $CRLFILE $CRLHOST $SSHSERVER_DIR $SSHUSER $SSHKEY
+	$SYSCHECK_HOME/related-available/906_ssh-copy-to-remote-machine.sh -s --file="$CRLFILE" --host="$CRLHOST" --dir="$SSHSERVER_DIR" --user="$SSHUSER" --key="$SSHKEY"
```

Two further changes in the same file, both the same class of defect:

- `-c` was matched by the case arm but never declared to `getopt`
  (`--options "hsv"`), so only the long `--crlfile` worked. Now `"hsvc:"`.
- `SCRIPTINDEX` was never incremented, so every host reported under the same
  monitoring key. Now advanced once per `VERIFY_HOST`.

The path also moved from `related-enabled/` to `related-available/`, matching
`916` and `917`: the former requires `906` to have been symlinked in, and
nothing in `925` checks that it was.

### `926_local_htmf_copy_conf` repaired ✅ FIXED 2026-09-16

- `if [ !- d ${BACKUP_DIR} ]` → `if [ ! -d "${BACKUP_DIR}" ]`. The typo made
  `test` fail with "binary operator expected" and return 2, so the branch was
  never taken and a missing `BACKUP_DIR` was never created — every subsequent
  `cp` then failed.
- `-b` and `-r` were matched by case arms but never declared to `getopt`
  (`--options "hsv"`), so only the long forms worked. Now `"hsvbr"`.
- Two `printlogmess` calls had argument-flag errors: one passed
  `"${BACKUP_DIR}"` with no `-1`, the other used `-2` where `DESCR[1]` has a
  single placeholder. Same family as D77 in `917`.
- `SCRIPTINDEX` was never incremented; now advanced once per file.

**Not changed, and worth a decision:** with no options at all, `BACKUP` is empty
and the `else` branch runs — so `926` invoked bare **restores from backup over
the live configuration**. Defaulting a backup/restore tool to restore is the
dangerous way round, but changing it alters behaviour rather than fixing a
defect.

### D92 — closed ✅ FIXED 2026-09-16

Fixed in two steps. `help` → `schelp` addressed the wrong-function half, but
`schelp` only prints and returns (which is why the `-h` arms all read
`schelp;exit;`), so a bad option still fell through and ran every job. The
missing `exit 1` completed it. `test_940_mariadb_jobs.py` is now 14 passed, 0
xfailed.

### The `schelp` pattern is tree-wide ❌ OPEN — needs a decision

D92 was not a `940` bug. **35 sites across 34 scripts** carry

```bash
if [ $? != 0 ] ; then schelp ; fi
```

with no `exit`, so a mistyped option prints usage and then runs the script with
no arguments. Only 5 sites exit. The 40 `-h|--help` arms are fine — they all
spell it `schelp;exit;`, which is itself the evidence that `schelp` was never
expected to exit on its own.

Two ways to close it:

1. **Sweep the 35 call sites** to `schelp ; exit 1`. Explicit, gives a correct
   non-zero exit code, matches the 5 sites that already do this, touches no
   shared code.
2. **Make `schelp` exit**, ending it with `exit "${1:-0}"`. One line, but a bare
   `schelp` on an option *error* would then exit 0 unless each error site is
   also changed to `schelp 1` — which is option 1 again, plus a change to a
   function used at 89 sites.

Option 1 is recommended.

## 2026-09-16 — `904` / `920`, the backup→restore pair

### D98 — a second backup in the same second destroys the first ✅ FIXED 2026-09-18

Three individually-correct behaviours combine into data loss in `904`:

1. `DATESTING` is `%Y-%m-%d_%H.%M.%S`, so two runs within the same second build
   the **same** `MYSQLBACKUPFULLFILENAME`.
2. `initscript` sets `noclobber` (`lib/libsyscheck.sh:56`), so the second run's
   `| gzip -c > "$MYSQLBACKUPFULLFILENAME"` fails with "cannot overwrite
   existing file".
3. `set -o pipefail` correctly notices, and the failure branch runs
   `rm -f -- "$MYSQLBACKUPFULLFILENAME"` to clear a half-written file — but the
   file it deletes is the **previous run's complete, valid backup**.

The operator is left with one error message and zero backups where they had
one. The `rm` is right in the ordinary case and wrong here, because the redirect
failed before writing anything and there is no partial file to clean up.

Reachable in practice: `920` takes a safety backup of the same database
immediately before restoring it. Found because the `920` suite tripped it — its
tests took a backup and then restored it in the same second, and the file
vanished.

Guarding the `rm` on the file having been created by this run, using `>|`, or
giving `DATESTING` sub-second resolution would each break the chain.

### D94 — `920`'s short `-b` hangs ✅ FIXED 2026-09-17

`--options "hsvb" --long "...,backupfile:"` — colon on the long form, none on
the short. `-b /path` therefore hung exactly as D82 did in `900`/`901`/`902`.
The long `--backupfile=` was unaffected, which is why the suite could run.
Fixed with `"hsvb:"`.

### D95 — `920`'s confirmation phrase cannot be typed ✅ FIXED 2026-09-17

It printed `enter 'im-really-sure' (without the '-')`, which yields
`imreallysure`, then tested `[ "x$a" != "xim really sure" ]` — words separated by
**spaces**. An operator following the printed instruction exactly could never
proceed. It failed safe, but the one documented way to use a disaster-recovery
tool did not work, which is discovered during a disaster.

Fixed by making the prompt state exactly what the check wants. Changing the
check instead would have been equally valid but silently alters a contract an
operator may have memorised. The test now reads the phrase out of the script's
own prompt and answers with it, so the two cannot drift apart again.

`lang/920.english`'s top-level `HELP` was corrected at the same time: it
documented a positional `$0 <gzip:ed mysqldump-file>` while the script has taken
`--backupfile` for some time.

### D96 — `920`'s restore messages report `--` ✅ FIXED 2026-09-17

Both outcome branches pass `-1 "$1"`. After the `getopt` loop breaks on `--`,
`$1` *is* `--`; the path is in `$BACKUPFILE`. A successful restore logs
"Restored the db from file (--)". The failure branch fills `DESCR[3]`'s
"consider to restore to previously db (%s)" with the file just restored *from*
rather than the safety backup just taken, which is the one an operator needs.

### D97 — `920`'s missing-file guard reports nothing ✅ FIXED 2026-09-17

```bash
printlogmess -n ${SCRIPTNAME} -i ${SCRIPTID} -x ${SCRIPTINDEX} -l $ERROR -d ${DESCR[4]}
```

`NO_OF_ERR=3` and `lang/920.english` defines only `DESCR[1..3]`, so `${DESCR[4]}`
is empty; there is no `-e`, so no error number; and it is unquoted.
`printlogmess` rejected the call on its own missing-description guard, so `920`
run with no arguments reported nothing at all. `NO_OF_ERR` is now 4 and
`DESCR[4]`/`HELP[4]` exist, matching what `940` and `929` were given for the
same shape of problem.

### D93 — withdrawn, not a defect ℹ️

`904`'s missing-directory guard passes `${SCRIPTNAME} ${SCRIPTID}
${SCRIPTINDEX}` as bare positional arguments with no `-n`/`-i`/`-x`. I recorded
this as a defect and the test **xpassed**, which was correct: `printlogmess` is
a sourced shell function whose `case` arms assign those three variables without
declaring them `local`, so they are the caller's own globals and are already
set. No information is lost.

Kept as a passing test documenting why, because it is fragile rather than
wrong — the day `printlogmess` makes those variables `local`, this single call
site starts failing while every other one keeps working.

### Suites landed

`test_904_make_mysql_db_backup.py` — 21 passed, 1 xfailed.
`test_920_restore_mysql_db_from_backup.py` — 15 passed, 0 xfailed.

Together they prove a real round trip: rows dumped by the real `mysqldump`,
deleted, restored by `920`, and read back.

## 2026-09-16 — mysql group completed

### D99 — `922` emits no messages at all ✅ FIXED 2026-09-17

All four `printlogmess` calls are spelled

```bash
printlogmess -n ${SCRIPTNAME} -i ${SCRIPTID} -x ${SCRIPTINDEX}  $LEVEL_1 ${ERRNO[1]} -d "${DESCR[1]}"
```

`$LEVEL_1`..`$LEVEL_4` **are** defined — in `lang/922.english`, holding the right
values (`LEVEL_1=$INFO`, `LEVEL_4=$ERROR`). The fault is that they are passed
positionally with no `-l`, and `${ERRNO[N]}` likewise with no `-e`.
`printlogmess` binds neither and rejects the call:

```
printlogmess: bad level (-l) '', expected I, W or E
```

So `922` reports nothing in any of its four branches. Like `914` before it was
deleted, enabling it buys no monitoring — and unlike `914` it fails loudly to
stderr, where nothing is reading. The trailing `"$valhost1" "$valhost2"` are
positional too, so the `%s` placeholders could not fill even if the call landed.

*(I first recorded this as "`LEVEL_N` is undefined". That was wrong — my grep
covered `config/` and `lib/` but not `lang/`. The effect is identical; the
mechanism is a missing flag, not a missing variable.)*

### D100 — `938`'s full backup always logs a spurious error ❌ OPEN

`mariabackup_full_backup` guards on `$1` being empty, but the dispatch calls it
with no argument. `ERRNO[1]`, "no name for fullbackup sent", is therefore logged
on **every** run; the guard does not `exit`, so the backup proceeds and a
healthy run emits one permanent error followed by a success. `FULL_BACKUP_NAME`
is never used again, so the parameter looks vestigial.

### D101 — `938` passes `DESCR[2]` unquoted ✅ FIXED 2026-09-17

`-d ${DESCR[2]}` word-splits "Mariadb full backup dir already exist" so `-d`
takes only `Mariadb`. Every other call in the file quotes its description.

### D102 — `936` never loads `mariadb.conf` 🗑 SCRIPT DELETED

`936` makes no `getconfig "mariadb"` call, and `config/related-scripts.conf`
sources only `common.conf`, `libsyscheck.sh` and `printlogmess.sh`. So
`MYSQL_BIN`, `DB_NAME`, `DB_USER` and `DB_PASSWORD` are all unset and all
unquoted, and the command collapses to its literal flags — the shell then tries
to execute `-h`. `936` has never opened a console. Same root cause as D38 in
`sc_40`.

### D103 — `931` latches its cleanup flag off ✅ FIXED 2026-09-18

`FILETRANS=1` was set once, above the loop over files. A failed transfer set it
to 0 and nothing reset it, so the first failure suppressed cleanup for every
later file in that run — including ones that reached every host, leaving the
staging directory to grow until someone noticed.

Fixed by resetting the flag at the top of each file's iteration. The assignment
inside the `SHARED_STORAGE` branch stays: there it deliberately recovers from an
earlier host's failure, because one copy to shared storage is enough.

### D104 — `931` ships its own log offsite ✅ FIXED 2026-09-18

`[ "x${TRANSFERFILENAME}" = "xencback.log" ]` compared a full path from `find`
against a bare filename, so the skip never fired: `encback.log` was transferred
to every backup host and then deleted locally. Fixed with `basename`, matching
how `906` does the same job.

The cleanup `rm` also gained a `[ -f ... ]` guard. Nothing in `931` guarantees
the file is still there — the encryption step writes into the same directory the
loop is walking, and `find` captured its list before any of that ran — so a run
that actually succeeded could print an `rm` error.

Two further changes went in with these:

* `DESCR[1]` and `DESCR[4]` each carried one placeholder and received only the
  filename, so with several backup hosts configured nothing but the index
  distinguished which one had failed. Both now take a second placeholder and the
  calls pass `${BACKUP_HOST[$i]}`.
* The `906` call moved from `related-enabled/` to `related-available/`, as
  `905`, `919` and `925` did — it no longer depends on the helper having been
  symlinked rather than merely installed.

That path change moved the suite's seam too: the stub `906` is now written over
the real one in `related-available/`, which is safe because that tree is in the
harness's `MUTABLE_TREES` and `reset()` restores it from `/src` before every
test.

`test_931_mysql_backup_encrypt_send.py` is 15 passed, 0 xfailed.

### D105 — `931` writes `$ERRNO[2]` without braces ✅ FIXED 2026-09-17

`-e $ERRNO[2]` is `$ERRNO` — element 0, unset — followed by the literal `[2]`.
The backup-failure message carries the error number `[2]` instead of `9312`, and
`DESCR[2]`'s `(%s)` is passed nothing.

### D106 / D107 — `937`'s options are broken in both directions 🗑 SCRIPT DELETED

It **handles** `-b|--batch`, `-m|--menu`, `-q|--quiet` but declares none of them
to `getopt`, which rejects them; the failure branch has no `exit`, so `937` runs
anyway with no arguments. And it **declares** `cert` with no matching case arm,
so `--cert` is accepted, matches nothing, is never shifted, and loops forever —
D82's end state reached from the opposite mistake.

### D108 — `937` reports nothing 🗑 SCRIPT DELETED

`Sub_Error` is the single reporting path for all ten error codes and calls
`printlogmess` entirely positionally — no `-n`, `-i`, `-x`, `-l`, `-e` or `-d`.
Rejected on every invocation. Same as D99. `lang/937.english` defines eleven
descriptions that can never be printed.

### D109 — `937` cannot run twice 🗑 SCRIPT DELETED

`var/937.sql` and `var/937.out` are fixed names written with a plain `>` and
never cleaned up, so `noclobber` blocks every run after the first. D85 again,
which `933` fixed with `set +o noclobber`.

### Suites landed

| Script | Result |
| ------ | ------ |
| `922`  | 8 passed (after D99) |
| `931`  | 11 passed, 3 xfailed |
| `936`  | 3 passed, 4 xfailed |
| `937`  | 4 passed, 4 xfailed |
| `938`  | 10 passed, 2 xfailed |

Two suites needed restructuring after their first run contradicted my reading:
`922`'s branch tests now assert against the rejected-call diagnostic on stderr,
since no messages exist to assert on; and D103 in `931` only latches **within**
one run, so driving it through two invocations xpassed until the stub was
changed to fail only its first call.

## 2026-09-16 — six scripts deleted 🗑

`926_local_htmf_copy_conf`, `928_check_dsm_backup`, `935_mysql_console_as_root`,
`936_mysql_console_as_db_user` and `937_delete_old_CRLData` were removed at the
maintainer's direction, with their configs, language files, ansible entries and
`docs/related-scripts.md` sections. The suites for `936` and `937` went with
them.

The findings recorded above stand as the record of why. In particular:

- **`936`** had never worked at all (D102): it made no `getconfig "mariadb"`
  call, so every connection variable was unset and the shell ended up trying to
  execute `-h`.
- **`937`** could not be invoked as documented (D106/D107), reported nothing
  through any of its ten error codes (D108), and could not run twice (D109).
- **`926`** had been repaired earlier the same day — the `[ !- d ]` typo, the
  undeclared `-b`/`-r`, two `printlogmess` flag errors and the missing index
  increment. Those fixes are moot now.

Two cross-references were updated rather than left dangling: `test_927`'s
docstring cited `926` as a sibling example of the `-2`-without-`-1` mistake, and
item **#21** in `BUGFIXES_AND_IMPROVEMENTS.md` (hard-coded `/backup/mysql/` in
`937`) is now marked 🗑 MOOT.

`903_make_hsm_backup` was deleted immediately afterwards, emptying the HSM
backup group. It had no suite and was never examined here.

Phase 4 is 34 scripts, 15 covered.

## 2026-09-16 — ssh/remote group completed

New harness capability: **`start_sshd_node`** in `syscheck_harness.py`, plus a
session-scoped `sshd_node` fixture in `conftest.py`. It runs a key-only `sshd`
built from the syscheck image — so the far end has the same coreutils the
scripts assume when they send `df --block-size=M` or `mktemp -p` across — with a
keypair generated inside the syscheck container and its public half installed on
the remote. `openssh-server` and `rsync` were added to `Dockerfile.syscheck`.

Two wrinkles worth recording: Debian already ships a user named `backup`, so the
remote account is `syscheckbak`; and readiness is probed with bash's
`/dev/tcp/127.0.0.1/22` because neither `ss` nor `netstat` is in the image.

### D110 — `915` reports a missing `--user` as "Command not found" ✅ FIXED 2026-09-18

The `SSHCMD` and `SSHTOUSER` guards both use `ERRNO[3]`/`DESCR[3]`, so omitting
the user names the wrong argument. All four of `915`'s codes are in use, so
fixing it properly needs a fifth.

### D111 — `915`'s success message drops the command ✅ FIXED 2026-09-18

`DESCR[1]` has one placeholder; the call passes `-1 user -2 host -3 command`. The
`%s` takes the *user*, so the audit line for every remote operation in the tree
records that someone ran something, somewhere.

### D112 — `918` greps for a log format the tree no longer ships 🗑 SCRIPT DELETED

`918` searches syslog for `1903`, which is `${SCRIPTID}${ERRNO}` — the shape
`printlogmess` produces only in **OLDFMT**. `config/common.conf` ships
`SENDTOSYSLOG_OUTPUTTYPE="NEWFMT"`, which writes `19-01-I-03-PKI`. The grep never
matches, so **every monitored host is reported as having failed to call in**.

### D113 — `918` reports a dead host as healthy 🗑 SCRIPT DELETED

When the grep *does* match, `awk '{print $7,$8}'` yields syscheck's
`%Y%m%d %H:%M:%S` stamp, which is then compared against a `%b %d %H:%M:%S`
"now" with `--noyearnotz`. `cmp_dates.py` produces no output and exits 1, so
`MINUTES_SINCE_LASTLOG` is empty, both `[ "" -gt N ]` tests error out, and
control falls through to the healthy branch.

So on NEWFMT a live machine reads as dead, and on OLDFMT a dead machine reads as
alive. `918` has no configuration in which it answers correctly.

### D114 — `918`'s warning tier is unreachable 🗑 SCRIPT DELETED

The warn branch omits `-l` and `-e`, so `printlogmess` rejects it. The error and
info branches on either side are spelled correctly. Same as D99 in `922`.

### D115 / D123 — `918` and `924` never increment `SCRIPTINDEX` 🗑 BOTH SCRIPTS DELETED

Every host or path reports under one monitoring key. Worse in `918` than in
`916`, since watching several machines is the entire point of the script.

### D116 — `930`'s failure message discards its own diagnosis ✅ FIXED 2026-09-18

The failure branch passed `-2` and `-3` with no `-1`, so `DESCR[2]`'s first
placeholder was blank and the filename landed in the "result" slot. The
carefully assembled detail naming host, directory, user, key and `906`'s output
went in `-3`, which `DESCR[2]` had no placeholder for at all — built, then
discarded.

`DESCR[2]` now carries file, host and result. Dir, user and key were dropped
from the detail rather than given placeholders: they are all in the config
already, so echoing them back adds length without information, while the host is
what distinguishes one configured destination from another.

Two changes went in alongside:

* `DESCR[1]` gained the host too. The success branch was correctly wired, but
  `930`'s whole purpose is shipping to several monitoring hosts and a success
  could not say which one took the file either.
* The `906` call moved from `related-enabled/` to `related-available/`, as
  `905`, `919`, `925` and `931` did. The suite's stub seam moved with it — the
  fixture used to symlink the real `906` into `related-enabled/` and now simply
  writes over it in `related-available/`, which `reset()` restores per test.

`test_930_send_filtered_result_to_remote_machine.py` is 11 passed, 0 xfailed.

### D117 — `907`'s messages name neither file nor host ❌ OPEN

Both outcome calls pass no arguments, though `DESCR[3]` has a placeholder. With
several backup hosts configured the log says a transfer failed but not which.

### D118–D121 — `923` cannot transfer anything 🗑 SCRIPT DELETED

Four independent faults between the command line and the `rsync` call:

* **D118** — the `else` branch of the `FILES` guard overwrites it with `$1`,
  which is the `--` separator. `FILES` is therefore either empty (exit) or `--`.
* **D119** — `-d|--dir` has a case arm but is declared to neither `--options`
  nor `--long`, so `getopt` rejects it; and it assigns `SSHTODIR` while the
  `rsync` line reads `${SSHDIR}`, which is never set.
* **D120** — the transport is built as `-e "ssh ${SSHFROMKEY} ${SSHTOUSER}"`,
  with no `-i` or `-l`. `915` gets the equivalent line right.
  `config/923.conf`'s `SSH_OPTIONS` is never read.
* **D121** — the failure message passes `"$runresult"` positionally, so
  `DESCR[4]`'s `%s` never fills and rsync's diagnosis is discarded.

### D122 — `924` calls `923` positionally 🗑 SCRIPT DELETED

`923` takes named options only. The same defect that had `913` and `921`
deleted, and D56 in `sc_28` before them. `924` differs only in checking that the
helper exists first, which makes the failure look like a working call. It is
moot until D118–D120 are fixed, since `923` cannot transfer regardless.

### D124 — `924`'s outcome messages pass their detail positionally 🗑 SCRIPT DELETED

No `-1` on either branch, so `DESCR[3]`'s placeholder never fills. `DESCR[1]`
has no placeholder at all.

### Suites landed

| Script | Result |
| ------ | ------ |
| `906`  | 14 passed |
| `907`  | 11 passed, 1 xfailed |
| `915`  | 12 passed, 2 xfailed |
| `930`  | 9 passed, 2 xfailed |

`906` and `915` are genuinely healthy — real sftp, real checksums, real key
authentication, and every guard reachable. They are also the two everything else
delegates to, which is the reassuring part.

**`923-rsync-to-remote-machine.sh` and
`924-backup-this-machine-to-remote-machine.sh` were deleted on 2026-09-16**,
with their suites. `923` had four independent faults between its command line
and its `rsync` call (D118-D121) and could not transfer anything; `924` did
nothing but call `923` positionally (D122). Two references in
`BUGFIXES_AND_IMPROVEMENTS.md` — the quoting sweep count and item #5's site
list — were annotated rather than rewritten, since they record work that was
really done at the time.

**`918_server_alive.sh` was deleted on 2026-09-16**, with its suite. D112 and
D113 together meant it had no configuration in which it answered correctly: on
the shipped NEWFMT it reported every live host as dead, and on OLDFMT it
reported every dead host as alive. Three docstring cross-references in
`conftest.py`, `test_924` and `test_930` were updated rather than left dangling.

One characterisation worth noting in `906`: its `[ ! -r "$SSHFILE" ]` guard can
never fire, because syscheck runs as **root** and root satisfies `-r` on a
mode-000 file. The transfer still fails, but as a hash mismatch (`9066`) rather
than a bad-input error (`9062`), so the message names the wrong thing.

## 2026-09-17 — EJBCA group completed

### D125 / D126 — `900` and `901` describe failures with each other's text ✅ FIXED 2026-09-17

The twins disagree in mirror image. `900` uses `ERRNO[3]` at six call sites,
`ERRNO[1]` at one, and **`ERRNO[2]` nowhere** — so every failure, including a
corrupt certificate, is reported with `DESCR[3]`, "script called without file".
`901` does the opposite: its missing-file guard uses `ERRNO[2]`/`DESCR[2]`,
"Export revocation failed (%s)", while `DESCR[3]` — the text that fits — is used
for everything else.

Between them neither ever prints the right text, and being wrong in opposite
directions is the strongest evidence they were copied from one another and
edited independently.

The unused `DESCR[2]` in `900` is also the only description carrying a
placeholder, which makes the `-1 "$?"` on every call moot twice over: `$?` is
expanded *inside* the branch, where the last command is the `[` test that
returned 0 to enter it, so the value is always the literal `0` — and it is never
rendered anyway.

Not a defect, recorded as a passing test: both read `$?` after
`openssl … | sed`, which is **sed's** status, so those guards cannot fire. No
failure is missed, because the un-piped `CERT=`openssl x509 …`` a few lines
later catches the same condition — only the attribution is lost.

### D127 — `925`'s outcome messages drop the host and file ✅ FIXED 2026-09-17

Both branches pass `-1 "$CRLHOST" -2 "$CRLFILE"` correctly, but `DESCR[1]`
("Publish crl run successfully") and `DESCR[4]` ("scp script failed") carry no
`%s` at all. The inverse of the usual fault here: the call site is right and the
language file is short.

### D128 — `919` parses its options twice and the first pass discards `--cert` ✅ FIXED 2026-09-17 (by the maintainer)

`919` contains the whole `getopt` block twice. The first declares only
`help,screen,verbose`; the second adds `cert:`. The first therefore rejects
`--cert` as unrecognised and prints only the remainder:

```
first getopt stdout: < -- '/tmp/919/cert.der'>
```

`eval set --` replaced the argument list with that, so the second block — the
one that would understand the option — found nothing. `CERTFILE` was never
assigned and the `! -r ""` guard exited. The duplicate block was a leftover and
deleting it was the fix. D129 and D130 remain open.

### D129 — `919` calls `915` positionally ✅ FIXED 2026-09-18

The fifth script found calling a named-option helper positionally, after `913`,
`921`, `923`/`924` and `905`.

### D130 — `919` never reports what it exists to do ✅ FIXED 2026-09-18

`ERRNO[3]` at seven sites, `ERRNO[4]` at one, and `ERRNO[1]`/`ERRNO[2]` — "Remote
command ran successfully" and "Remote command failed" — **nowhere**. The `915`
call's exit status is never checked. Every message `919` can emit is about
reading the certificate. `SCRIPTINDEX` is never incremented either.

### D131 — `905` writes `"$DESCR[N]"` unbraced at eight of seventeen call sites ✅ FIXED 2026-09-17

Nine calls use `"${DESCR[N]}"` and eight use `"$DESCR[N]"`, which is `$DESCR`
(element 0, unset) followed by the literal `[N]`. Same as D77 in `917`, where
every call was affected; here roughly half are, which reads like an abandoned
partial edit.

All eight braced. Asserted against the source rather than against messages,
because every affected call site sits past the validity check — until D133 was
fixed none of them could be reached at runtime at all, and a source check keeps
the guarantee whole rather than covering only the branches the suite drives.

### D132 — `905` calls `906` positionally ✅ FIXED 2026-09-17

`put()` passed `-s $CRLFILE $REMOTEHOST $REMOTEDIR $SSHUSER $SSHKEY`. `925` had
exactly this and was converted on 2026-09-16; `905` got the same treatment, and
its path moved from `related-enabled/` to `related-available/` at the same time
so it no longer depends on `906` having been enabled.

Verified against a real sshd rather than an unreachable host, so a pass cannot
come from the connection failing for some other reason. `test_905_publish_crl.py`
is now 14 passed, 0 xfailed.

### D133 — `905` can never publish a CRL ✅ FIXED 2026-09-17

The one that matters. `checkcrl` reads the CRL's dates with

```bash
LASTUPDATE=$(openssl crl -inform der -in $outname -lastupdate -noout | ...)
NEXTUPDATE=$(openssl crl -inform der -in $outname -nextupdate -noout | ...)
```

but **`outname` is never assigned anywhere in `905`**. It is a leftover from
`sc_08_crl_from_webserver.sh`, which does define it; `905` uses `CRLFILE` for
the same thing everywhere else, including the `! -f` and `stat` guards on the
lines immediately above.

Unquoted and empty, `-in $outname` collapses and openssl reads the next argument
as its input file:

```
Could not open file or uri for loading CRL from -lastupdate
```

Both dates come back empty, `cmp_dates.py` raises on `''`, the CRL is graded
unparseable, `checkcrl` returns non-zero and the loop `continue`s. **No CRL was
ever published, by any route.** That is the entire purpose of the script.

Fixed by reading `"$CRLFILE"` — the name the rest of `checkcrl` already uses —
and by making both parse guards `return 7` instead of falling through. The
fall-through was a second, hidden bug: with empty dates `cmp_dates.py` was still
invoked and died with a Python traceback on stderr.

A **DER-then-PEM fallback** was added at the same time, in a small `crlfield`
helper. EJBCA's `ca getcrl` writes DER, so that is still tried first, but a CRL
placed by hand or fetched from a web server is commonly PEM and previously
failed the check with "Cant parse file" and was silently never published. The
two formats are indistinguishable by filename, so trying both is cheaper than
making the operator declare which they have. Garbage still fails both attempts
and stops the run, which is pinned by its own test.

`test_905_publish_crl.py` is now 12 passed, 2 xfailed — D131 and D132 remain.

### Suites landed

| Script | Result |
| ------ | ------ |
| `900`  | 13 passed |
| `901`  | 12 passed |
| `905`  | 14 passed (after D131/D132/D133) |
| `919`  | 5 passed, 2 xfailed |
| `925`  | 12 passed, 1 xfailed |

`905` publishes for the first time as of the D133 fix; `925` is otherwise the
healthy one, and only because it was repaired on 2026-09-16 — its
suite confirms the named-option conversion works end to end against a real
sshd. `900` and `901` work as of the D82 colon fix. `905` and `919` do not work
at all.

## 2026-09-17 — VIP group completed

FAKE-BIN for `ifconfig`, `route`, `ping` and `arping`. Real ones would need
NET_ADMIN and a second host to fail over from, and every branch in both scripts
turns on what those four commands *say* rather than on the kernel actually
reconfiguring — so the stubs sit exactly at the decision points. Each records
its argv, which is how the tests distinguish "reported success" from "actually
reconfigured the interface". That distinction is the whole of D134.

### D134 — `911` never configures the interface ✅ FIXED 2026-09-17

The line that should bring the VIP up is

```bash
res=($IFCONFIG ${IF_VIRTUAL} inet ${HOSTNAME_VIRTUAL} netmask ${NETMASK_VIRTUAL} up)
```

`res=(...)` is bash **array assignment**, not command substitution. The words are
stored in `res` and `ifconfig` is never executed. `$?` is then the status of the
assignment — always 0 — so the guard below never fires, and `911` goes on to
write `var/this_node_has_the_vip` and report `ERRNO[1]`, "Activate VIP run
successfully".

**`911` claims the VIP on every run without ever configuring it.** For a
failover script that is the worst available shape of failure: the cluster
believes the address moved, the marker file agrees, monitoring is green, and the
address is up nowhere. Measured directly — the fake `ifconfig` records no `up`
call.

Fixed to `res=$(...)`, with `2>&1` added so `ifconfig`'s own complaint reaches
`DESCR[2]`'s placeholder — the guard passes `-1 "$res"` and without the
redirect it filled with empty stdout. Line 62 was the only one of four `res=`
assignments in the script written without the `$`; the other three already used
command substitution, which is what makes it a typo rather than an intention.

The fix also made the failure guard **reachable for the first time** — until
now `$?` was the array assignment's status, so `ERRNO[2]` could not fire
whatever the interface did. Three tests now cover that path: a failing
`ifconfig` reports `9112`, writes no marker file, and sends no gratuitous ARP.
The marker one matters most — writing it after a failed activation is how two
nodes end up both believing they hold the VIP.

### D135 — `911`'s failed-ARP branch is unreachable ✅ FIXED 2026-09-17

```bash
printlogmess ... -x ${SCRIPTINDEX}  $WARN ${ERRNO[6]} -d "${DESCR[6]}" -1 "$res"
```

No `-l`, no `-e`, so `printlogmess` rejects the call. The success branch
immediately below is spelled correctly. A router that does not answer the
gratuitous ARP — VIP up locally but unreachable from the network — is exactly
what this branch exists to surface, and it is the one outcome that produces no
message at all. Same as D114 in the deleted `918` and D99 in `922`.

### D136 — all three of `912`'s messages print as `[N]` ✅ FIXED 2026-09-17

Every call writes `-d "$DESCR[N]"` unbraced: `$DESCR` (element 0, unset)
followed by the literal `[N]`. `911`, the other half of the pair, braces all six
of its references. Same as D131 in `905`, fixed 2026-09-17, and D77 in `917`.

The two `-1 "$?"` arguments are moot alongside it — `$?` is expanded inside the
branch where the `[` test just returned 0, so the value is always the literal
`0`, and `DESCR[1]` has no placeholder anyway.

### The noclobber fix is now covered

`911`'s marker write was fixed blind on 2026-09-16 (D85 family) with
`set +o noclobber`, with no suite to prove it. `test_the_marker_file_is_rewritten_on_a_later_activation`
now does: two activations a second apart must leave different timestamps. It
passes.

### Suites landed

| Script | Result |
| ------ | ------ |
| `911`  | 16 passed, 1 xfailed (after D134) |
| `912`  | 10 passed, 1 xfailed |

`test_activate_then_deactivate_leaves_no_marker` drives both in sequence, since
they are the only two places in the tree that touch
`var/this_node_has_the_vip` and nothing else checks they agree on the filename.

## 2026-09-17 — syscheck plumbing group completed

`929` and `932` are syscheck's outbound layer, around `var/last_status`:

```
checks -> var/last_status
             |- 929 filters -> var/last_status_filtered -> 930 ships to monitoring hosts
             `- 932 sends the whole file via a vendor message command
```

### D137 — `929` works exactly once ✅ FIXED 2026-09-17

`egrep ... > ${FILTERED_FILE}` is a plain redirect to a fixed path, and
`initscript` sets `noclobber`. Measured: first run `rc=0`, second
`cannot overwrite existing file`.

Every run after the first reports `ERRNO[2]` and leaves the **first** run's file
in place — which `930` then ships onward. A monitoring host receives a snapshot
that may be days old while the local check reports a failure nobody is reading.

Same as D85 in `933` and the marker write in `911`. Those took the one-line
`set +o noclobber`; this one deliberately did not.

A shell redirect truncates its target **before** the command runs, so simply
allowing the overwrite would mean any failed `egrep` — missing `last_status`,
unreadable file — left an *empty* `last_status_filtered` for `930` to ship.
That trades "ships stale data" for "ships empty data", which is worse: stale
data looks wrong to a human, empty data looks like nothing is failing. The
`noclobber` that caused the bug was accidentally protecting against it.

`929` now builds into `mktemp` and `mv`s into place only on success — atomic,
and unaffected by `noclobber` since `mv` is not a redirect. Two tests cover the
property directly: a failed run leaves the previous file byte-identical, and
leaves no temporary behind.

Worth recording: `mktemp` *creates* the file, so the redirect into it needed
`>|` to get past `noclobber` — the same trap one level down, and the same
workaround `sc_20_errors_ejbcalog.sh` uses with `2>|`. The first attempt at this
fix failed eight tests for exactly that reason.

### D138 — `929`'s filter is close to a no-op on real data ✅ FIXED 2026-09-17

The pattern is built as `(01|03|06|17|31)-` and applied unanchored, so it
matches anywhere in the line — including the `SCRIPTINDEX` field immediately
after the script id.

`01` is the index almost every single-instance check reports at, so with the
shipped `SEND_ONLY_SCRIPT_IDS` nearly every line matches whatever its script id.
Measured on an ordinary five-check `last_status`: **all five survived**,
including the two never configured.

So the host that was meant to see disk, memory, RAID, NTP and HP health received
essentially the whole file, silently. Fixed by anchoring the pattern with `^`.

### D139 — `929` reports "nothing matched" as a failure ✅ FIXED 2026-09-17

`egrep` exits 1 when no line matches; `929` grades that `ERRNO[2]`, "Filter
failed". But matching nothing is legitimate — a `last_status` holding only
checks nobody asked to forward. The script cannot distinguish "the filter broke"
from "there was nothing to forward", the same conflation as D74 in `908`. It
matters more here because an empty filtered file is a correct thing for `930` to
ship, and an error is not.

Measured exit codes: **0** matched, **1** no match, **2** a real error. All three
are now graded separately, with a new `ERRNO[3]` for the middle case rather than
folding it into success — an empty result is informational, and worth seeing
when `SEND_ONLY_SCRIPT_IDS` has been mistyped into selecting nothing. `DESCR[3]`
carries the configured id list so that is visible at a glance. `NO_OF_ERR` went
2 to 3.

### D140 — `932` reports a failed send as a success ✅ FIXED 2026-09-17

```bash
SENDRES=$(${SEND_MSG_COMMAND[$j]} -c ... -m ... | tr -d '\n')
if [ $? -ne 0 ] ; then
```

`$?` after a pipeline is the status of its **last** command — `tr`, which always
succeeds. Measured: `false | tr -d "\n"` gives 0. The failure branch is
unreachable and `932` reports `ERRNO[1]`, "Transfer ok", whatever the vendor
tool did.

Same masking as D125 in `900`/`901`, and materially worse: there a later
un-piped call caught the same condition, so no failure was *missed*, only
misattributed. Here there is no second check.

And it was lost in the one place it cannot be afforded. `932` exists to tell a
human the system is unhealthy; a broken notification path that reports itself
healthy is indistinguishable from a healthy system — precisely the state an
operator is trusting it to rule out.

Fixed with `set -o pipefail` inside the command substitution, which scopes it to
that subshell rather than changing the whole script's behaviour. `904` already
uses `pipefail` for this shape of problem.

The tool's own output does still reach the message, so the evidence is in the
log — mislabelled rather than absent. Pinned by its own passing test.

### Suites landed

| Script | Result |
| ------ | ------ |
| `929`  | 14 passed (after D137/D138/D139) |
| `932`  | 11 passed (after D140) |


## 2026-09-17 — `939_delete_old_elastic_index` deleted 🗑

Removed with its config and language file. It had no ansible entry and no
`docs/related-scripts.md` section, so nothing else referenced it — the only
apparent hits were digits inside a nanosecond timestamp in
`docs/output-format.md`.

It was the sole member of the Elasticsearch group, so `elasticsearch:8` is no
longer a dependency of this phase. Phase 4 is 30 scripts, 28 covered; only the
S3 pair (`941`, `942`) remains.

## 2026-09-17 — S3 group completed, Phase 4 finished

Deliberately kept minimal: **FAKE-BIN `curl`**, no MinIO, and the PGP path left
at its shipped default of off so no `gpg` is needed (it is not in the test
image).

**Fidelity gap, stated plainly.** These suites prove the request each script
builds — endpoint, bucket, object key, credentials, signing region — and how it
reports the outcome. They do **not** prove a real S3 accepts that request.
`test/test-s3-backup-restore.bats` has the same limit. A REAL-SVC MinIO upgrade
is still the honest next step and stays recorded in PLAN.md.

### No defects found

`941` and `942` are the best-written pair in `related-available/`, and the only
two scripts in the whole phase whose suites landed with **zero xfails**. They
use arrays for optional arguments, `curl --fail-with-body`, `mktemp` for
transient files, consistent quoting, and — unusually for this tree — they get
their exit-status handling right.

Two properties worth calling out, both of which the rest of the tree gets wrong
somewhere:

* `941` tracks `UPLOADFAILED` across every configured endpoint and removes the
  local backup only if all of them accepted it. Compare `931`, where the
  equivalent flag latches off and never resets (D103).
* `942` refuses to hand anything to `920` when the download failed, so a live
  database is never overwritten from an empty file.

### One thing that looked like a bug and is not

`942`'s fixture initially wrote `config/942.conf` and the S3 settings were
ignored. `942` does `getconfig "941"`, and `config/942.conf` documents this: the
S3 destinations are deliberately shared with the upload side, so a restore
cannot be pointed at a bucket the backups were never written to. `--index`
selects among them. The test now writes `941.conf`.

### Suites landed

| Script | Result |
| ------ | ------ |
| `941`  | 15 passed |
| `942`  | 12 passed |

`942`'s handoff is asserted at the boundary — that `920` was invoked with the
downloaded file — rather than by checking rows came back. The restore itself is
`920`'s behaviour and is covered by its own suite against a real database;
driving it end to end here would mean configuring `904` too, to satisfy `920`'s
safety backup, for no additional guarantee about `942`.

### D96 — the applied patch

Both outcome branches pass `-1 "$1"`, and after the `getopt` loop breaks on `--`
that *is* `--`; the path lives in `$BACKUPFILE`. `DESCR[3]`'s second
placeholder — "consider to restore to previously db (%s)" — receives the file
that just failed rather than the safety backup, so the message tells an operator
to recover using the thing that did not work.

Fixed by capturing the safety backup's name from `904 --batch`:

```bash
# 904 --batch prints the filename it wrote, one line per configured database
SAFETYBACKUP=$($SYSCHECK_HOME/related-available/904_make_mysql_db_backup.sh -s --batch)
SAFETYBACKUPRET=$?
SAFETYBACKUP=$(echo "${SAFETYBACKUP}" | tr '\n' ' ')

if [ "$SAFETYBACKUPRET" -ne 0 ] || [ "x${SAFETYBACKUP}" = "x" ] ; then
	...
	exit 1
fi
```

An earlier draft put `set -o pipefail` inside the command substitution to dodge
the `$?`-after-a-pipe trap (D140). Rejected as too dense: splitting capture,
status and formatting onto separate lines removes the pipe from the captured
expression altogether, so no subshell option is needed and each line does one
thing.

Three things that made this more than a variable rename:

* `-s --batch` together are safe — `printlogmess`'s screen output goes to
  **stderr**, so only `904`'s filename `echo` reaches stdout.
* The empty-string check is the guard that actually bites. `904` does not exit
  non-zero when an individual dump fails, only when its backup directory is
  missing, so `$? -ne 0` catches less than it appears to.
* `exit` → `exit 1` is not cosmetic: a bare `exit` returns the status of the
  preceding `printlogmess`, which succeeds. `942` does `RESTORERET=$?` on
  `920` and propagates it, so an aborted restore reported **success** upstream.
  Covered by `test_an_aborted_safety_backup_exits_non_zero`.

`test_920_restore_mysql_db_from_backup.py` is now **15 passed, 0 xfailed** — all
four of its defects closed. Two tests were added rather than just clearing the
marker: one driving a *failed* restore to prove the safety backup is named in
`DESCR[3]`'s second placeholder, and one on the exit status `942` depends on.


## 2026-09-18 — `915` message wiring, and a test that passed for the wrong reason

D110 and D111 fixed, with three related corrections taken at the same time:

* All three argument guards rendered their `(%s)` empty. Each now names the
  complementary field, so an operator can tell which caller misconfigured.
* `DESCR[4]`, the failure message, carried only the exit number — the message
  someone actually reads during an incident. It now names the host and command.
* `SSHFROMKEY` was passed unquoted as `-i ${SSHFROMKEY}`, so an empty key left
  `-i` to swallow the `-l` that followed it: `ssh -i -l bob h1 true`. Reachable,
  because `915` mandates a user but not a key and `917` treats the key as
  optional. The key is now assembled into an array that is simply absent when
  unset, matching the idiom in `904` and `941`.

`${SSHOPTIONS}` and `${SSHCMD}` deliberately stay unquoted — the first is a
multi-word option string, the second a command ssh rejoins server-side.

`test_915_remote_command_via_ssh.py` is 17 passed, 0 xfailed. The whole ssh
group was re-run behind the key change rather than `915` alone: 74 passed.

### A test that passed for the wrong reason

Clearing D84's marker on `933` exposed that
`test_the_summary_timestamp_records_the_minute` **never ran the script** — it
read `var/db_export_summary` directly, so the xfail was satisfied by a
missing-file error rather than by the timestamp being wrong. It would have gone
on "passing" as an xfail indefinitely.

Worth noting as a hazard of the strict-xfail convention: a marker proves *a*
failure, not the failure you named. This is the second time clearing one has
revealed the test underneath was measuring something else — the first was D103
in `931`, which only latched within a single run.


## 2026-09-18 — the four "reports success while doing nothing" defects

### D79 / D80 — `909` and `910` now decide on the exit status

Both wrote their output to `${SYSCHECK_HOME}/var/$0.output`, where `$0` is the
script's *full path*, so the target was a nested directory that does not exist.
`tee` wrote nothing, the read came back empty, and empty was the success
condition.

Fixing the path alone would have left a worse criterion in place: success meant
*the tool printed nothing*, so any banner or "CA activated" line would have been
reported as a failure. Both now use `mktemp` and take the tool's own exit status
through `${PIPESTATUS[0]}`, keeping the captured output for the message.

`${PIPESTATUS[0]}` rather than `pipefail` because what is wanted is specifically
the **first** element of the pipeline, not "any failure in it".

**This changes what success means** in both scripts, from "silent" to "exited
0". Agreed deliberately rather than discovered later.

`910` additionally never assigned `NAME` — `909` sets `NAME=${CANAME[$i]}` at
the top of its loop and `910` simply did not — so it ran `ca deactivateca` with
no CA at all. `lang/910.english`'s `DESCR[2]` also gained the second placeholder
it was already being passed.

The screen line that read "Deactivating CA … on node $HOSTNAME_NODE2" had its
node reference removed on the same day: `910` runs entirely locally, and
`HOSTNAME_NODE2` now appears nowhere in it.

### D81 — `910` reuses `909`'s CA list

`config/910.conf` claimed the CAs were "defined in common.conf", where `CANAME`
has never been; it lives in `config/909.conf`, which `910` never read. Fixed
with `getconfig "909"`, so activate and deactivate cannot drift apart about
which CAs exist — the same arrangement `942` uses to read `941`'s S3
destinations. The config comment now says so.

This moved the seam in the suite: `test_910_deactivate_cas.py` had been writing
`config/910.conf`, which `getconfig "909"` then overrode with the shipped list.
The fixture now writes `909.conf`, exactly as `test_942_restore_from_s3.py`
writes `941.conf`. Four tests failed on the first run for that reason.

### D98 — `904` refuses rather than cleaning up afterwards

A guard before the dump: if the target filename already exists, report and
`continue`. The existing `rm -f` is correct when a partial file was written and
wrong only when the redirect never opened the file, so guarding up front makes
it correct by construction — no conditional `rm`, no tracking flag.

### Suites

`909` 7 passed, `910` 8 passed, `904` 21 passed — all with no xfails remaining.


## 2026-09-18 — `919` publishes, and a new defect underneath it

### D129 / D130 fixed

The `915` call was positional and is now named, with the path moved from
`related-enabled/` to `related-available/` — `915` defaults to **disabled** in
the ansible role, so the enabled path is the one likely to be missing.

`ERRNO[1]` and `ERRNO[2]` had never been used: `915`'s exit status was not
checked and nothing was logged after it, so the one thing `919` exists to do was
the one thing it never reported. Both branches now fire, `addOneToIndex` runs
once per host (it was called **zero** times), and `lang/919.english` gained the
placeholders the call sites fill.

### D141 — the subject-field extraction truncates at the first dot ✅ FIXED 2026-09-18

Found by the D129 test passing with the wrong value. `919` pulls fields out of
the certificate subject with

```bash
grep -oi 'cn=[[:alnum:][:space:]]*' | sed 's/cn=//gi'
```

`[[:alnum:][:space:]]` covers letters, digits and spaces but **not dots or
hyphens**, so `CN=publisher.example.com` is published as `publisher`. Measured:
the remote host received exactly that.

Hostname CNs almost always contain dots and organisation names routinely contain
hyphens, so this truncates in the common case. `CERTUID` (line 57) and `CERTSN`
(line 67) use the same class and truncate the same way. `CERTDN` does not — it
takes the whole subject and rewrites the punctuation — which is why the `DN`
mode is unaffected.

This was only visible because D129 and D130 were fixed: until the remote call
worked and its result was reported, there was nothing to observe the truncation
with.

Fixed by adding both characters to the class — `[[:alnum:][:space:].-]`, with
the `-` last in the bracket expression so it stays literal rather than opening a
range. All three sites corrected together. Verified: `CN=publisher.example.com`
now publishes intact, and a `serialNumber=SN-123.4` survives too.

`test_919_certpublisher_remotecommand.py` is 10 passed, 0 xfailed.
