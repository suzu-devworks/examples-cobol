#!/usr/bin/env bash
set -e

ROOT=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../.." && pwd -P)

GENERATE=$ROOT/src/generating/build/bin
SORT=$ROOT/src/sorting/build/bin
REPORT=$ROOT/src/reporting/build/bin
WORK=$ROOT/temp

COUNT=1000

STEPS=(
    STEP01_GENERATE_EMPLOYEES
    STEP02_SORT_EMPLOYEES
    STEP03_WRITE_EMPLOYEE_REPORT
)

STEP01_GENERATE_EMPLOYEES() {
    "$GENERATE/generate_emp" "$WORK/emp.dat" "$COUNT"
}

STEP02_SORT_EMPLOYEES() {
    "$SORT/sort_records" "$WORK/emp.dat" \
        "$WORK/emp_sorted.dat" 15 4
}

STEP03_WRITE_EMPLOYEE_REPORT() {
    "$REPORT/report_emp_by_dept" "$WORK/emp_sorted.dat" \
        "$WORK/emp_report.txt"
}

printf 'JOB START\n'
for i in "${!STEPS[@]}"; do
    step_number=$((i + 1))
    CURRENT_STEP=${STEPS[i]%%_*}
    printf '\n===== %s %s START =====\n' "$CURRENT_STEP" "${STEPS[i]#*_}"
    "${STEPS[i]}"
    printf '===== %s NORMAL END =====\n' "$CURRENT_STEP"
done
printf '\nJOB NORMAL END\n'
