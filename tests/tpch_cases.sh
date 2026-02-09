#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
EXA="${EXAPLUS_BIN:-$ROOT_DIR/exaplus}"
HOST="${EXAPLUS_TEST_HOST:-localhost}"
PORT="${EXAPLUS_TEST_PORT:-8563}"
HOSTPORT="$HOST:$PORT"
CONN_HOST="$HOST"
if [[ "$PORT" != "8563" ]]; then
  CONN_HOST="$HOSTPORT"
fi
HOST_NC="$HOST/nocertcheck:$PORT"
HOSTLIST="$HOST,$HOST"
HOSTLIST_NC="$HOSTLIST/nocertcheck:$PORT"
HOSTLIST_PORT_NC="$HOSTLIST:$PORT/nocertcheck"
TMPDIR=$(mktemp -d)
KH="$TMPDIR/known_hosts"
HIST="$TMPDIR/history"
SQLFILE="$TMPDIR/piped.sql"

run() {
  EXAPLUS_KNOWN_HOSTS="$KH" EXAPLUS_HISTORY="$HIST" "$@"
}

# seed known_hosts
run "$EXA" -q -u sys -P exasol -c "$HOST_NC" -sql "SELECT 1;" >/dev/null

# 1) -autoCompletion OFF with piped SQL
out=$(printf "SELECT 1;\n" | run "$EXA" -q -u sys -P exasol -c "$CONN_HOST" -autoCompletion OFF)
echo "$out" | grep -Eq "row(s)? in resultset"

# 2) -autoCompletion off (lowercase)
out=$(printf "SELECT 1;\n" | run "$EXA" -q -u sys -P exasol -c "$CONN_HOST" -autoCompletion off)
echo "$out" | grep -Eq "row(s)? in resultset"

# 3) host list with port + nocertcheck (both positions)
run "$EXA" -q -u sys -P exasol -c "$HOSTLIST_NC" -sql "SELECT 1;" >/dev/null
run "$EXA" -q -u sys -P exasol -c "$HOSTLIST_PORT_NC" -sql "SELECT 1;" >/dev/null

# 4) cat file | exaplus (tpch-style piping)
cat > "$SQLFILE" <<'SQL'
SELECT 1;
SELECT 2;
SQL
out=$(cat "$SQLFILE" | run "$EXA" -q -u sys -P exasol -c "$CONN_HOST" -autoCompletion OFF)
echo "$out" | grep -Eq "row(s)? in resultset"

# 5) echo inline | exaplus
out=$(echo "SELECT 3;" | run "$EXA" -q -u sys -P exasol -c "$CONN_HOST" -autoCompletion OFF)
echo "$out" | grep -Eq "row(s)? in resultset"

if [[ -z "${EXAPLUS_TEST_QUIET:-}" ]]; then
  echo "OK"
fi
