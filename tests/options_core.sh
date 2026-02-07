#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
EXA="$ROOT_DIR/exaplus"
TMPDIR=$(mktemp -d)
KH="$TMPDIR/known_hosts"
HIST="$TMPDIR/history"
SQLFILE="$TMPDIR/sql.sql"
INITFILE="$TMPDIR/init.sql"
BATCHFILE="$TMPDIR/batch.sql"
ERRFILE="$TMPDIR/err.txt"

run() {
  EXAPLUS_KNOWN_HOSTS="$KH" EXAPLUS_HISTORY="$HIST" "$@"
}

# 1) nocertcheck initial connect
run "$EXA" -q -u sys -P exasol -c localhost/nocertcheck:8563 -sql "SELECT 1;" >/dev/null
run "$EXA" -q -u sys -P exasol -c localhost:8563/nocertcheck -sql "SELECT 1;" >/dev/null

grep -q "localhost:8563" "$KH"

# 2) connect without cert spec (uses known_hosts)
run "$EXA" -q -u sys -P exasol -c localhost:8563 -sql "SELECT 1;" >/dev/null

# 3) default port
run "$EXA" -q -u sys -P exasol -c localhost -sql "SELECT 1;" >/dev/null

# 4) mismatch detection
printf "localhost:8563 deadbeef\n" > "$KH"
if run "$EXA" -u sys -P exasol -c localhost -sql "SELECT 1;" >/dev/null 2>"$ERRFILE"; then
  echo "Expected failure on mismatched fingerprint" >&2
  exit 1
fi

grep -q "REMOTE CERTIFICATE HAS CHANGED" "$ERRFILE"

# 5) restore via nocertcheck
run "$EXA" -q -u sys -P exasol -c localhost/nocertcheck:8563 -sql "SELECT 1;" >/dev/null

# 6) rowcount format
out=$(run "$EXA" -q -u sys -P exasol -c localhost -sql "OPEN SCHEMA test2;")
echo "$out" | grep -q "Rows affected"

# 7) -init + sql check schema
printf "OPEN SCHEMA test2;\n" > "$INITFILE"
out=$(run "$EXA" -q -u sys -P exasol -c localhost -init "$INITFILE" -sql "SELECT CURRENT_SCHEMA;")
echo "$out" | grep -qi "TEST2"

# 8) -f file with two statements
cat > "$SQLFILE" <<'SQL'
SELECT 1;
SELECT 2;
SQL
out=$(run "$EXA" -q -u sys -P exasol -c localhost -f "$SQLFILE")
echo "$out" | grep -Eq "row(s)? in resultset"

# 9) -B file (single statement)
printf "SELECT 3;\n" > "$BATCHFILE"
run "$EXA" -q -u sys -P exasol -c localhost -B "$BATCHFILE" >/dev/null

# 10) history save from non-tty
printf "SELECT 1;\n" | EXAPLUS_KNOWN_HOSTS="$KH" EXAPLUS_HISTORY="$HIST" "$EXA" -q -u sys -P exasol -c localhost >/dev/null

grep -q "SELECT 1" "$HIST"

if [[ -z "${EXAPLUS_TEST_QUIET:-}" ]]; then
  echo "OK"
fi
