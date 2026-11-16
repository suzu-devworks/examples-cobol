#!/usr/bin/env bash
set -Eeuo pipefail

ROOT=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../.." && pwd -P)
BASE=$ROOT
RUN_MONTH=
SEED=1
CUTOFF=20200101
RESTART=STEP01
STEPS=(
    STEP01_EMPLOYEE_INPUT STEP02_DEPARTMENT_INPUT STEP03_SALARY_INPUT
    STEP04_ATTENDANCE STEP05_BUILD_ISAM STEP06_EXPORT_PREVIOUS
    STEP07_UPDATE_ISAM STEP08_EXPORT_CURRENT STEP09_SALARY_CSV
    STEP10_SORT_CURRENT STEP11_NORMALIZE_CURRENT STEP12_SORT_PREVIOUS
    STEP13_NORMALIZE_PREVIOUS STEP14_COMPARE_EMPLOYEES STEP15_SORT_DEPARTMENT
    STEP16_NORMALIZE_DEPARTMENT STEP17_GROUP_DEPARTMENT STEP18_SORT_SUMMARY
    STEP19_NORMALIZE_SUMMARY STEP20_MATCH_DEPARTMENT STEP21_SPLIT_DEPARTMENT
    STEP22_SPLIT_JOIN_DATE STEP23_REPORT_BEFORE STEP24_REPORT_AFTER
    STEP25_READ_PREVIOUS_SUMMARY STEP26_COMPARE_SUMMARY STEP27_WRITE_SUMMARY
    STEP28_VERIFY_SUMMARY STEP29_PUBLISH_REPORTS
)
TRANSFORM=$ROOT/src/transforming/build/bin
GENERATE=$ROOT/src/generating/build/bin
INDEX=$ROOT/src/indexing/build/bin
SORT=$ROOT/src/sorting/build/bin
MATCH=$ROOT/src/matching/build/bin
GROUP=$ROOT/src/grouping/build/bin
SEPARATE=$ROOT/src/separating/build/bin
DATABASE=$ROOT/src/database/build/bin

# Display the job arguments and defaults.
usage() {
    cat <<'EOF'
Usage: run_integration_scenario.sh --run-month YYYY-MM [options]
  --restart STEPnn   Restart at a numbered step (default: STEP01)
  --seed N           Attendance seed, 1-99999999 (default: 1)
  --cutoff YYYYMMDD  Join-date cutoff (default: 20200101)
  --base-dir DIR     Directory containing input/, work/, output/, state/
  --list-steps       List step numbers and names
  --help             Show this help
EOF
}

# Report a validation failure and show restart instructions when applicable.
fail() {
    printf 'ERROR: %s\n' "$*" >&2
    if [[ ${CURRENT_STEP:-JOB} == STEP* ]]; then
        report_restart
    fi
    exit 1
}

# Print a command that resumes the current STEP with the same parameters.
report_restart() {
    printf 'Restart with --run-month %s --restart %s' \
        "$RUN_MONTH" "$CURRENT_STEP" >&2
    printf ' --seed %s --cutoff %s --base-dir %q\n' \
        "$SEED" "$CUTOFF" "$BASE" >&2
}

# Report an unexpected command failure with its STEP and exit status.
on_error() {
    local rc=$?
    trap - ERR
    printf 'ERROR: %s failed (exit %d).\n' "$CURRENT_STEP" "$rc" >&2
    if [[ $CURRENT_STEP == STEP* ]]; then
        report_restart
    fi
    exit "$rc"
}

# Parse the job options, or display help or the STEP list.
parse_arguments() {
    local step
    while (($#)); do
        case $1 in
            --run-month|--restart|--seed|--cutoff|--base-dir)
                (($# >= 2)) || fail "Missing value for $1."
                case $1 in
                    --run-month) RUN_MONTH=$2 ;;
                    --restart) RESTART=$2 ;;
                    --seed) SEED=$2 ;;
                    --cutoff) CUTOFF=$2 ;;
                    --base-dir) BASE=$2 ;;
                esac
                shift 2
                ;;
            --list-steps)
                for step in "${STEPS[@]}"; do
                    printf '%s %s\n' "${step%%_*}" "${step#*_}"
                done
                exit 0
                ;;
            --help) usage; exit 0 ;;
            *) usage >&2; fail "Unknown argument: $1" ;;
        esac
    done
}

# Validate options and derive the month keys used by the job.
validate_arguments() {
    local year month cutoff_date
    [[ $RUN_MONTH =~ ^([0-9]{4})-([0-9]{2})$ ]] ||
        fail "Run month must be YYYY-MM."
    year=$((10#${BASH_REMATCH[1]}))
    month=$((10#${BASH_REMATCH[2]}))
    ((year >= 1 && month >= 1 && month <= 12)) ||
        fail "Invalid run month: $RUN_MONTH"
    ((year > 1 || month > 1)) ||
        fail "The previous month must have a year greater than zero."
    [[ $SEED =~ ^[0-9]{1,8}$ ]] || fail "Invalid attendance seed."
    ((10#$SEED >= 1)) || fail "Attendance seed must be at least 1."
    [[ $CUTOFF =~ ^[0-9]{8}$ ]] || fail "Cutoff must be YYYYMMDD."
    [[ $CUTOFF > 19000100 && $CUTOFF < 21001232 ]] ||
        fail "Cutoff must be between 19000101 and 21001231."
    cutoff_date="${CUTOFF:0:4}-${CUTOFF:4:2}-${CUTOFF:6:2}"
    [[ $(date -d "$cutoff_date" +%Y%m%d 2>/dev/null) == "$CUTOFF" ]] ||
        fail "Invalid cutoff date: $CUTOFF"
    [[ $RESTART =~ ^STEP([0-9]{2})$ ]] || fail "Invalid step: $RESTART"
    restart_number=$((10#${BASH_REMATCH[1]}))
    ((restart_number >= 1 && restart_number <= ${#STEPS[@]})) ||
        fail "Unknown step: $RESTART"
    [[ -d $BASE ]] || fail "Base directory does not exist: $BASE"
    BASE=$(cd -- "$BASE" && pwd -P)
    [[ $BASE != *[[:space:]]* ]] ||
        fail "Base directory must not contain whitespace."

    MONTH_KEY=${RUN_MONTH/-/}
    if ((month == 1)); then
        printf -v PREVIOUS_MONTH '%04d12' "$((year - 1))"
    else
        printf -v PREVIOUS_MONTH '%04d%02d' "$year" "$((month - 1))"
    fi
}

# Check that all COBOL programs have been built before starting the job.
check_programs() {
    local program category name
    for program in \
        transforming/transform_from_emp_csv \
        transforming/transform_from_dept_csv \
        transforming/transform_from_salary_csv \
        generating/generate_attendance \
        indexing/build_emp_isam indexing/export_emp_isam \
        indexing/update_salary_isam transforming/transform_to_salary_csv \
        sorting/sort_records transforming/transform_record_width \
        matching/match_emp_one_to_one grouping/group_by_dept \
        matching/match_emp_one_to_many separating/separate_by_dept_multi \
        separating/separate_by_join_date transforming/transform_emp_to_csv \
        database/read_dept_summary_db matching/compare_dept_summary \
        database/write_dept_summary_db; do
        category=${program%/*}
        name=${program#*/}
        [[ -x $ROOT/src/$category/build/bin/$name ]] ||
            fail "Missing executable: $program. Run make first."
    done
}

# Prepare the job directories and prevent concurrent runs.
prepare_job() {
    WORK=$BASE/work/$MONTH_KEY
    OUTPUT=$BASE/output
    STATE=$BASE/state
    mkdir -p -- "$BASE/work" "$OUTPUT" "$STATE"
    exec 9>"$BASE/work/.integration.lock"
    flock -n 9 || fail "Another integration job is running in $BASE."
    mkdir -p -- "$WORK"

    CURRENT_STEP=JOB
    trap on_error ERR
    DB=$STATE/summary.db
}

# Convert employee input records.
STEP01_EMPLOYEE_INPUT() {
    "$TRANSFORM/transform_from_emp_csv" "$BASE/input/emp.csv" "$WORK/emp.dat"
}

# Convert department input records.
STEP02_DEPARTMENT_INPUT() {
    "$TRANSFORM/transform_from_dept_csv" "$BASE/input/dept.csv" "$WORK/dept.dat"
}

# Convert the preceding month's salary records.
STEP03_SALARY_INPUT() {
    "$TRANSFORM/transform_from_salary_csv" "$BASE/input/salary.csv" \
        "$WORK/previous_salary.dat" --run-month "$RUN_MONTH"
}

# Generate attendance for the run month.
STEP04_ATTENDANCE() {
    "$GENERATE/generate_attendance" "$WORK/emp.dat" "$WORK/attendance.dat" \
        --run-month "$RUN_MONTH" --seed "$SEED"
}

# Build the preceding month's indexed employee file.
STEP05_BUILD_ISAM() {
    "$INDEX/build_emp_isam" "$WORK/emp.dat" "$WORK/previous_salary.dat" \
        "$WORK/previous_emp.isam"
}

# Export the preceding month's employee records.
STEP06_EXPORT_PREVIOUS() {
    "$INDEX/export_emp_isam" "$WORK/previous_emp.isam" \
        "$WORK/previous_month_emp.dat"
}

# Rebuild the ISAM file before updating so a retry cannot apply changes twice.
STEP07_UPDATE_ISAM() {
    "$INDEX/build_emp_isam" "$WORK/emp.dat" "$WORK/previous_salary.dat" \
        "$WORK/current_emp.isam"
    "$INDEX/update_salary_isam" "$WORK/current_emp.isam" \
        "$WORK/attendance.dat" "$WORK/dept.dat" --run-month "$RUN_MONTH"
}

# Export the current month's employee records.
STEP08_EXPORT_CURRENT() {
    "$INDEX/export_emp_isam" "$WORK/current_emp.isam" \
        "$WORK/current_month_salary.dat"
}

# Convert current salaries to CSV.
STEP09_SALARY_CSV() {
    "$TRANSFORM/transform_to_salary_csv" "$WORK/current_month_salary.dat" \
        "$WORK/salary.csv"
}

# Sort current employee records by employee ID.
STEP10_SORT_CURRENT() {
    "$SORT/sort_records" "$WORK/current_month_salary.dat" \
        "$WORK/current_by_id_100.dat" 1 4
}

# Restore the sorted current records to their original width.
STEP11_NORMALIZE_CURRENT() {
    "$TRANSFORM/transform_record_width" "$WORK/current_by_id_100.dat" \
        "$WORK/current_by_id.dat"
}

# Sort preceding employee records by employee ID.
STEP12_SORT_PREVIOUS() {
    "$SORT/sort_records" "$WORK/previous_month_emp.dat" \
        "$WORK/previous_by_id_100.dat" 1 4
}

# Restore the sorted preceding records to their original width.
STEP13_NORMALIZE_PREVIOUS() {
    "$TRANSFORM/transform_record_width" "$WORK/previous_by_id_100.dat" \
        "$WORK/previous_by_id.dat"
}

# Compare employee records across months.
STEP14_COMPARE_EMPLOYEES() {
    "$MATCH/match_emp_one_to_one" "$WORK/previous_by_id.dat" \
        "$WORK/current_by_id.dat" "$WORK/employee_comparison.dat"
}

# Sort current employee records by department.
STEP15_SORT_DEPARTMENT() {
    "$SORT/sort_records" "$WORK/current_month_salary.dat" \
        "$WORK/employees_by_dept_100.dat" 15 4
}

# Restore department-sorted records to their original width.
STEP16_NORMALIZE_DEPARTMENT() {
    "$TRANSFORM/transform_record_width" "$WORK/employees_by_dept_100.dat" \
        "$WORK/employees_by_dept.dat"
}

# Summarize employees by department.
STEP17_GROUP_DEPARTMENT() {
    "$GROUP/group_by_dept" "$WORK/employees_by_dept.dat" \
        "$WORK/department_summary.dat"
}

# Sort department summaries by department ID.
STEP18_SORT_SUMMARY() {
    "$SORT/sort_records" "$WORK/department_summary.dat" \
        "$WORK/department_summary_100.dat" 1 4
}

# Restore sorted summaries to their original width.
STEP19_NORMALIZE_SUMMARY() {
    "$TRANSFORM/transform_record_width" "$WORK/department_summary_100.dat" \
        "$WORK/sorted_department_summary.dat"
}

# Match department summaries to their employee records.
STEP20_MATCH_DEPARTMENT() {
    "$MATCH/match_emp_one_to_many" "$WORK/sorted_department_summary.dat" \
        "$WORK/employees_by_dept.dat" "$WORK/department_employee_detail.dat"
}

# Remove prior generated splits before running the append-mode separator.
STEP21_SPLIT_DEPARTMENT() {
    local directory=$WORK/departments file
    [[ ! -L $directory ]] || fail "Department output is a symlink."
    mkdir -p -- "$directory"
    for file in "$directory"/employee.[0-9][0-9][0-9][0-9]; do
        if [[ -e $file || -L $file ]]; then
            [[ -f $file && ! -L $file ]] ||
                fail "Unexpected department output: $file"
            rm -- "$file"
        fi
    done
    "$SEPARATE/separate_by_dept_multi" "$WORK/employees_by_dept.dat" \
        "$directory/employee"
}

# Split current employees by join date.
STEP22_SPLIT_JOIN_DATE() {
    "$SEPARATE/separate_by_join_date" "$WORK/current_month_salary.dat" \
        "$WORK/employees_before_cutoff.dat" \
        "$WORK/employees_on_or_after_cutoff.dat" "$CUTOFF"
}

# Convert employees who joined before the cutoff to CSV.
STEP23_REPORT_BEFORE() {
    "$TRANSFORM/transform_emp_to_csv" "$WORK/employees_before_cutoff.dat" \
        "$WORK/employees_before_cutoff.csv"
}

# Convert employees who joined on or after the cutoff to CSV.
STEP24_REPORT_AFTER() {
    "$TRANSFORM/transform_emp_to_csv" \
        "$WORK/employees_on_or_after_cutoff.dat" \
        "$WORK/employees_on_or_after_cutoff.csv"
}

# Read the preceding month's department summaries.
STEP25_READ_PREVIOUS_SUMMARY() {
    "$DATABASE/read_dept_summary_db" "$DB" "$PREVIOUS_MONTH" \
        "$WORK/previous_department_summary.dat"
}

# Compare department summaries across months.
STEP26_COMPARE_SUMMARY() {
    "$MATCH/compare_dept_summary" "$WORK/previous_department_summary.dat" \
        "$WORK/sorted_department_summary.dat" "$WORK/department_change.dat"
}

# Save the current month's department summaries.
STEP27_WRITE_SUMMARY() {
    "$DATABASE/write_dept_summary_db" "$DB" "$MONTH_KEY" \
        "$WORK/sorted_department_summary.dat"
}

# Compare persisted department records with the current sorted summaries.
STEP28_VERIFY_SUMMARY() {
    "$DATABASE/read_dept_summary_db" "$DB" "$MONTH_KEY" \
        "$WORK/readback_department_summary.dat"
    cut -b 1-32 "$WORK/sorted_department_summary.dat" \
        > "$WORK/expected_department_summary.dat"
    cmp -- "$WORK/expected_department_summary.dat" \
        "$WORK/readback_department_summary.dat"
}

# Publish each saved report through a temporary file in the output directory.
STEP29_PUBLISH_REPORTS() {
    local file temporary
    for file in salary.csv employees_before_cutoff.csv \
        employees_on_or_after_cutoff.csv; do
        temporary=$(mktemp "$OUTPUT/.publish.XXXXXXXX")
        if cp -- "$WORK/$file" "$temporary" &&
            mv -f -- "$temporary" "$OUTPUT/$file"; then
            continue
        fi
        rm -f -- "$temporary"
        return 1
    done
}

parse_arguments "$@"
validate_arguments
check_programs
prepare_job

printf 'JOB START: month=%s restart=%s seed=%s cutoff=%s\n' \
    "$RUN_MONTH" "$RESTART" "$SEED" "$CUTOFF"
for i in "${!STEPS[@]}"; do
    step_number=$((i + 1))
    ((step_number >= restart_number)) || continue
    CURRENT_STEP=${STEPS[i]%%_*}
    printf '\n===== %s %s START =====\n' "$CURRENT_STEP" "${STEPS[i]#*_}"
    "${STEPS[i]}"
    printf '===== %s NORMAL END =====\n' "$CURRENT_STEP"
done
printf '\nJOB NORMAL END: %s\n' "$RUN_MONTH"
