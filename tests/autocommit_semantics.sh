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

run() {
  EXAPLUS_KNOWN_HOSTS="$KH" EXAPLUS_HISTORY="$HIST" "$@"
}

# seed known_hosts
run "$EXA" -q -u sys -P exasol -c "$HOST_NC" -sql "SELECT 1;" >/dev/null

TS=$(date +%s)
SCHEMA_OFF="ACOFF_${TS}"
SCHEMA_ON="ACON_${TS}"

# autocommit off: rollback should undo DDL
out=$(cat <<SQL | run "$EXA" -q -x -u sys -P exasol -c "$CONN_HOST"
set autocommit off;
create schema ${SCHEMA_OFF};
open schema ${SCHEMA_OFF};
create table ttt(a int);
select 'T1=' || count(*) from exa_all_tables where table_schema='${SCHEMA_OFF}' and table_name='TTT';
rollback;
select 'T2=' || count(*) from exa_all_tables where table_schema='${SCHEMA_OFF}' and table_name='TTT';
SQL
)

echo "$out" | grep -q "T1=1"
echo "$out" | grep -q "T2=0"

# cleanup just in case
run "$EXA" -q -u sys -P exasol -c "$CONN_HOST" -sql "DROP SCHEMA ${SCHEMA_OFF} CASCADE;" >/dev/null 2>&1 || true

# autocommit on: rollback should not remove DDL
out=$(cat <<SQL | run "$EXA" -q -x -u sys -P exasol -c "$CONN_HOST"
set autocommit on;
create schema ${SCHEMA_ON};
open schema ${SCHEMA_ON};
create table ttt(a int);
select 'T3=' || count(*) from exa_all_tables where table_schema='${SCHEMA_ON}' and table_name='TTT';
rollback;
select 'T4=' || count(*) from exa_all_tables where table_schema='${SCHEMA_ON}' and table_name='TTT';
SQL
)

echo "$out" | grep -q "T3=1"
echo "$out" | grep -q "T4=1"

run "$EXA" -q -u sys -P exasol -c "$CONN_HOST" -sql "DROP SCHEMA ${SCHEMA_ON} CASCADE;" >/dev/null 2>&1 || true

if [[ -z "${EXAPLUS_TEST_QUIET:-}" ]]; then
  echo "OK"
fi
