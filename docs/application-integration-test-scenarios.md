# Application Integration Test Scenarios

This document proposes an end-to-end batch scenario that connects the COBOL
examples under `src/`. The shell script acts as a job controller: it prepares
the work directory, runs each program in order, and stops when a step fails.
It is a shell-based JCL-style example, not a proposal to add a mainframe JCL
runtime.

The scenario uses employees, departments, and salaries so that each processing
step has a concrete business purpose. Existing COBOL programs are reused where
possible. CSV, JSON, XML, SQLite, and ISAM adapters are additional work and are
marked as such in the flow.

## End-to-End Flow

```mermaid
flowchart TD
    job["run_integration_scenario.sh<br/>Create a clean work directory"]
    attendance_gen["generate_attendance<br/>Run month and seed"]
    run_month[/Run month: YYYY-MM/]

    subgraph inputs["1. Read fixed inputs"]
        emp_json[/input/emp.json/]
        emp_reader["transform_from_emp_json"]
        emp_in[(work/emp.dat)]

        salary_csv[/input/salary.csv/]
        salary_reader["transform_from_salary_csv<br/>Ignore file dates; stamp the previous month"]
        prev_salary[(work/previous_salary.dat)]

        dept_xml[/input/dept.xml/]
        xml_reader["transform_from_dept_xml"]
        dept_in[(work/dept.dat)]

        emp_json --> emp_reader --> emp_in
        salary_csv --> salary_reader --> prev_salary
        dept_xml --> xml_reader --> dept_in
    end

    emp_in -->|"Employee IDs"| attendance_gen
    run_month --> attendance_gen
    run_month --> salary_reader
    job --> emp_reader
    job --> salary_reader
    job --> xml_reader
    job --> attendance_gen

    subgraph salary_cycle["2. Create current-month salary with the ISAM salary master"]
        attendance_in[(work/attendance.dat)]
        isam_build["build_emp_isam<br/>Key: employee ID"]
        emp_isam[(work/emp.isam)]
        export_prev["export_emp_isam<br/>Before update"]
        prev_emp[(work/previous_month_emp.dat)]
        current_salary["update_salary_isam<br/>Apply overtime and absence adjustments"]
        export_current["export_emp_isam<br/>After update"]
        emp_current[(work/current_month_salary.dat)]
        csv_output["transform_to_salary_csv"]
        next_month_csv[/output/salary.csv/]

        emp_in --> isam_build
        prev_salary --> isam_build
        isam_build --> emp_isam
        emp_isam --> export_prev --> prev_emp
        attendance_gen --> attendance_in --> current_salary
        dept_in --> current_salary
        emp_isam <--> current_salary
        emp_isam --> export_current --> emp_current
        emp_current --> csv_output --> next_month_csv
    end

    job --> isam_build
    job --> current_salary

    subgraph employee_delta["3. Compare current and previous employees"]
        sort_current_id["sort_records<br/>Employee ID: start 1, length 4"]
        sort_previous_id["sort_records<br/>Employee ID: start 1, length 4"]
        normalize_current["transform_record_width<br/>100 to 50 bytes"]
        normalize_previous["transform_record_width<br/>100 to 50 bytes"]
        match_one["match_emp_one_to_one"]
        delta[(work/employee_comparison.dat)]

        emp_current --> sort_current_id --> normalize_current --> match_one
        prev_emp --> sort_previous_id --> normalize_previous --> match_one
        match_one --> delta
    end

    subgraph department["4. Create department summaries and details"]
        sort_employees_dept["sort_records<br/>Department ID: start 15, length 4"]
        normalize_employees["transform_record_width<br/>100 to 50 bytes"]
        group_dept["group_by_dept<br/>Member count and highest-paid employee"]
        dept_summary[(work/department_summary.dat)]
        sort_summary["sort_records<br/>Department ID: start 1, length 4"]
        normalize_summary["transform_record_width<br/>100 to 50 bytes"]
        match_many["match_emp_one_to_many"]
        dept_detail[(work/department_employee_detail.dat)]
        split_dept["separate_by_dept_multi<br/>One output file per department"]

        emp_current --> sort_employees_dept --> normalize_employees
        normalize_employees --> group_dept --> dept_summary --> sort_summary
        sort_summary --> normalize_summary --> match_many
        normalize_employees --> match_many --> dept_detail
        normalize_employees --> split_dept
    end

    subgraph reports["5. Create report outputs"]
        split_join_date["separate_by_join_date<br/>Split at a configured join date"]
        before_cutoff[(work/employees_before_cutoff.dat)]
        after_cutoff[(work/employees_on_or_after_cutoff.dat)]
        csv_report["transform_emp_to_csv<br/>CSV report"]
        report_before[(output/employees_before_cutoff.csv)]
        report_after[(output/employees_on_or_after_cutoff.csv)]

        emp_current --> split_join_date
        split_join_date --> before_cutoff --> csv_report --> report_before
        split_join_date --> after_cutoff --> csv_report --> report_after
    end

    subgraph persist["6. Compare with and save department summaries"]
        db[("state/summary.db<br/>SQLite: department summaries by month")]
        sqlite_read["read_dept_summary_db<br/>Previous month"]
        prev_dept_summary[(work/previous_department_summary.dat)]
        compare_summary["compare_dept_summary<br/>Member count and highest salary changes"]
        dept_change[(work/department_change.dat)]
        sqlite_write["write_dept_summary_db<br/>Current month"]

        db --> sqlite_read --> prev_dept_summary --> compare_summary
        dept_summary --> compare_summary --> dept_change
        dept_summary --> sqlite_write --> db
    end

    subgraph verify["7. Verify outputs"]
        checks["Check exit status, record counts, sort order,<br/>keys, totals, report contents, and persisted values"]
    end

    delta --> checks
    dept_change --> checks
    dept_detail --> checks
    split_dept --> checks
    report_before --> checks
    report_after --> checks
    db -->|"Read back persisted rows"| checks
    next_month_csv -->|"Verify CSV schema and values"| checks
```

## Programs

Names follow the existing `verb_object` convention. Each
program does one thing. New programs live in new category folders under `src/`.

| Program | Folder | Status | Role |
| --- | --- | --- | --- |
| `run_integration_scenario.sh` | `scripts/integration/` | Additional | Shell job controller (JCL-style). |
| `transform_from_emp_json` | `src/transforming/` | Additional | Convert `input/emp.json` to `emp.dat`. |
| `transform_from_dept_xml` | `src/transforming/` | Additional | Convert `input/dept.xml` to `dept.dat`. |
| `transform_from_salary_csv` | `src/transforming/` | Additional | Convert `input/salary.csv` to `previous_salary.dat`, ignoring its dates and stamping the previous month. |
| `generate_attendance` | `src/generating/` | Additional | Generate `attendance.dat` from `emp.dat`, the run month, and a seed. |
| `build_emp_isam` | `src/indexing/` | Additional | Build `emp.isam` from `emp.dat` and `previous_salary.dat`. |
| `update_salary_isam` | `src/indexing/` | Additional | Apply attendance adjustments to each ISAM record by key. |
| `export_emp_isam` | `src/indexing/` | Additional | Export ISAM records in key order (before and after the update). |
| `sort_records` | `src/sorting/` | Existing | Sort employee and summary files by employee ID or department ID. |
| `transform_record_width` | `src/transforming/` | Additional | Convert sorted 100-byte records to 50 bytes. |
| `match_emp_one_to_one` | `src/matching/` | Existing | Compare current and previous employee records by employee ID. |
| `group_by_dept` | `src/grouping/` | Existing | Create department member counts and highest-paid employee summaries. |
| `match_emp_one_to_many` | `src/matching/` | Existing | Join department summaries to the employees belonging to each department. |
| `separate_by_dept_multi` | `src/separating/` | Existing | Write one employee file per department. |
| `separate_by_join_date` | `src/separating/` | Existing | Split employees into two files at a configured join date. |
| `transform_emp_to_csv` | `src/transforming/` | Existing, rename of `transform_to_csv` | Convert employee records into a display-oriented CSV report. |
| `transform_to_salary_csv` | `src/transforming/` | Additional | Write `output/salary.csv` in the canonical schema. |
| `read_dept_summary_db` | `src/database/` | Additional | Read the previous month's department summaries from SQLite. |
| `compare_dept_summary` | `src/matching/` | Additional | Compare previous and current department summaries. |
| `write_dept_summary_db` | `src/database/` | Additional | Save the current month's department summaries to SQLite. |
| `generate_emp` | `src/generating/` | Existing | Optional large-volume input only; its random values are not suitable for exact expected results. |

The SQLite database lives outside the per-run work directory so a later run can
read the previous month's summaries. SQLite and the ISAM file are not shared:
ISAM serves the salary calculation, and SQLite serves the department summary
history.

## Fixed Inputs and Salary Generator

Keep these three inputs as small, checked-in fixtures. Each has its own reader
and is not regenerated for each run:

| File | Format | Content |
| --- | --- | --- |
| `input/emp.json` | JSON | Current employee roster: ID, name, department ID, join date. |
| `input/dept.xml` | XML | Department IDs and names. |
| `input/salary.csv` | CSV | Previous-month salaries: `salary_month,employee_id,monthly_salary`. |

The salary CSV reader ignores the `salary_month` values in the file and
stamps every row with the month before `--run-month` (for example
`2026-11` gives `202610`). This lets the same file be reused in any run month,
including the January-to-December year boundary, and lets the previous run's
output be fed back in unchanged. It writes a fixed-length intermediate record:
employee ID `9(004)`, salary month `9(006)` (`YYYYMM`), and monthly salary
`9(006)`, defined in a new copybook under `src/copies`. The load step
builds the ISAM salary master from this file.

Add one focused attendance generator that writes only the fixed-length
`work/attendance.dat`. It reads employee IDs from `emp.dat` and takes the run
month and a seed, so overtime hours and absence days vary per employee and per
month yet are reproducible for the same arguments. A suggested record is
employee ID `9(004)`, overtime hours `9(003)`, and absence days `9(002)`.
The generator does not read salaries, decide the calculation rule, create
other files, or write expected results. Tests that need exact values pass a
fixed seed, or use a small fixed table for a few employees.

The calculation rule belongs to the salary program. For example: current
salary = previous salary + overtime hours x hourly rate - absence days x daily
deduction, with the rates defined as documented constants. This rule is a
scenario decision and can be changed. An employee without an attendance record
has zero overtime and zero absence, so the salary is unchanged. An attendance
record for an unknown employee is reported as a warning.

`output/salary.csv` uses the same schema as `input/salary.csv`, with
unformatted numbers. Copy it over the input and run the job again with the
next run month: the salaries from the first run become the previous month, so
results change from run to run (different run month or seed gives different
attendance). Rebuild the ISAM file in each run's fresh work directory, and key
SQLite rows by month (replace the row for the same run month) so reruns do
not duplicate rows. The first run has no previous-month summaries and reports
every department as new.

Use `generate_emp.cbl` only when testing throughput or large-file behavior;
do not use its random records to assert exact join or aggregate results.

The employee record is 36 bytes before any example-specific padding. Its
employee ID starts at position 1 and its department ID starts at position 15.
The department record is 32 bytes before padding, with department ID at
position 1. Keep sort key positions and lengths aligned with the record layout
used by each program.

There is a record-width boundary to resolve when wiring these examples:
`sort_records.cbl` reads and writes 100-byte records, while the matching,
grouping, and separating examples shown here read 50-byte records. The flow
therefore includes a record-width normalization step after each sort. This can
be a small adapter or a carefully tested change to the sort program's record
width; do not pass the sort output directly to a 50-byte consumer without
verifying the runtime's line-sequential behavior.

## Suggested Test Cases

Use small, deterministic fixtures for functional tests. Include cases that
exercise:

- An employee with overtime, one with absences, one with both, and one with
  no attendance row (salary unchanged).
- An attendance record whose employee ID is not in `emp.json`, and a salary
  row whose employee ID is not in the roster.
- A salary CSV whose date column holds an arbitrary month, to confirm it is
  ignored.
- A chained run: feed the first run's `output/salary.csv` into a second run
  and confirm the salaries change as expected.
- A department with multiple employees, a department with one employee, and an
  employee whose department code is unknown.
- Employees on both sides of the join-date cutoff, including a record exactly
  on the cutoff.
- Empty input and malformed `salary.csv`, `emp.json`, or `dept.xml`
  records at the input boundaries.

For each run, verify that:

1. The shell job stops and reports failure if any step returns a non-zero exit
   status.
2. The employee comparison includes every employee from the carried-forward
   roster and identifies the expected salary changes.
3. Grouped department member counts and highest-paid employees match the
   fixture, and the one-to-many output contains the expected employee/
   department pairs.
4. The department split files and join-date split files together contain the
   expected records without duplication or loss.
5. CSV report values and record counts match the fixed input and the
   transformation rules.
6. SQLite contains one expected summary row per department and month, and
   the department changes match the previous and current summaries.
7. The reader stamps the month before the run month, including the year
   boundary, and a rerun does not duplicate SQLite rows.
8. In a chained run, the second run's previous-month salaries equal the first
   run's current-month salaries.

`separate_by_dept_multi` opens its department output files in extend mode.
Run each test in a fresh work directory, or explicitly clear prior outputs
before rerunning, so old records cannot make a test appear to pass.
