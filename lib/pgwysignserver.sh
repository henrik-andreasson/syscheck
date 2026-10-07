#!/bin/bash
#
# start-pgwy-signserver.sh
#
# Compiles (if needed) and starts the persistent PgwySignServer daemon.
# Safe to re-run: won't start a second instance if one's already listening.
#
# ============================================================
#  CONFIGURATION - edit these or override with CLI flags
# ============================================================
SIGN_LIB_DIR="/opt/syscheck/lib"
P12FILE="/opt/syscheck/cert/test.p12"
P12PASSWORD="1234"
PORT="9600"
THREADS="8"
LOGFILE="/opt/verification/pgwysignserver.log"
PIDFILE="/opt/syscheck/lib/pgwysignserver.pid"
# ============================================================

usage() {
  cat <<EOF
Usage: $0 [options]

  -d DIR       directory containing PgwySignServer.java and its jars (default: $SIGN_LIB_DIR)
  -p FILE      officer P12 file                                      (default: $P12FILE)
  -w PASS      P12 password                                          (default: hidden)
  -P PORT      port to listen on                                     (default: $PORT)
  -t THREADS   worker thread pool size                                (default: $THREADS)
  -l LOGFILE   daemon stdout/stderr log                                (default: $LOGFILE)
  -k           stop a running daemon (reads pidfile) and exit
  -h           show this help
EOF
  exit 1
}

STOP=0
while getopts ":d:p:w:P:t:l:kh" opt; do
  case $opt in
    d) SIGN_LIB_DIR="$OPTARG" ;;
    p) P12FILE="$OPTARG" ;;
    w) P12PASSWORD="$OPTARG" ;;
    P) PORT="$OPTARG" ;;
    t) THREADS="$OPTARG" ;;
    l) LOGFILE="$OPTARG" ;;
    k) STOP=1 ;;
    h) usage ;;
    \?) echo "Invalid option: -$OPTARG" >&2; usage ;;
    :) echo "Option -$OPTARG requires an argument." >&2; usage ;;
  esac
done

PIDFILE="${SIGN_LIB_DIR}/pgwysignserver.pid"
CLASSPATH=".:${SIGN_LIB_DIR}:${SIGN_LIB_DIR}/*"

# ---- stop mode ----
if [ "$STOP" -eq 1 ]; then
  if [ -f "$PIDFILE" ] && kill -0 "$(cat "$PIDFILE")" 2>/dev/null; then
    echo "Stopping PgwySignServer (pid $(cat "$PIDFILE"))..."
    kill "$(cat "$PIDFILE")"
    rm -f "$PIDFILE"
  else
    echo "No running PgwySignServer found (pidfile: $PIDFILE)"
  fi
  exit 0
fi

for cmd in java javac; do
  command -v "$cmd" >/dev/null 2>&1 || { echo "ERROR: '$cmd' not found in PATH"; exit 1; }
done
if [ ! -f "$P12FILE" ]; then echo "ERROR: P12 file not found: $P12FILE"; exit 1; fi
if [ ! -f "${SIGN_LIB_DIR}/PgwySignServer.java" ]; then
  echo "ERROR: ${SIGN_LIB_DIR}/PgwySignServer.java not found"; exit 1
fi

# ---- already running? ----
if [ -f "$PIDFILE" ] && kill -0 "$(cat "$PIDFILE")" 2>/dev/null; then
  echo "PgwySignServer already running (pid $(cat "$PIDFILE")), port ${PORT}. Use -k to stop it first."
  exit 0
fi

# ---- compile if needed (source newer than class, or class missing) ----
if [ ! -f "${SIGN_LIB_DIR}/PgwySignServer.class" ] || \
   [ "${SIGN_LIB_DIR}/PgwySignServer.java" -nt "${SIGN_LIB_DIR}/PgwySignServer.class" ]; then
  echo "Compiling PgwySignServer.java..."
  ( cd "$SIGN_LIB_DIR" && javac -cp "$CLASSPATH" PgwySignServer.java )
  if [ $? -ne 0 ]; then
    echo "ERROR: compilation failed"
    exit 1
  fi
fi

# ---- start, backgrounded, detached from this shell ----
echo "Starting PgwySignServer on port ${PORT} (threads=${THREADS})..."
( cd "$SIGN_LIB_DIR" && \
  nohup java -cp "$CLASSPATH" PgwySignServer "$P12FILE" "$P12PASSWORD" "$PORT" "$THREADS" \
    >> "$LOGFILE" 2>&1 &
  echo $! > "$PIDFILE" )

sleep 1
if kill -0 "$(cat "$PIDFILE")" 2>/dev/null; then
  echo "Started (pid $(cat "$PIDFILE")). Log: $LOGFILE"
  tail -n 3 "$LOGFILE"
else
  echo "ERROR: process did not stay running - check $LOGFILE"
  rm -f "$PIDFILE"
  exit 1
fi
