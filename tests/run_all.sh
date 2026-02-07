#!/usr/bin/env bash
set -euo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$DIR/.." && pwd)"
EXA="$ROOT_DIR/exaplus"

TMPDIR=$(mktemp -d)
KH="$TMPDIR/known_hosts"
if EXAPLUS_KNOWN_HOSTS="$KH" EXAPLUS_TEST_QUIET=1 "$EXA" -q -u sys -P exasol -c localhost/nocertcheck:8563 -sql "SELECT 1;" >/dev/null 2>&1; then
  if [[ -z "${EXAPLUS_TEST_FINGERPRINT:-}" && -s "$KH" ]]; then
    fp=$(awk '/^localhost:8563[[:space:]]+[0-9a-fA-F]+/ {print $2; exit}' "$KH")
    if [[ -n "$fp" ]]; then
      export EXAPLUS_TEST_FINGERPRINT="$fp"
    fi
  fi

  if out=$(EXAPLUS_KNOWN_HOSTS="$KH" EXAPLUS_TEST_QUIET=1 "$EXA" -q -u sys -P exasol -c localhost -sql "SELECT SCHEMA_NAME FROM EXA_ALL_SCHEMAS WHERE SCHEMA_NAME='TEST2';" 2>/dev/null); then
    if ! echo "$out" | grep -qi "TEST2"; then
      EXAPLUS_KNOWN_HOSTS="$KH" EXAPLUS_TEST_QUIET=1 "$EXA" -q -u sys -P exasol -c localhost -sql "CREATE SCHEMA test2;" >/dev/null 2>&1 || true
    fi
  fi
fi
rm -rf "$TMPDIR"

echo "RUN run.lua"
EXAPLUS_TEST_QUIET=1 lua "$DIR/run.lua"
echo "OK run.lua"

echo "RUN options_core.sh"
EXAPLUS_TEST_QUIET=1 "$DIR/options_core.sh"
echo "OK options_core.sh"

echo "RUN options_more.sh"
EXAPLUS_TEST_QUIET=1 "$DIR/options_more.sh"
echo "OK options_more.sh"

echo "RUN sql_scripts.sh"
EXAPLUS_TEST_QUIET=1 "$DIR/sql_scripts.sh"
echo "OK sql_scripts.sh"

echo "RUN autocommit_semantics.sh"
EXAPLUS_TEST_QUIET=1 "$DIR/autocommit_semantics.sh"
echo "OK autocommit_semantics.sh"

echo "RUN tpch_cases.sh"
EXAPLUS_TEST_QUIET=1 "$DIR/tpch_cases.sh"
echo "OK tpch_cases.sh"

echo "RUN tpch_sql_files.sh"
EXAPLUS_TEST_QUIET=1 "$DIR/tpch_sql_files.sh"
echo "OK tpch_sql_files.sh"

if command -v expect >/dev/null 2>&1; then
  echo "RUN interactive.expect"
  LOG="$DIR/interactive.expect.log"
  if ! expect "$DIR/interactive.expect" >"$LOG" 2>&1; then
    echo "interactive.expect failed, log:"
    tail -n 50 "$LOG"
    exit 1
  fi
  echo "OK interactive.expect"
else
  echo "SKIP interactive.expect (expect not installed)"
fi

echo "ALL OK"
