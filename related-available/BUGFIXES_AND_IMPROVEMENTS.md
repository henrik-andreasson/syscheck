# Bug Fixes and Improvements for related-available Scripts

## Overview
Analysis of the `related-available/` directory containing 40 helper scripts for system checking, backup, and maintenance operations.

---

## 🐛 Critical Bugs

### 1. Missing space in `printlogmess-n` (931_mysql_backup_encrypt_send_to_remote_host.sh:55)
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

### 2. Missing closing bracket in while loop (938_mariabackup.sh:60)
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

### 3. Duplicate backup execution (907_make_mysql_db_backup_and_transfer_to_remote_mashine.sh:54-60)
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

### 4. Wrong option in getopt (920_restore_db.sh:31)
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

### 5. Inconsistent exit codes (Multiple files)
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

---

## 🔒 Security Issues

### 6. Passwords in command line (Multiple files)
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

### 7. Unsafe use of eval (Multiple files)
**Files**: Most scripts use `eval set -- "$INPUTARGS"`  
**Issue**: While using getopt output, still potentially risky
```bash
eval set -- "$INPUTARGS"
```
**Recommendation**: This is standard practice with getopt, but ensure input is always from getopt  
**Severity**: LOW - Current usage appears safe

### 8. No input validation for file paths (906_ssh-copy-to-remote-machine.sh)
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

### 9. Unsafe file removal without confirmation (908_clean_old_backups.sh)
**File**: `908_clean_old_backups.sh`  
**Issue**: Deletes files based on pattern matching without extra safety checks
```bash
rm ${FILENAME[$i]} 2>&1
```
**Recommendation**: Add dry-run mode, require explicit confirmation for production  
**Severity**: MEDIUM - Data loss risk

---

## 🪲 Logic Errors

### 10. Missing exit after error messages (Multiple files)
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

### 11. Incorrect comparison operator (930_send_filtered_result_to_remote_machine.sh:48)
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

### 12. Race condition in lock file handling (931_mysql_backup_encrypt_send_to_remote_host.sh:60-73)
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

### 13. Array iteration without bounds check (904_make_mysql_db_backup.sh:67)
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

---

## 💣 Crash/Stability Issues

### 14. Unquoted variables in test conditions (Multiple files)
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

### 15. No error handling for external commands (906_ssh-copy-to-remote-machine.sh)
**File**: `906_ssh-copy-to-remote-machine.sh`  
**Issue**: Commands like `sha1sum`, `du`, `sftp` could fail but not all failures checked
```bash
LOCAL_SHA1=$(sha1sum "${SSHFILE}" | awk '{print $1}')
# What if file doesn't exist or is unreadable?
```
**Recommendation**: Check exit codes and handle failures gracefully  
**Severity**: MEDIUM

### 16. Unsafe shell expansion (938_mariabackup.sh:437-438)
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

### 17. Multiple remote SSH calls (906_ssh-copy-to-remote-machine.sh)
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

### 18. Inefficient backup cleanup (938_mariabackup.sh:59-64)
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

### 19. Duplicate SYSCHECK_HOME check (All files)
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

### 20. Inconsistent error handling patterns
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

### 21. Hard-coded paths (Multiple files)
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

### 22. Missing input validation (920_restore_mysql_db_from_backup.sh)
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

### 23. Inconsistent function naming (938_mariabackup.sh)
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

### 24. Debugging code left in (938_mariabackup.sh:127)
**File**: `938_mariabackup.sh`  
**Line**: 127  
**Issue**: `set -x` left in production code
```bash
mariabackup_incremental_backup() {
set -x  # DEBUG - should be removed
```
**Impact**: Verbose debug output in production  
**Severity**: LOW

---

## 🔧 Improvements

### 25. Add `set -euo pipefail` to all scripts
**Recommendation**: Add at top of scripts (after shebang and comments):
```bash
#!/bin/bash
set -euo pipefail  # Exit on error, undefined vars, pipe failures
```
**Benefit**: Catch errors earlier, prevent cascading failures  
**Priority**: HIGH

### 26. Use `trap` for cleanup
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

### 27. Add dry-run mode to destructive operations
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

### 28. Implement proper logging
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

### 29. Add progress indicators for long operations
**Files**: `904_make_mysql_db_backup.sh`, `906_ssh-copy-to-remote-machine.sh`  
**Recommendation**: Show progress for long-running operations
```bash
# Use pv for progress:
$MYSQLDUMP_BIN ... | pv -s $(estimated_size) | gzip > file.gz
```
**Benefit**: Better user experience  
**Priority**: LOW

### 30. Create common functions library
**Recommendation**: Extract common patterns to shared library
```bash
# lib/common.sh
check_syscheck_home() { ... }
validate_required_var() { ... }
safe_exit() { ... }
```
**Benefit**: DRY principle, easier maintenance  
**Priority**: HIGH

---

## 📊 Summary by Severity

### Critical (2)
1. Missing space in `printlogmess-n` command (931)
2. Syntax error in while loop (938)

### High (6)
3. Duplicate backup execution (907)
4. Wrong option name in getopt (920)
6. Passwords in command line (multiple)
11. Wrong parameter format for ssh-copy (930)
12. Race condition in lock file (931)

### Medium (8)
5. Inconsistent exit codes (multiple)
8. No input validation for file paths (906)
9. Unsafe file removal (908)
10. Missing exit after errors (multiple)
14. Unquoted variables (multiple)
15. No error handling for external commands (906)
17. Multiple SSH connections (906)

### Low (7)
7. Unsafe eval usage (appears safe but noted)
13. Array iteration without bounds check (904)
16. Unsafe shell expansion (938)
18. Inefficient backup cleanup (938)
19-24. Code quality issues

---

## 🎯 Priority Fixes

### Immediate (Must fix before next deployment)
1. Fix `printlogmess-n` typo in 931
2. Fix syntax error in 938
3. Remove duplicate backup execution in 907
4. Fix wrong option name in 920
5. Fix wrong parameters in 930

### High Priority (Fix within sprint)
6. Replace password CLI arguments with config file
7. Fix race condition in lock file handling (931)
8. Fix inconsistent exit codes (-1 → 1)

### Medium Priority (Plan for next release)
9. Add proper input validation
10. Improve error handling consistency
11. Reduce SSH connection overhead
12. Add dry-run modes

### Low Priority (Technical debt)
13. Code cleanup and consistency improvements
14. Extract common functions
15. Improve documentation

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

**Report Generated**: Analysis of 40 scripts in `related-available/`  
**Total Issues Found**: 30+ bugs and improvements identified  
**Lines of Code Analyzed**: ~3000+ lines across all scripts