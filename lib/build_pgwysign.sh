#!/bin/bash
#
# build-pgwysign.sh
#
# Compiles the PGWY signing helpers in this directory into .class files:
#   PgwySign.java        -> PgwySign.class        (used by sc_50_nexus_api.sh)
#   PgwySignServer.java  -> PgwySignServer.class  (optional, used by test/pgwysignserver.sh)
#
# The .class files are build output and are not kept in git. Run this once
# after cloning/updating syscheck, and again whenever a .java file changes.
#
# Requirements:
#   - a JDK (javac) in PATH, or JAVA_HOME pointing at one
#   - the Nexus CM SDK jars copied into this directory (they are proprietary
#     and cannot be distributed with syscheck). They are normally found in the
#     CM client installation's lib directory, e.g.:
#        cm-sdk.jar  cm-common.jar  common.jar  bcprov-jdk15on-*.jar
#     Any jar that provides com.id2tech.security.* is accepted.
#
# Usage:
#   ./build-pgwysign.sh [-d DIR] [-f] [-c] [-h]
#
#   -d DIR   directory with the .java sources and jars (default: this script's dir)
#   -f       force rebuild even if the .class files are up to date
#   -c       clean: remove the generated .class files and exit
#   -h       show help
#
# Extra javac flags can be passed in JAVAC_OPTS, e.g. to target an older JVM:
#   JAVAC_OPTS="--release 11" ./build-pgwysign.sh -f
#

SOURCES="PgwySign PgwySignServer"
LIB_DIR="$(cd "$(dirname "$0")" && pwd)"
FORCE=0
CLEAN=0

usage() {
  sed -n '3,30p' "$0" | sed 's/^# \{0,1\}//'
  exit "${1:-1}"
}

while getopts ":d:fch" opt; do
  case $opt in
    d) LIB_DIR="$OPTARG" ;;
    f) FORCE=1 ;;
    c) CLEAN=1 ;;
    h) usage 0 ;;
    \?) echo "Invalid option: -$OPTARG" >&2; usage ;;
    :)  echo "Option -$OPTARG requires an argument." >&2; usage ;;
  esac
done

if [ ! -d "$LIB_DIR" ]; then
  echo "ERROR: directory not found: $LIB_DIR" >&2
  exit 1
fi
cd "$LIB_DIR" || exit 1

# ---- clean mode ----
if [ "$CLEAN" -eq 1 ]; then
  for c in $SOURCES; do
    rm -f "${c}.class" "${c}"\$*.class
  done
  echo "Removed generated .class files in $LIB_DIR"
  exit 0
fi

# ---- locate javac ----
if [ -n "$JAVA_HOME" ] && [ -x "$JAVA_HOME/bin/javac" ]; then
  JAVAC="$JAVA_HOME/bin/javac"
elif command -v javac >/dev/null 2>&1; then
  JAVAC="$(command -v javac)"
else
  echo "ERROR: javac not found. Install a JDK (e.g. 'apt install default-jdk-headless'" >&2
  echo "       or 'dnf install java-17-openjdk-devel') or set JAVA_HOME." >&2
  exit 1
fi

# ---- check sources ----
# PgwySign is required (sc_50). PgwySignServer is optional (only used by
# test/pgwysignserver.sh for load testing) and is skipped if not present.
if [ ! -f "PgwySign.java" ]; then
  echo "ERROR: ${LIB_DIR}/PgwySign.java not found" >&2
  exit 1
fi
PRESENT=""
for c in $SOURCES; do
  if [ -f "${c}.java" ]; then
    PRESENT="$PRESENT $c"
  else
    echo "Skipping ${c}: ${c}.java not found (optional)"
  fi
done
SOURCES="$PRESENT"

# ---- check that the Nexus SDK jars are present ----
shopt -s nullglob
JARS=( *.jar )
shopt -u nullglob
FOUND_SDK=0
for j in "${JARS[@]}"; do
  if unzip -l "$j" 2>/dev/null | grep -q 'com/id2tech/security/pkcs7/SignedData.class'; then
    FOUND_SDK=1
    break
  fi
done
if [ "$FOUND_SDK" -eq 0 ]; then
  # unzip may be missing; fall back to the JDK's jar tool before giving up
  JARTOOL="$(dirname "$JAVAC")/jar"
  if [ -x "$JARTOOL" ]; then
    for j in "${JARS[@]}"; do
      if "$JARTOOL" tf "$j" 2>/dev/null | grep -q 'com/id2tech/security/pkcs7/SignedData.class'; then
        FOUND_SDK=1
        break
      fi
    done
  fi
fi
if [ "$FOUND_SDK" -eq 0 ]; then
  echo "ERROR: no jar in $LIB_DIR provides com.id2tech.security.pkcs7.SignedData." >&2
  echo "       Copy the Nexus CM SDK jars (cm-sdk.jar, cm-common.jar, common.jar," >&2
  echo "       bcprov-jdk15on-*.jar) from your CM installation into $LIB_DIR." >&2
  exit 1
fi

CLASSPATH=".:${LIB_DIR}:${LIB_DIR}/*"

# ---- compile what is missing or out of date ----
BUILT=0
for c in $SOURCES; do
  if [ "$FORCE" -eq 1 ] || [ ! -f "${c}.class" ] || [ "${c}.java" -nt "${c}.class" ]; then
    echo "Compiling ${c}.java ..."
    # shellcheck disable=SC2086
    if ! "$JAVAC" $JAVAC_OPTS -cp "$CLASSPATH" -d "$LIB_DIR" "${c}.java"; then
      echo "ERROR: compilation of ${c}.java failed" >&2
      exit 1
    fi
    BUILT=$((BUILT + 1))
  else
    echo "${c}.class is up to date"
  fi
done

echo "Done: $BUILT class file(s) built in $LIB_DIR using $("$JAVAC" -version 2>&1 | tail -1)"
exit 0

