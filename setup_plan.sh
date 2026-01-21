#!/usr/bin/env bash
set -euo pipefail

# Usage:
#   ./setup_plan.sh /path/to/create_staging_fixed.sql /path/to/02_load_from_excel_new_no_truncate.sql
#
# Example:
#   ./setup_plan.sh create_staging_fixed.sql 02_load_from_excel_new_no_truncate.sql

if [[ $# -ne 2 ]]; then
  echo "Usage: $0 <create_sql> <load_sql>"
  exit 1
fi

CREATE_SQL="$1"
LOAD_SQL="$2"
DB_NAME="PLAN"

if [[ ! -f "$CREATE_SQL" ]]; then
  echo "Create SQL file not found: $CREATE_SQL"
  exit 1
fi

if [[ ! -f "$LOAD_SQL" ]]; then
  echo "Load SQL file not found: $LOAD_SQL"
  exit 1
fi

echo "==> Dropping database (if exists): ${DB_NAME}"
# Drop might fail if DB doesn't exist; ignore that case
db2 "CONNECT RESET" >/dev/null 2>&1 || true
db2 "DROP DATABASE ${DB_NAME}" >/dev/null 2>&1 || true

echo "==> Creating database: ${DB_NAME}"
db2 "CREATE DATABASE ${DB_NAME}"

echo "==> Connecting to database: ${DB_NAME}"
db2 "CONNECT TO ${DB_NAME}"

echo "==> Running create script: ${CREATE_SQL}"
db2 -tvf "$CREATE_SQL"

echo "==> Running load script: ${LOAD_SQL}"
db2 -tvf "$LOAD_SQL"

echo "==> Verifying row counts"
db2 -x "SELECT COUNT(*) AS COURSE_ASSIGNMENT_ROWS FROM SCHEMA_MAIN.COURSE_ASSIGNMENT"
db2 -x "SELECT COUNT(*) AS SUBJECT_ROWS FROM SCHEMA_MAIN.SUBJECT"
db2 -x "SELECT COUNT(*) AS STAFF_ROWS FROM SCHEMA_MAIN.ACADEMIC_STAFF"

echo "==> Done."
db2 "CONNECT RESET" >/dev/null

