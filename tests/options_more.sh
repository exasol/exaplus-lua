#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
EXA="$ROOT_DIR/exaplus"
TMPDIR=$(mktemp -d)
KH="$TMPDIR/known_hosts"
HIST="$TMPDIR/history"
ERRFILE="$TMPDIR/err.txt"

run() {
  EXAPLUS_KNOWN_HOSTS="$KH" EXAPLUS_HISTORY="$HIST" "$@"
}

# ensure known_hosts
run "$EXA" -q -u sys -P exasol -c localhost/nocertcheck:8563 -sql "SELECT 1;" >/dev/null

# 0) host list (one invalid host, one valid)
run "$EXA" -q -u sys -P exasol -c "256.256.256.256,localhost" -sql "SELECT 1;" >/dev/null

# 0b) host list (three hosts, bad in middle)
run "$EXA" -q -u sys -P exasol -c "localhost,256.256.256.256,127.0.0.1" -sql "SELECT 1;" >/dev/null

# 0c) host list (three hosts, bad at end)
run "$EXA" -q -u sys -P exasol -c "127.0.0.1,localhost,256.256.256.256" -sql "SELECT 1;" >/dev/null

# 0d) pipe mode prompt + echo, no banner
out=$(printf "SELECT 1;\n" | EXAPLUS_KNOWN_HOSTS="$KH" EXAPLUS_HISTORY="$HIST" "$EXA" -u sys -P exasol -c localhost)
echo "$out" | grep -Eq "row(s)? in resultset"
echo "$out" | grep -q "^SQL_EXA> "
if echo "$out" | grep -q "EXAplusLua"; then
  echo "Expected no banner in pipe mode" >&2
  exit 1
fi

# 1) -s <schema>
out=$(run "$EXA" -q -u sys -P exasol -c localhost -s test2 -sql "SELECT CURRENT_SCHEMA;")
echo "$out" | grep -qi "TEST2"

# 2) -autocommit OFF (status via getAttributes)
out=$(run "$EXA" -q -u sys -P exasol -c localhost -autocommit OFF -sql "SELECT 1;")
echo "$out" | grep -Eq "row(s)? in resultset"

# 3) -Q (query timeout) set low; expect error on sleep
if run "$EXA" -q -u sys -P exasol -c localhost -Q 1 -sql "SELECT SLEEP(2);" >/dev/null 2>"$ERRFILE"; then
  echo "Expected timeout error" >&2
  exit 1
fi

grep -q "\[" "$ERRFILE"

# 4) -x exit on error
if run "$EXA" -q -u sys -P exasol -c localhost -x -sql "SELECT * FROM not_a_table;" >/dev/null 2>"$ERRFILE"; then
  echo "Expected failure with -x" >&2
  exit 1
fi

# 5) explicit fingerprint in -c
FP=$(awk '/^localhost:8563[[:space:]]+[0-9a-fA-F]+/ {print $2; exit}' "$KH")
run "$EXA" -q -u sys -P exasol -c "localhost/$FP:8563" -sql "SELECT 1;" >/dev/null

# 6) -help / -version
"$EXA" -help | grep -q "Synopsis"
"$EXA" -version | grep -q "EXAplusLua"

# 7) -F fetch size with larger result set
out=$(run "$EXA" -q -u sys -P exasol -c localhost -F 1 -sql "SELECT COLUMN_NAME FROM EXA_ALL_COLUMNS LIMIT 101;")
echo "$out" | grep -Eq "row(s)? in resultset"

if [[ -z "${EXAPLUS_TEST_QUIET:-}" ]]; then
  echo "OK"
fi
