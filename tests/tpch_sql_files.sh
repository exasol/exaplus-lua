#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
EXA="$ROOT_DIR/exaplus"
TMPDIR=$(mktemp -d)
KH="$TMPDIR/known_hosts"
HIST="$TMPDIR/history"
TPCH_SQL_DIR="$ROOT_DIR/tests/sql/tpch"
ACID_SQL_DIR="$ROOT_DIR/tests/sql/acid"

run() {
  EXAPLUS_KNOWN_HOSTS="$KH" EXAPLUS_HISTORY="$HIST" "$@"
}

# seed known_hosts
run "$EXA" -q -u sys -P exasol -c localhost/nocertcheck:8563 -sql "SELECT 1;" >/dev/null

# ensure tpcuser exists so DROP USER in create_user.sql succeeds
run "$EXA" -q -u sys -P exasol -c localhost -sql "CREATE USER tpcuser IDENTIFIED BY \"tpcuser\";" >/dev/null 2>&1 || true

# run create_user.sql (sys)
run "$EXA" -q -x -u sys -P exasol -c localhost -f "$TPCH_SQL_DIR/create_user.sql" >/dev/null

# reset TPC schema to ensure create_schema.sql succeeds
run "$EXA" -q -u sys -P exasol -c localhost -sql "DROP SCHEMA tpc CASCADE;" >/dev/null 2>&1 || true

# create schema/tables (tpcuser)
run "$EXA" -q -x -u tpcuser -P tpcuser -c localhost -f "$TPCH_SQL_DIR/create_schema.sql" >/dev/null

# prepare postcheck schemas (owned by tpcuser) so DROP without cascade succeeds
run "$EXA" -q -u tpcuser -P tpcuser -c localhost -sql "DROP SCHEMA postcheck CASCADE;" >/dev/null 2>&1 || true
run "$EXA" -q -u tpcuser -P tpcuser -c localhost -sql "CREATE SCHEMA postcheck;" >/dev/null 2>&1 || true
run "$EXA" -q -u tpcuser -P tpcuser -c localhost -sql "DROP SCHEMA postcheck2 CASCADE;" >/dev/null 2>&1 || true
run "$EXA" -q -u tpcuser -P tpcuser -c localhost -sql "CREATE SCHEMA postcheck2;" >/dev/null 2>&1 || true

# create postcheck schema/tables (tpcuser)
run "$EXA" -q -x -u tpcuser -P tpcuser -c localhost -f "$TPCH_SQL_DIR/create_postcheck_schema.sql" >/dev/null

# create history tables (sys + tpcuser)
run "$EXA" -q -x -u sys -P exasol -c localhost -f "$ACID_SQL_DIR/create_history_table.sql" >/dev/null
run "$EXA" -q -x -u tpcuser -P tpcuser -c localhost -f "$ACID_SQL_DIR/create_history_table2.sql" >/dev/null

# indices pipelines (match TPCH scripts)
cat "$TPCH_SQL_DIR/create_indices.sql" | \
  sed "s+END_OF_OPTIMIZATION+END_OF_LINEITEM_OPTIMIZATION+g" | \
  grep -i -v -e NATION -e REGION -e " PART" -e ORDERS -e PARTSUPP -e CUSTOMER -e SUPPLIER -e "^$" | \
  uniq | \
  run "$EXA" -q -x -u tpcuser -P tpcuser -c localhost -autoCompletion OFF >/dev/null

cat "$TPCH_SQL_DIR/create_indices.sql" | \
  sed "s+END_OF_OPTIMIZATION+END_OF_REST_OPTIMIZATION+g" | \
  grep -i -v -e LINEITEM -e "^$" | \
  uniq | \
  run "$EXA" -q -x -u tpcuser -P tpcuser -c localhost -autoCompletion OFF >/dev/null

# analyze + integrity checks
cat "$TPCH_SQL_DIR/analyze_database.sql" | \
  run "$EXA" -q -x -u tpcuser -P tpcuser -c localhost -autoCompletion OFF >/dev/null

cat "$TPCH_SQL_DIR/referential_integrity.sql" | \
  run "$EXA" -q -x -u tpcuser -P tpcuser -c localhost -autoCompletion OFF >/dev/null

# files with @includes must run from their directory
pushd "$TPCH_SQL_DIR" >/dev/null
cat tables.sql | run "$EXA" -q -x -u tpcuser -P tpcuser -c localhost -autoCompletion OFF >/dev/null
cat dbcheck.sql | run "$EXA" -q -x -u tpcuser -P tpcuser -c localhost -autoCompletion OFF >/dev/null
cat postcheck_tables.sql | run "$EXA" -q -x -u tpcuser -P tpcuser -c localhost -autoCompletion OFF >/dev/null
popd >/dev/null

# ACID SQLs (file and pipe usage)
cat "$ACID_SQL_DIR/check_consistency.sql" | \
  run "$EXA" -q -x -u sys -P exasol -c localhost -autoCompletion off >/dev/null

run "$EXA" -q -x -u tpcuser -P tpcuser -c localhost -f "$ACID_SQL_DIR/clear_history.sql" >/dev/null
run "$EXA" -q -x -u tpcuser -P tpcuser -c localhost -f "$ACID_SQL_DIR/clear_history2.sql" >/dev/null

cat "$ACID_SQL_DIR/compare_history1.sql" | run "$EXA" -q -x -u tpcuser -P tpcuser -c localhost >/dev/null
cat "$ACID_SQL_DIR/compare_history2.sql" | run "$EXA" -q -x -u tpcuser -P tpcuser -c localhost >/dev/null
cat "$ACID_SQL_DIR/store_history.sql" | run "$EXA" -q -x -u tpcuser -P tpcuser -c localhost >/dev/null
cat "$ACID_SQL_DIR/store_history2.sql" | run "$EXA" -q -x -u tpcuser -P tpcuser -c localhost >/dev/null

if [[ -z "${EXAPLUS_TEST_QUIET:-}" ]]; then
  echo "OK"
fi
