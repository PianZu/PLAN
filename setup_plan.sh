#!/usr/bin/env bash
set -Eeuo pipefail

# Usage:
#   ./setup_plan.sh <create_sql> <load_sql>
# Example:
#   ./setup_plan.sh create_staging.sql 02_load_from_excel.sql

if [[ $# -ne 2 ]]; then
  echo "Usage: $0 <create_sql> <load_sql>"
  exit 1
fi

CREATE_SQL="$1"
LOAD_SQL="$2"
DB_NAME="PLAN"

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
VIEWS_SQL="${SCRIPT_DIR}/create_views.sql"

LOG_DIR="${SCRIPT_DIR}/logs"
mkdir -p "$LOG_DIR"
CREATE_LOG="${LOG_DIR}/create.log"
VIEWS_LOG="${LOG_DIR}/views.log"
LOAD_LOG="${LOG_DIR}/load.log"

trap 'echo "ERROR at line $LINENO: $BASH_COMMAND" >&2' ERR

require_file() {
  [[ -f "$1" ]] || { echo "File not found: $1" >&2; exit 1; }
}

require_file "$CREATE_SQL"
require_file "$LOAD_SQL"
require_file "$VIEWS_SQL"

echo "==> Script dir: $SCRIPT_DIR"
echo "==> Views file: $VIEWS_SQL"

echo "==> Dropping database (if exists): ${DB_NAME}"
db2 "CONNECT RESET" >/dev/null 2>&1 || true
db2 "DROP DATABASE ${DB_NAME}" >/dev/null 2>&1 || true

echo "==> Creating database: ${DB_NAME}"
db2 "CREATE DATABASE ${DB_NAME}"

echo "==> Connecting to database: ${DB_NAME}"
db2 "CONNECT TO ${DB_NAME}"

echo "==> Running create script: ${CREATE_SQL}"
db2 -svtz"$CREATE_LOG" -f "$CREATE_SQL"

echo "======================================"
echo "==> Creating views from: ${VIEWS_SQL}"
echo "======================================"
db2 -svtz"$VIEWS_LOG" -f "$VIEWS_SQL"

echo "==> Verifying views exist in SCHEMA_MAIN (after view creation)"
db2 -x "SELECT COUNT(*) AS VIEW_COUNT FROM SYSCAT.VIEWS WHERE VIEWSCHEMA='SCHEMA_MAIN'"

echo "==> Running load script: ${LOAD_SQL}"
# LOAD can return non-zero RC due to warnings even if it loaded data.
# Allow non-zero RC, but fail if there are negative SQLCODEs in the log.
set +e
db2 -svtz"$LOAD_LOG" -f "$LOAD_SQL"
LOAD_RC=$?
set -e

if grep -qE 'SQLCODE=-[0-9]+' "$LOAD_LOG"; then
  echo "ERROR: Load script produced SQL errors (see $LOAD_LOG)"
  exit 1
fi

if [[ $LOAD_RC -ne 0 ]]; then
  echo "NOTE: Load returned RC=$LOAD_RC (likely warnings). Continuing."
fi

echo "==> Listing views in SCHEMA_MAIN (first 50)"
db2 -x "SELECT VIEWNAME FROM SYSCAT.VIEWS WHERE VIEWSCHEMA='SCHEMA_MAIN' ORDER BY VIEWNAME FETCH FIRST 50 ROWS ONLY"

echo "==> Verifying row counts"
db2 -x "SELECT COUNT(*) AS COURSE_ASSIGNMENT_ROWS FROM SCHEMA_MAIN.COURSE_ASSIGNMENT"
db2 -x "SELECT COUNT(*) AS SUBJECT_ROWS FROM SCHEMA_MAIN.SUBJECT"
db2 -x "SELECT COUNT(*) AS STAFF_ROWS FROM SCHEMA_MAIN.ACADEMIC_STAFF"

echo "==> Done."
db2 "CONNECT RESET" >/dev/null
