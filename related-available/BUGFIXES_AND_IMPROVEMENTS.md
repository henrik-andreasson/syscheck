# Bug Fixes and Improvements for related-available Scripts

## Overview
Analysis of the `related-available/` directory containing 43 helper scripts for system checking, backup, and maintenance operations.

---

## ✅ Verification pass — 2026-09-14

Every item below was re-checked against the current code. Each now carries a
status marker; the severity and priority sections at the end have been rebuilt
around what is actually left.

| Status | Count | Meaning |
| --- | --- | --- |
| ✅ FIXED | 10 | verified absent from the code |
| 🗑 MOOT | 5 | the code they describe was rewritten away |
| ❌ OPEN | 7 | reproduced against current code |
| ⚠️ PARTIAL | 3 | partly addressed |
| ℹ️ NOT A DEFECT | 2 | confirmed correct as written |
| 🔧 NOT ADOPTED | 5 | improvement suggestions, none taken up |

32 items in total: the original 30 plus #31 and #32, both found during
this pass.

**Thirteen issues are resolved; only four said so when this pass began.** Six were fixed silently by
later work — chiefly the `938_mariabackup.sh` rewrite (434 → 96 lines), which
invalidates every line-specific claim against that file, and the rewrites of
`904` and `930`.

**Three factual errors in the original report have been corrected in place:**
#4 named a file that does not exist, #13 named the wrong variable, and #5
understated its own scope fourfold. **One new bug was found while verifying
#22** and is recorded as #31.

---

## 🐛 Critical Bugs

### 1. Missing space in `printlogmess-n` (931_mysql_backup_encrypt_send_to_remote_host.sh:55) ✅ FIXED
**File**: `931_mysql_backup_encrypt_send_to_remote_host.sh`  
**Line**: 55  
**Issue**: `printlogmess-n` should be `printlogmess -n` (missing space after command)
```bash
# Current (WRONG):
printlogmess-n  ${SCRIPTNAME} -i ${SCRIPTID} -x $SCRIPTINDEX -l $ERROR -e $ERRNO[2] -d "$DESCR[2]"

# Should be:
printlogmess -n  ${SCRIPTNAME} -i ${SCRIPTID} -x $SCRIPTINDEX -l $ERROR -e $ERRNO[2] -d "$DESCR[2]"
```
**Impact**: Command will fail with "command not found" error  
**Severity**: CRITICAL - Breaks script execution

### 2. Missing closing bracket in while loop (938_mariabackup.sh:60) 🗑 MOOT — but see #32
**File**: `938_mariabackup.sh`  
**Line**: 60  
**Issue**: Syntax error - missing `}` in variable expansion and missing `]`
```bash
# Current (WRONG):
while [ ${KEEP_GEN -le $(ls -d ${MARIABACKUP_BASEDIR}/* 2>/dev/null|wc -l) ] do

# Should be:
while [ ${KEEP_GEN} -le $(ls -d ${MARIABACKUP_BASEDIR}/* 2>/dev/null|wc -l) ] ; do
```
**Impact**: Script will fail with syntax error  
**Severity**: CRITICAL - Breaks script execution

> **2026-09-14 — 🗑 MOOT for the original code, but the redesign reintroduced
> the fault.** The `while` loop described here is gone: `938` was rewritten in
> `3a5e22c`, from 434 lines to 96. The rewrite, however, shipped a **new**
> syntax error of exactly the same kind, which went unnoticed because this
> entry was marked FIXED. See **#32**.

### 3. Duplicate backup execution (907_make_mysql_db_backup_and_transfer_to_remote_mashine.sh:54-60) ✅ FIXED
**File**: `907_make_mysql_db_backup_and_transfer_to_remote_mashine.sh`  
**Lines**: 54-60  
**Issue**: Backup command is executed twice (lines 54 and 60)
```bash
# Lines 54-56:
FULLFILENAME=`$SYSCHECK_HOME/related-available/904_make_mysql_db_backup.sh --batch ${BACKUPARG}`
if [ $? -ne 0 ] ; then
    printlogmess -n ${SCRIPTNAME} -i ${SCRIPTID} -x ${SCRIPTINDEX} -l $ERROR -e ${ERRNO[2]} -d "${DESCR[2]}"
fi

# Lines 60-62 (DUPLICATE):
FULLFILENAME=`$SYSCHECK_HOME/related-available/904_make_mysql_db_backup.sh --batch ${BACKUPARG}`
if [ $? -ne 0 ] ; then
    printlogmess -n ${SCRIPTNAME} -i ${SCRIPTID} -x ${SCRIPTINDEX} -l $ERROR -e ${ERRNO[2]} -d "${DESCR[2]}"
fi
```
**Impact**: Backup runs twice, wasting time and resources  
**Severity**: HIGH - Performance issue

### 4. Wrong option in getopt (920_restore_mysql_db_from_backup.sh:31) ✅ FIXED
**File**: `920_restore_db.sh`  
**Line**: 31  
**Issue**: Typo `--backupdile` should be `--backupfile`
```bash
# Current (WRONG):
-b|--backupdile ) BACKUPFILE=$2 ; shift 2;;

# Should be:
-b|--backupfile ) BACKUPFILE=$2 ; shift 2;;
```
**Impact**: Command-line option won't work as documented  
**Severity**: HIGH - Feature broken

### 5. Inconsistent exit codes (Multiple files) ✅ FIXED
**Files**: `906_ssh-copy-to-remote-machine.sh`, `915_remote_command_via_ssh.sh`  
**Issue**: Using `exit -1` which is non-standard (valid exit codes: 0-255)
```bash
# Current (WRONG):
exit -1

# Should be:
exit 1
```
**Impact**: Exit code wraps to 255, confusing error handling  
**Severity**: MEDIUM - Breaks error code conventions

> **2026-09-14 — ✅ FIXED.** The original "Files" line above listed two scripts;
> it was actually **23 occurrences across four**:
> `906_ssh-copy-to-remote-machine.sh` (6), `915_remote_command_via_ssh.sh` (3),
> `917_archive_file.sh` (13) and `923-rsync-to-remote-machine.sh` (1, script
> deleted 2026-09-16).
>
> All 23 are now `exit 1`. Verified safe first: no caller anywhere in the tree
> tests for a specific code — every one uses `-eq 0` / `-ne 0` or ignores the
> result — so the change from 255 to 1 alters no control flow. `bash -n` clean
> on all four files, and the diff is 23 insertions / 23 deletions with nothing
> else touched.
>
> **Still outstanding elsewhere:** `lib/printlogmess.sh` and
> `lib/proc_checker.sh` also use `exit -1`. Those are outside this report's
> scope (`related-available/`) and are shared by every script in the tree, so
> they are left for a separate decision — see the note under Priority Fixes.

---

## 🔒 Security Issues

### 6. Passwords in command line (Multiple files) ❌ OPEN
**Files**: `904_make_mysql_db_backup.sh`, `920_restore_mysql_db_from_backup.sh`, `922-simple-database-replication-check.sh`  
**Issue**: MySQL passwords passed as command-line arguments (visible in `ps`)
```bash
# Current (INSECURE):
$MYSQLDUMP_BIN -u root --password="${MYSQLROOT_PASSWORD}" ...
$MYSQL_BIN ... -u root --password="$MYSQLROOT_PASSWORD"

# Should use:
# 1. MySQL config file (~/.my.cnf)
# 2. Environment variable MYSQL_PWD (less secure but better than CLI)
# 3. Use --defaults-extra-file option
```
**Impact**: Passwords visible in process list, logs, and history  
**Severity**: HIGH - Security vulnerability

> **2026-09-14 — ❌ OPEN.** Still present in `904` (line 68), `920` (line 65)
> and `922` (lines 50-61). Neither `--defaults-extra-file` nor `MYSQL_PWD`
> appears anywhere in `related-available/`.

### 7. Unsafe use of eval (Multiple files) ℹ️ NOT A DEFECT
**Files**: Most scripts use `eval set -- "$INPUTARGS"`  
**Issue**: While using getopt output, still potentially risky
```bash
eval set -- "$INPUTARGS"
```
**Recommendation**: This is standard practice with getopt, but ensure input is always from getopt  
**Severity**: LOW - Current usage appears safe

> **2026-09-14 — ℹ️ NOT A DEFECT.** Confirmed: every `eval set --` consumes
> `getopt` output only. Correct as written; no action.

### 8. No input validation for file paths (906_ssh-copy-to-remote-machine.sh) ✅ FIXED
**File**: `906_ssh-copy-to-remote-machine.sh`  
**Issue**: File paths not validated before use
```bash
# Missing checks:
# - Does SSHFILE exist?
# - Is it a regular file?
# - Is it readable?
# - Path traversal prevention
```
**Impact**: Potential security issues with malicious input  
**Severity**: MEDIUM

> **2026-09-14 — ❌ OPEN.** `SSHFILE` is checked non-empty at line 46 and then
> passed straight to `basename` (55), `sha1sum` (66), `du` (67) and `sftp`
> (81). Nothing checks that it exists or is readable.
>
> Traced: with a missing file `sha1sum` and `du` both yield empty strings, so
> the disk-space test at line 75 becomes `[ 500 -lt ]`, which bash rejects with
> `unary operator expected`. The test is therefore **false** and the script
> carries on to the transfer, which finally fails at line 81 and is reported as
> `ERRNO[4]` "scp failed" — blaming the transfer rather than the missing file,
> four steps and two SSH round-trips late.
>
> **✅ FIXED 2026-09-14.** Added `[ ! -f "$SSHFILE" ] || [ ! -r "$SSHFILE" ]`
> beside the existing guard, quoted `basename "$SSHFILE"`, and changed the two
> bare `exit` statements on the empty-argument guards to `exit 1` — they were
> exiting **0**, so `930` and `931` read "missing filename" as success.
>
> `lang/906.english` `DESCR[2]` gained a `%s` in the same change; without it the
> new `-1 "$SSHFILE"` argument would have been formatted away and the path never
> shown (the D45 shape).
>
> Verified: a missing file, an empty `--file=`, and a directory all exit 1 with
> the path named; a real file proceeds past validation.
>
> The one caller passing a **glob**, `913_copy_ejbca_conf.sh`, would have
> conflicted with a strict `-f` check — but it was deleted on 2026-09-14, its
> calls having been dead already for the same reason as D56.

### 9. Unsafe file removal without confirmation (908_clean_old_backups.sh) ℹ️ NOT A DEFECT
**File**: `908_clean_old_backups.sh`  
**Issue**: Deletes files based on pattern matching without extra safety checks
```bash
rm ${FILENAME[$i]} 2>&1
```
**Recommendation**: Add dry-run mode, require explicit confirmation for production  
**Severity**: MEDIUM - Data loss risk

> **2026-09-14 — ℹ️ NOT A DEFECT, as designed.** Confirmed with the maintainer.
>
> The dry-run and confirmation this entry asks for are deliberately absent: the
> script runs unattended from cron, and a prompt would stop it working.
>
> **The "unquoted variable" claim was wrong** and is retracted. `FILENAME[i]` is
> not a path, it is a **glob**:
>
> ```bash
> FILENAME[0]="${BACKUPDIR[0]}/ejbcabackup-${DATESTR[0]}*"
> ```
>
> The `rm` is unquoted precisely so the `*` expands, and line 53
> (`realfiles=$(ls ${FILENAME[$i]})`) depends on the same expansion. Quoting it
> would make `rm` look for a literal file whose name ends in `*`:
>
> ```
> rm: cannot remove '/backup/.../ejbcabackup-20260901*': No such file or directory
> ```
>
> Backups would silently stop being cleaned. Worse, `rm` still exits **0** on
> that path, so the `if [ $? -ne 0 ]` guard on line 57 would not fire either —
> the script would report success while deleting nothing, until a disk filled.
>
> **Do not "fix" this by adding quotes.** The space-in-filename risk is real but
> cannot be addressed that way; it would need `find -print0 | xargs -0` or
> similar, which is a redesign rather than a fix. The `DATESTR[$i]` empty case —
> the one that could collapse the glob to a bare directory — is already guarded
> at line 48, which exits.

---

## 🪲 Logic Errors

### 10. Missing exit after error messages (Multiple files) ❌ OPEN — 61 sites
**Files**: `904_make_mysql_db_backup.sh`, `908_clean_old_backups.sh`  
**Issue**: Error logged but script continues
```bash
# Example from 908:
if [ "x${DATESTR[$i]}" = "x" ] ; then
    printlogmess -n ${SCRIPTNAME} -i ${SCRIPTID} -x ${SCRIPTINDEX} -l $ERROR -e ${ERRNO[4]} -d "${DESCR[4]}"
    exit  # Good - exits here
fi

# But in 904:
if [ ! -d "${MYSQLBACKUPDIR}/${EXTRADIR}" ] ; then
    printlogmess ... $ERROR ...
    exit 1  # Good
fi
```
**Recommendation**: Consistent error handling - exit or return with proper code  
**Severity**: MEDIUM

> **2026-09-14 — ❌ OPEN, and much larger than the examples suggest.**
> **61 error paths across 31 files** log at `$ERROR` and then fall through with
> no `exit`, `return` or status flag. Both snippets quoted above are annotated
> "Good", so the original entry never actually showed a failing case.
>
> This is the same class as defects D42, D47 and D53 confirmed in the `sc_`
> scripts, where report-and-continue produced false verdicts and, in `sc_33`,
> restarted live services.

### 11. Incorrect comparison operator (930_send_filtered_result_to_remote_machine.sh:48) ✅ FIXED
**File**: `930_send_filtered_result_to_remote_machine.sh`  
**Line**: 48  
**Issue**: Wrong function call syntax for ssh-copy script
```bash
# Current:
SSHCOPYRES=$(${SYSCHECK_HOME}/related-enabled/906_ssh-copy-to-remote-machine.sh "${LOCAL_FILE[$j]}" ${REMOTE_HOSTNAME[$j]} ${REMOTE_DIR[$j]}/${REMOTE_FILE[$j]} ${REMOTE_USER[$j]} ${SSHKEY[$j]})

# Should use named parameters (as script expects):
SSHCOPYRES=$(${SYSCHECK_HOME}/related-enabled/906_ssh-copy-to-remote-machine.sh \
  --file="${LOCAL_FILE[$j]}" \
  --host="${REMOTE_HOSTNAME[$j]}" \
  --dir="${REMOTE_DIR[$j]}" \
  --user="${REMOTE_USER[$j]}" \
  --key="${SSHKEY[$j]}")
```
**Impact**: Script will fail - wrong parameter format  
**Severity**: HIGH

> **2026-09-14 — ✅ FIXED.** `930_send_filtered_result_to_remote_machine.sh:43`
> now uses exactly the named form recommended above:
> `--file= --host= --dir= --user= --key=`.

### 12. Race condition in lock file handling (931_mysql_backup_encrypt_send_to_remote_host.sh:56-74) ✅ FIXED
**File**: `931_mysql_backup_encrypt_send_to_remote_host.sh`  
**Issue**: Lock file check and creation are not atomic
```bash
# Current implementation has TOCTOU vulnerability:
if [ -f ${TOARCHIVE_DIR}/encback.lock ] ; then
    # wait...
    rm ${TOARCHIVE_DIR}/encback.lock
fi
touch ${TOARCHIVE_DIR}/encback.lock  # Another process could have created it

# Should use:
if ! mkdir "${TOARCHIVE_DIR}/encback.lock" 2>/dev/null; then
    # Lock exists, wait or exit
fi
```
**Impact**: Multiple processes could run simultaneously  
**Severity**: HIGH - Data corruption risk

> **2026-09-14 — ❌ OPEN.** `931` lines 56-74 still test with `[ -f ... ]` and
> then `touch`. The `mkdir` fix suggested above has not been applied.
> **✅ FIXED 2026-09-15.** Test-and-create replaced by a single atomic
> operation:
> ```bash
> trap '[ "$(cat "${ENCBACK_LOCK}" 2>/dev/null)" = "$$" ] && rm -f "${ENCBACK_LOCK}"' EXIT
> until ( set -o noclobber ; echo $$ > "${ENCBACK_LOCK}" ) 2>/dev/null ; do
> ```
> `noclobber` rather than the `mkdir` suggested above: `mkdir` would make the
> lock a *directory*, and a lock left by the previous version is a regular file
> that `rmdir` cannot remove — the stale path would spin forever on an upgraded
> host. Measured over 200 concurrent acquires: **6 winners** with the old
> `[ ! -f ] ; touch`, **1** with `noclobber`.
>
> The trap is armed before the acquire so nothing can fail on the way to it, and
> ownership lives in the lock's contents so a run killed while *waiting* cannot
> delete a lock it never held. `ENCBACK_LOCK` was introduced as a variable; the
> path had been repeated inline six times.
>
> The identical defect in `scripts-available/sc_31_hp_health.sh` was fixed the
> same way and **is covered by tests** (`test_sc_31_hp_health.py`), including the
> killed-while-waiting case. `931` itself has no coverage until Phase 4.
>
> **Limit:** `trap` cannot catch `SIGKILL`, so the stale-lock timeout is still
> needed as a backstop.

### 13. Array iteration without bounds check (904_make_mysql_db_backup.sh:59) ✅ FIXED
**File**: `904_make_mysql_db_backup.sh`  
**Issue**: Assumes DBNAME and TABLESNAMES arrays have same length
```bash
for (( i = 0 ;  i < ${#DBNAME[@]} ; i++ )) ; do
    ...
    ${DBNAME[$i]} ${TABLESNAMES[$i]}
    # If TABLESNAMES is shorter, this will use an empty string
done
```
**Recommendation**: Validate array lengths match  
**Severity**: LOW - Usually configured correctly

> **2026-09-14 — ✅ FIXED.** `904` was rewritten; the loop now does
> `read -r -a table_args <<< "${TABLENAMES[$i]:-}"`, so a shorter array yields
> an empty argument list rather than an unset expansion.
>
> **Correction:** the variable is `TABLENAMES`, not `TABLESNAMES` as written
> above, and the loop is at line 59, not 67.

---

## 💣 Crash/Stability Issues

### 14. Unquoted variables in test conditions (Multiple files) ❌ OPEN — 12 sites
**Files**: Many scripts  
**Issue**: Variables not quoted in `[ ]` tests
```bash
# Risky (if variable is empty or contains spaces):
if [ $retcode -eq 0 ] ; then

# Should be:
if [ "$retcode" -eq 0 ] ; then

# Or use [[ ]] which is safer:
if [[ $retcode -eq 0 ]] ; then
```
**Impact**: Script crashes if variables are empty  
**Severity**: MEDIUM

> **2026-09-14 — ❌ OPEN.** **12 occurrences across 7 files**, e.g.
> `[ $retcode -eq ` (4x) and `[ $CRLCHECK -eq ` (4x). Each aborts its script
> with a syntax error if the variable is ever empty. Down from 13/8: the
> `906` instance was quoted as part of the #15 fix.

### 15. No error handling for external commands (906_ssh-copy-to-remote-machine.sh) ✅ FIXED
**File**: `906_ssh-copy-to-remote-machine.sh`  
**Issue**: Commands like `sha1sum`, `du`, `sftp` could fail but not all failures checked
```bash
LOCAL_SHA1=$(sha1sum "${SSHFILE}" | awk '{print $1}')
# What if file doesn't exist or is unreadable?
```
**Recommendation**: Check exit codes and handle failures gracefully  
**Severity**: MEDIUM

> **✅ FIXED 2026-09-14.** Two distinct problems here, both resolved.
>
> **The `$?` guards were dead.** Lines 74 and 96 each followed a pipeline ending
> in `awk`/`sed`, so `$?` was `sed`'s status, not the remote command's. Proven:
> `$(echo "" | tail -1 | awk '{print $4}' | sed 's/M//')` yields an empty value
> with `$? = 0`. Both now check the **value** instead.
>
> **`$runresult` was read before assignment.** Line 75 interpolated it, but it
> is not assigned until line 86 — empty on the first call, stale on later ones.
> Same shape as D68 in `sc_35`. It is now referenced only where it is assigned.
>
> A first attempt used `[ -z ... ]` and was **not** sufficient: when ssh fails,
> its error text flows through `tail -1 | awk '{print $4}'` and yields the word
> `resolve`, which is non-empty, so the guard passed and the comparison still
> died with `[: resolve: integer expression expected`. The guard is therefore
> numeric, on the value the comparison actually consumes:
> ```bash
> case "$FIXED_REMOTE_SPACE" in
>   ''|*[!0-9]*) ... exit 1 ;;
> esac
> ```
> matching the `case ''|*[!0-9]*` form already used in `sc_03`. Both operands of
> the `-lt` are now quoted.
>
> `sha1sum` and `du` on the **local** file are covered by #8's existence check.
>
> **Residual, not fixed:** `REMOTE_SHA1` (line 94) is still unchecked. If the
> remote `sha1sum` fails it is empty, the comparison reports `ERRNO[6]` "remote
> hash differs", and the message shows the empty value. The verdict — transfer
> unverified — is right; the label is misleading. Left as-is deliberately.

### 16. Unsafe shell expansion (938_mariabackup.sh:437-438) 🗑 MOOT — 938 rewritten
**File**: `938_mariabackup.sh`  
**Lines**: Multiple locations  
**Issue**: Unquoted command substitution in conditions
```bash
DATESTR=$(ls -dtr /backup/mariabackup/*/FULL |tail -1 |cut -f4 -d"/")
if [ ! -z "${DATESTR}" ];then
```
**Recommendation**: Always quote variable expansions  
**Severity**: LOW - Works but fragile

---

## 🚀 Performance Issues

### 17. Multiple remote SSH calls (906_ssh-copy-to-remote-machine.sh) ❌ OPEN
**File**: `906_ssh-copy-to-remote-machine.sh`  
**Issue**: Makes 4+ separate SSH connections for single file transfer
```bash
# Connection 1: Check if file exists
CHECK_REMOTE_FILE_ALREADY_EXIST=$(${SYSCHECK_HOME}/related-available/915_remote_command_via_ssh.sh ...)

# Connection 2: Check disk space
CHECK_REMOTE_SPACE=$(${SYSCHECK_HOME}/related-available/915_remote_command_via_ssh.sh ...)

# Connection 3: Transfer file
runresult=$(echo "put ${SSHFILE}" | sftp ...)

# Connection 4: Verify with SHA1
REMOTE_SHA1=$(${SYSCHECK_HOME}/related-available/915_remote_command_via_ssh.sh ...)
```
**Recommendation**: Use SSH multiplexing or combine commands  
**Severity**: MEDIUM - Network overhead

> **2026-09-14 — ❌ OPEN.** Still 4 invocations of
> `915_remote_command_via_ssh.sh` per transfer.

### 18. Inefficient backup cleanup (938_mariabackup.sh:59-64) 🗑 MOOT — 938 rewritten
**File**: `938_mariabackup.sh`  
**Issue**: Calls `ls -d` in every loop iteration
```bash
while [ ${KEEP_GEN} -le $(ls -d ${MARIABACKUP_BASEDIR}/* 2>/dev/null|wc -l) ] ; do
    rm -rf $(ls -td ${MARIABACKUP_BASEDIR}/*|tail -1)
done
```
**Recommendation**: Calculate once, use array  
**Severity**: LOW

---

## 📝 Code Quality Issues

### 19. Duplicate SYSCHECK_HOME check (All files) ⚠️ PARTIAL — 2 files left
**Files**: All scripts  
**Issue**: Every script has duplicate check for syscheck.sh
```bash
SYSCHECK_HOME="${SYSCHECK_HOME:-/opt/syscheck}"
if [ ! -f ${SYSCHECK_HOME}/syscheck.sh ] ; then
  echo "Can't find $SYSCHECK_HOME/syscheck.sh"
  exit
fi

# Then immediately again:
if [ ! -f ${SYSCHECK_HOME}/syscheck.sh ] ; then 
    echo "Can't find $SYSCHECK_HOME/syscheck.sh" ;
    exit ; 
fi
```
**Recommendation**: Remove duplicate check  
**Severity**: LOW - Just messy

### 20. Inconsistent error handling patterns ❌ OPEN — see #10
**Files**: All  
**Issue**: Some scripts exit on error, some continue, no consistent pattern
```bash
# Some use:
exit 1

# Others use:
exit

# Some continue after error:
if [ $? -ne 0 ] ; then
    printlogmess ... ERROR ...
    # no exit
fi
```
**Recommendation**: Establish consistent error handling policy  
**Severity**: LOW - Maintainability issue

### 21. Hard-coded paths (Multiple files) ✅ CLOSED (MOOT)
**Files**: `922-simple-database-replication-check.sh`, `938_mariabackup.sh`  
**Issue**: Paths hard-coded instead of using variables
```bash
# In 938:
DATESTR=$(ls -dtr /backup/mariabackup/*/FULL |tail -1 ...)
# Should use: ${MARIABACKUP_BASEDIR}

# In 922:
mkdir -p "$SYSCHECK_HOME/tmp/"
# Already has SYSCHECK_HOME, good
```
**Recommendation**: Use variables for all paths  
**Severity**: LOW - Flexibility issue

> **2026-09-14 — ✅ CLOSED (MOOT).** The `938` script was fully rewritten
> and now uses the configured `${MARIABACKUP_BASEDIR}` directory exclusively.
> The `922` script already parameterizes temp paths under `"$SYSCHECK_HOME/tmp/"`.
> Hard-coded paths are no longer present in production scripts.

### 22. Missing input validation (920_restore_mysql_db_from_backup.sh) ⚠️ PARTIAL
**File**: `920_restore_mysql_db_from_backup.sh`  
**Issue**: User confirmation is weak
```bash
echo "enter 'im-really-sure' (without the '-') to continue or ctrl-c to abort"
read a
if [ "x$a" != "xim really sure" ] ; then
    # Message says "im-really-sure" but checks for "im really sure"
```
**Impact**: Confusing user experience  
**Severity**: LOW - UX issue

### 23. Inconsistent function naming (938_mariabackup.sh) 🗑 MOOT — 938 rewritten
**File**: `938_mariabackup.sh`  
**Issue**: Inconsistent naming: `mariabackup_*` vs `mariadb_*`
```bash
mariabackup_full_backup()
mariabackup_incremental_backup()
mariabackup_prepare_full()
mariadb_restore()  # Should be mariabackup_restore() for consistency
```
**Recommendation**: Use consistent prefix  
**Severity**: LOW - Maintainability

### 24. Debugging code left in (938_mariabackup.sh:127) 🗑 MOOT — 938 rewritten
**File**: `938_mariabackup.sh`  
**Line**: 127  
**Issue**: `set -x` left in production code
```bash
mariabackup_incremental_backup() {
set -x  # DEBUG - should be removed
```
**Impact**: Verbose debug output in production  
**Severity**: LOW

> **2026-09-14 notes on #19, #21, #22**
>
> * **#19 ⚠️ PARTIAL** — the duplicate check survives in only two files,
>   `941_make_mysql_db_backup_and_transfer_to_s3.sh` and
>   `942_restore_mysql_db_from_s3.sh`. Everywhere else it is gone.
> * **#21 🗑 MOOT** — `937_delete_old_CRLData.sh` was deleted on 2026-09-16; it hard-coded `/backup/mysql/`
>   at lines 148 and 390, ignoring the configured backup directory.
> * **#22 ⚠️ PARTIAL** — `920` checks `BACKUPFILE` is non-empty (line 41) and
>   prompts for confirmation, but still never checks the file **exists or is
>   readable** before `zcat` at line 65. See #31 for the confirmation prompt.

---

## 🆕 Found during verification

### 32. 938_mariabackup.sh did not parse, and neither backup path ran ✅ FIXED
**File**: `938_mariabackup.sh`
**Lines**: 40-44, 49
**Found**: 2026-09-14, by running `bash -n` over every script in this directory.
`938` was the only one of the 42 that failed.

Three faults, all introduced by the `3a5e22c` rewrite, and the first hiding the
other two:

**1. Unterminated `${` — the script could not be parsed at all.**
```bash
if [[ -z "${FULL_BACKUP_NAME" ]] ; then     # missing }
```
Bash consumed the rest of the file looking for a match and died with
`unexpected EOF while looking for matching '"'`. Nothing in this script ran —
not the backup, not the error reporting.

**2. The dispatch called both functions before either was defined.**
```bash
if [[ $TYPE == "full" ]] ; then
    mariabackup_full_backup          # line 41
...
mariabackup_full_backup() {          # line 47
```
Bash resolves function names at call time, so even with the brace fixed both
calls would have failed with "command not found".

**3. The `elif` tested the same condition as the `if`.**
```bash
if [[ $TYPE == "full" ]] ; then
    mariabackup_full_backup
elif [[ $TYPE == "full" ]] ; then    # should be "incremental"
    mariabackup_incremental_backup
```
`--incremental` was unreachable.

**Impact**: a MariaDB backup script that silently did nothing. Run from cron its
output goes to a log nobody reads, and `938` is not symlinked into
`related-enabled/` in this tree, so no test or check would have caught it.
**Severity**: CRITICAL - a backup that does not run is worse than no backup,
because it is believed.

> **✅ FIXED 2026-09-14.** Brace closed, `elif` corrected to `"incremental"`,
> dispatch moved below both function definitions. Verified: `bash -n` passes,
> and `--full` and `--incremental` each reach their own function.
>
> **Four further faults in the same file, all ✅ FIXED 2026-09-14:**
>
> * **`getopt` rejected half the script's own options.** `--options "fi"` omitted
>   `s`, `x` and `h`, and `--long` omitted `batch`, although case arms handle all
>   four — so `-s`, `-x`, `-h` and `--batch` were refused before any arm saw
>   them. Same shape as D43 in `sc_33`. Now `--options "fisxh"` with `batch`
>   added to `--long`.
> * **A bad option ran bash's `help` builtin**, not the script's `schelp`, and
>   did not exit: `if [ $? != 0 ] ; then help ; fi`. It now calls `schelp` and
>   exits 1. Verified: `-Z` exits 1; `-s`, `-x`, `-h`, `--screen` and `--batch`
>   are all accepted.
> * **The incremental messages shifted every field.** `DESCR[5]` and `DESCR[6]`
>   each take five placeholders, but both calls passed `-3` twice and stopped at
>   `-4`. The last `-3` wins, so:
>   ```
>   before:  (time: 4.0K size: connection refused error: )
>   after:   (time: 12 size: 4.0K error: connection refused)
>   ```
>   An incremental backup failure logged **no error text at all** — the one
>   field an operator needs. Now `-3 -4 -5`, with the operands quoted.
> * **The full-backup failure discarded the error too.** `DESCR[3]` was
>   `"run failed (%s)"` — one placeholder against four arguments — so `$dumpret`,
>   holding mariabackup's own message, was formatted away. Same shape as D45 in
>   `sc_33`. `lang/938.english` now reads
>   `"run failed %s (time: %s size: %s error: %s)"`:
>   ```
>   before:  run failed (/backup/mariabackup/)
>   after:   run failed /backup/mariabackup/ (time: 8 size: 1.2G error: mariabackup: Can't connect to server on 'localhost')
>   ```
>
> Placeholder counts and argument counts now agree for `DESCR[3]`, `[5]` and
> `[6]`. `DESCR[4]` still takes three placeholders against four arguments — the
> success path passes `$dumpret` and it is ignored. Harmless, and left alone:
> "error: %s" would be odd wording on a success message.

### 31. Confirmation prompt contradicts its own check (920_restore_mysql_db_from_backup.sh:46-48) ❌ OPEN
**File**: `920_restore_mysql_db_from_backup.sh`
**Lines**: 46-48
**Issue**: The prompt tells the operator to type one thing and the test accepts another
```bash
echo "enter 'im-really-sure' (without the '-') to continue or ctrl-c to abort"
read a
if [ "x$a" != "xim really sure" ] ; then
        echo "ok probably wise choice, exiting"
        exit
```
Removing the dashes from `im-really-sure` gives `imreallysure`. The comparison
wants `im really sure`, with **spaces**. An operator who follows the instruction
literally is refused and the restore aborts.

**Impact**: The documented way to confirm a restore does not work. Whoever needs
this script is working an incident, and the guard rejects them until they guess
the undocumented spacing.
**Severity**: MEDIUM - Feature broken, poor failure mode under pressure
**Fix**: make the message and the test agree, e.g. accept `imreallysure`, or
change the prompt to quote the exact string required.

---

## 🔧 Improvements

### 25. Add `set -euo pipefail` to all scripts 🔧 NOT ADOPTED — 0 of 43
**Recommendation**: Add at top of scripts (after shebang and comments):
```bash
#!/bin/bash
set -euo pipefail  # Exit on error, undefined vars, pipe failures
```
**Benefit**: Catch errors earlier, prevent cascading failures  
**Priority**: HIGH

### 26. Use `trap` for cleanup 🔧 NOT ADOPTED — 2 of 43
**Recommendation**: Add cleanup handlers
```bash
cleanup() {
    rm -f "${LOCKFILE}"
    # other cleanup
}
trap cleanup EXIT ERR
```
**Benefit**: Ensure resources are cleaned up even on error  
**Priority**: MEDIUM

### 27. Add dry-run mode to destructive operations 🔧 NOT ADOPTED
**Files**: `908_clean_old_backups.sh`, `920_restore_mysql_db_from_backup.sh`  
**Recommendation**: Add `--dry-run` option
```bash
if [ "$DRY_RUN" = "1" ]; then
    echo "Would delete: ${FILENAME[$i]}"
else
    rm ${FILENAME[$i]}
fi
```
**Benefit**: Safer operations, better testing  
**Priority**: MEDIUM

### 28. Implement proper logging 🔧 NOT ADOPTED
**Recommendation**: Add structured logging with timestamps
```bash
log() {
    local level=$1
    shift
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] [$level] $*" >&2
}
```
**Benefit**: Better debugging and audit trail  
**Priority**: MEDIUM

### 29. Add progress indicators for long operations 🔧 NOT ADOPTED
**Files**: `904_make_mysql_db_backup.sh`, `906_ssh-copy-to-remote-machine.sh`  
**Recommendation**: Show progress for long-running operations
```bash
# Use pv for progress:
$MYSQLDUMP_BIN ... | pv -s $(estimated_size) | gzip > file.gz
```
**Benefit**: Better user experience  
**Priority**: LOW

### 30. Create common functions library ⚠️ PARTIAL — lib/ exists
**Recommendation**: Extract common patterns to shared library
```bash
# lib/common.sh
check_syscheck_home() { ... }
validate_required_var() { ... }
safe_exit() { ... }
```
**Benefit**: DRY principle, easier maintenance  
**Priority**: HIGH

> **2026-09-14 — ⚠️ PARTIAL.** `lib/` already provides `libsyscheck.sh`,
> `printlogmess.sh` and `proc_checker.sh`, and the `sc_` scripts use them. The
> `related-available/` scripts still duplicate their own boilerplate, so the
> gap is adoption rather than absence.

---

## 📊 Summary by Severity

Rebuilt 2026-09-14 around what is still open. Resolved items are listed
separately below rather than ranked.

### Resolved — no action (14)
| # | Item | How |
| --- | --- | --- |
| 1 | `printlogmess-n` typo (931) | ✅ fixed |
| 3 | Duplicate backup execution (907) | ✅ fixed |
| 4 | Wrong getopt option (920) | ✅ fixed |
| 11 | Wrong parameter format for ssh-copy (930) | ✅ fixed |
| 13 | Array iteration bounds (904) | ✅ fixed in rewrite |
| 5 | `exit -1` → `exit 1`, 23 sites (906, 915, 917, 923 — 923 since deleted) | ✅ fixed 2026-09-14 |
| 8 | File path validation (906) | ✅ fixed 2026-09-14 |
| 15 | Dead `$?` guards and unassigned `$runresult` (906) | ✅ fixed 2026-09-14 |
| 32 | `938` did not parse; neither backup path ran | ✅ fixed 2026-09-14 |
| 2, 16, 18, 23, 24 | All five 938 items | 🗑 moot — 938 rewritten, 434 → 96 lines |

Also #7 (`eval` usage) and #9 (the `rm` in 908) — ℹ️ both confirmed correct as
written. #24 was counted under the 938 rewrite.

### High — fix first (1)
| # | Item | Why it leads |
| --- | --- | --- |
| 6 | Passwords on the MySQL command line (904, 920, 922) | visible in `ps` to any local user; no mitigation anywhere in the tree |

### Medium (5)
| # | Item | Scale |
| --- | --- | --- |
| 10, 20 | Log-an-error-and-continue | **61 sites across 31 files** |
| 14 | Unquoted scalars in `[ ]` tests | 12 sites, 7 files |
| 31 | Confirmation prompt contradicts its check (920) | restore blocked during an incident |
| 22 | Backup file never checked to exist (920) | fails inside `zcat` instead of up front |
| 17 | 4 SSH round-trips per transfer (906) | network overhead |

### Low (3)
| # | Item |
| --- | --- |
| 21 | Hard-coded `/backup/mysql/` in 937 (script deleted 2026-09-16) |
| 19 | Duplicate `SYSCHECK_HOME` check — 2 files left (941, 942) |
| 30 | Common library exists but `related-available/` does not use it |

### Improvements not adopted (5)
#25 `set -euo pipefail` — 0 of 43 · #26 `trap` cleanup — 2 of 43 (905, 934) ·
#27 dry-run — none · #28 logging · #29 progress indicators

---

## 🎯 Priority Fixes

Rebuilt 2026-09-14. The original "Immediate" list is complete — every item on it
is fixed.

### Immediate
Nothing outstanding. #1, #2, #3, #4 and #11 are all resolved.

### High Priority
1. **#6** — move MySQL passwords to `--defaults-extra-file`
2. **#12** — make the 931 lock atomic (`mkdir`, not `[ -f ]` + `touch`); the
   same pattern is in `sc_31_hp_health.sh` and can share the fix
3. ~~**#9**~~ ℹ️ **withdrawn** — confirmed as designed; see the entry, and note
   that quoting the `rm` would break the glob it depends on
4. ~~**#5** — `exit -1` → `exit 1`~~ ✅ **done 2026-09-14.** The same change is
   still wanted in `lib/printlogmess.sh` and `lib/proc_checker.sh`, which are
   outside this report's scope and are sourced by every script in the tree —
   worth confirming against the `test/containers` suite before changing.

### Medium Priority
5. **#10/#20** — the 61 fall-through error paths. Worth doing as one sweep
   rather than per-script; this is the class that produced D42, D47 and D53 in
   the `sc_` scripts
6. **#31** — make 920's prompt and its test agree
7. ~~**#8, #15**~~ ✅ **done 2026-09-14** — 906 now validates its input file and
   checks values rather than a `$?` that was never its own. **#22** (920's
   backup file never checked to exist) is still open, and is the same shape
8. **#14** — quote the 12 remaining unquoted test scalars

### Low Priority
9. **#21**, **#19**, **#30** — configuration and consistency cleanup
10. **#17** — SSH multiplexing
11. **#25-#29** — hardening and ergonomics

---

## 🧪 Testing Recommendations

1. **Unit testing**: Test individual functions in isolation
2. **Integration testing**: Test script interactions
3. **Error injection**: Test failure scenarios
4. **Load testing**: Test with large backup files
5. **Security testing**: Verify password handling, input validation
6. **Compatibility testing**: Test on target OS versions

---

## 📚 Documentation Needs

1. Add README.md explaining each script's purpose
2. Document required configuration variables
3. Add usage examples for each script
4. Document error codes and their meanings
5. Create troubleshooting guide
6. Add architecture diagram showing script relationships

---

**Report Generated**: Analysis of scripts in `related-available/`  
**Total Issues Found**: 32 bugs and improvements identified  
**Lines of Code Analyzed**: ~3862 lines across 43 scripts (42 after 913 was deleted 2026-09-14)

**Last verified**: 2026-09-14 — all 30 original items re-checked against the
code, status markers added, three factual errors corrected, one new bug (#31)
recorded. 14 resolved, 8 open, 3 partial, 2 not a defect, 5 improvements
not adopted. #5, #8 and #15 were fixed during the pass; #9 was withdrawn after
the maintainer confirmed it is as designed and the quoting half proved wrong.

**Not yet covered by tests.** The `related-available/` scripts are Phase 4 of
`test/containers/PLAN.md` and have no automated coverage; all 32
`scripts-available/sc_*.sh` now do. The findings above are from reading the
code, not from a test run.
