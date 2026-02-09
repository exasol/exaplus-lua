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
HOSTPORT_NC="$HOST:$PORT/nocertcheck"
TMPDIR=$(mktemp -d)
KH="$TMPDIR/known_hosts"
HIST="$TMPDIR/history"
SQLFILE="$TMPDIR/scripts.sql"

run() {
  EXAPLUS_KNOWN_HOSTS="$KH" EXAPLUS_HISTORY="$HIST" "$@"
}

# ensure known_hosts
run "$EXA" -q -u sys -P exasol -c "$HOST_NC" -sql "SELECT 1;" >/dev/null

ts=$(date +%s)
s1="EXAPLUS_SCRIPT_${ts}"
s2="EXAPLUS_UDF_${ts}"
s3="EXAPLUS_PRE_${ts}"

cat > "$SQLFILE" <<SQL
OPEN SCHEMA test2;
CREATE OR REPLACE SCRIPT $s1 AS
  output('hello;world');
  output('line2');
/;
EXECUTE SCRIPT $s1;

CREATE OR REPLACE LUA SCALAR SCRIPT $s2(a INT) RETURNS VARCHAR(100) AS
function run(ctx)
  local x = "v="; local y = ";ok";
  return x .. tostring(ctx.a) .. y
end
/;
SELECT $s2(3);

CREATE OR REPLACE PREPROCESSOR SCRIPT $s3 AS
  output("pp; test")
/;
DROP SCRIPT $s3;
DROP SCRIPT $s2;
DROP SCRIPT $s1;
SQL

out=$(run "$EXA" -q -u sys -P exasol -c "$CONN_HOST" -f "$SQLFILE")
echo "$out" | grep -Eq "row(s)? in resultset"
echo "$out" | grep -q "Rows affected"

if [[ -z "${EXAPLUS_TEST_QUIET:-}" ]]; then
  echo "OK"
fi
