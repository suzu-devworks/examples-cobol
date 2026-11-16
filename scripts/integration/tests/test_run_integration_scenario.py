import csv
import fcntl
import shutil
import subprocess
import tempfile
from pathlib import Path


ROOT = Path(__file__).resolve().parents[3]
JOB = ROOT / "scripts/integration/run_integration_scenario.sh"


def run_job(base, *args, success=True):
    """Run the job in an isolated base directory and verify its exit status."""
    result = subprocess.run(
        [JOB, "--run-month", "2026-11", "--base-dir", base, *args],
        capture_output=True, text=True, timeout=60,
    )
    assert (result.returncode == 0) == success, result.stdout + result.stderr
    return result


def complete_run_and_chained_month(base):
    """Verify outputs, month-to-month carryover, and report republishing."""
    result = run_job(base)
    assert "JOB NORMAL END" in result.stdout
    listing = subprocess.run(
        [JOB, "--base-dir", base, "--list-steps"],
        capture_output=True, text=True, timeout=10,
    )
    assert listing.returncode == 0, listing.stderr
    executed = [
        line[len("===== "):-len(" START =====")]
        for line in result.stdout.splitlines()
        if line.startswith("===== STEP") and line.endswith(" START =====")
    ]
    assert listing.stdout.splitlines() == executed
    assert [line.split()[0] for line in executed] == [
        f"STEP{i:02d}" for i in range(1, len(executed) + 1)
    ]
    work = base / "work/202611"
    with (base / "input/emp.csv").open(newline="") as stream:
        employees = list(csv.DictReader(stream))
    employee_ids = {row["employee_id"] for row in employees}
    department_ids = {row["department_id"] for row in employees}
    assert len(employees) == len(employee_ids) == 30
    with (base / "input/dept.csv").open(newline="") as stream:
        assert department_ids <= {row["department_id"] for row in csv.DictReader(stream)}
    with (base / "input/salary.csv").open(newline="") as stream:
        salary_rows = list(csv.DictReader(stream))
    salaries = {r["employee_id"]: int(r["monthly_salary"]) for r in salary_rows}
    assert len(salary_rows) == len(salaries) == len(employees)
    assert salaries.keys() == employee_ids
    attendance = (work / "attendance.dat").read_text().splitlines()
    assert len(attendance) == len(employees)
    expected = {
        row[:4]: salaries[row[:4]] + int(row[4:7]) * 25 - int(row[7:9]) * 80
        for row in attendance
    }
    assert expected.keys() == employee_ids
    with (base / "output/salary.csv").open(newline="") as stream:
        output = list(csv.DictReader(stream))
    assert len(output) == len(employees)
    assert {row["salary_month"] for row in output} == {"202611"}
    assert {r["employee_id"]: int(r["monthly_salary"]) for r in output} == expected
    november_csv = (base / "output/salary.csv").read_bytes()
    assert len((work / "employee_comparison.dat").read_text().splitlines()) == len(employees)
    assert len((work / "department_employee_detail.dat").read_text().splitlines()) == len(employees)
    assert sum(len(f.read_text().splitlines())
               for f in (work / "departments").glob("employee.*")) == len(employees)
    for report, before in (("employees_before_cutoff.csv", True),
                           ("employees_on_or_after_cutoff.csv", False)):
        with (base / "output" / report).open(newline="") as stream:
            ids = [row[0] for row in csv.reader(stream)]
        expected_ids = {
            row["employee_id"] for row in employees
            if (row["join_date"] < "20200101") == before
        }
        assert len(ids) == len(expected_ids) and set(ids) == expected_ids
    changes = (work / "department_change.dat").read_text().splitlines()
    assert [row[4] for row in changes] == ["N"] * len(department_ids)

    shutil.copyfile(base / "output/salary.csv", base / "input/salary.csv")
    result = subprocess.run(
        [JOB, "--run-month", "2026-12", "--base-dir", base],
        capture_output=True, text=True, timeout=60,
    )
    assert result.returncode == 0, result.stdout + result.stderr
    december = base / "work/202612"
    prior = (december / "previous_salary.dat").read_text().splitlines()
    assert {row[4:10] for row in prior} == {"202611"}
    assert {row[:4]: int(row[10:16]) for row in prior} == expected
    changes = (december / "department_change.dat").read_text().splitlines()
    assert len(changes) == len(department_ids) and all(row[4] in "CU" for row in changes)

    shutil.copyfile(base / "output/salary.csv", base / "input/salary.csv")
    result = subprocess.run(
        [JOB, "--run-month", "2027-01", "--base-dir", base],
        capture_output=True, text=True, timeout=60,
    )
    assert result.returncode == 0, result.stdout + result.stderr
    prior = (base / "work/202701/previous_salary.dat").read_text().splitlines()
    assert len(prior) == len(employees) and {row[4:10] for row in prior} == {"202612"}
    run_job(base, "--restart", "STEP29")
    assert (base / "output/salary.csv").read_bytes() == november_csv


def restart_after_failed_input(base):
    """Resume the failed input STEP after correcting its input."""
    salary = base / "input/salary.csv"
    original = salary.read_text()
    salary.write_text(original + "invalid\n")
    result = run_job(base, success=False)
    work = base / "work/202611"
    assert "STEP03 failed" in result.stderr
    assert "--restart STEP03" in result.stderr
    assert not (work / "attendance.dat").exists()

    salary.write_text(original)
    result = run_job(base, "--restart", "STEP03", "--seed", "2")
    assert "STEP01 EMPLOYEE_INPUT START" not in result.stdout
    assert "STEP03 SALARY_INPUT START" in result.stdout


def restart_without_saved_job(base):
    """Run a selected STEP using manually supplied prerequisite files."""
    work = base / "work/202611"
    work.mkdir(parents=True)
    reports = ("salary.csv", "employees_before_cutoff.csv",
               "employees_on_or_after_cutoff.csv")
    for report in reports:
        (work / report).write_text(report + "\n")
    result = run_job(base, "--restart", "STEP29")
    assert "STEP28 VERIFY_SUMMARY START" not in result.stdout
    assert "STEP29 PUBLISH_REPORTS START" in result.stdout
    for report in reports:
        assert (base / "output" / report).read_text() == report + "\n"


def restart_update_after_partial_failure(base):
    """Rebuild the ISAM file before retrying a partially applied update."""
    run_job(base)
    work = base / "work/202611"
    salary = work / "previous_salary.dat"
    attendance = work / "attendance.dat"
    original_salary = salary.read_text()
    original_attendance = attendance.read_text()
    expected_output = (base / "output/salary.csv").read_bytes()

    assert "0002202610250000" in original_salary
    salary.write_text(original_salary.replace("0002202610250000",
                                              "0002202610999999"))
    records = original_attendance.splitlines()
    records = ["000204000" if row.startswith("0002") else row
               for row in records]
    attendance.write_text("\n".join(records) + "\n")
    result = run_job(base, "--restart", "STEP07", success=False)
    assert "STEP07 failed" in result.stderr
    assert "Salary out of range" in result.stdout
    result = subprocess.run(
        [ROOT / "src/indexing/build/bin/export_emp_isam",
         work / "current_emp.isam", work / "partial_update.dat"],
        capture_output=True, text=True, timeout=10,
    )
    assert result.returncode == 0, result.stdout + result.stderr
    before = (work / "previous_month_emp.dat").read_text().splitlines()
    partial = (work / "partial_update.dat").read_text().splitlines()
    assert before[0][:4] == partial[0][:4] == "0001"
    assert before[0][36:42] != partial[0][36:42]

    salary.write_text(original_salary)
    attendance.write_text(original_attendance)
    run_job(base, "--restart", "STEP07")
    assert (base / "output/salary.csv").read_bytes() == expected_output


def restart_split_does_not_append_duplicates(base):
    """Replace department split files instead of appending on restart."""
    run_job(base)
    directory = base / "work/202611/departments"
    expected = {p.name: p.read_bytes() for p in directory.iterdir()}
    run_job(base, "--restart", "STEP21")
    assert {p.name: p.read_bytes() for p in directory.iterdir()} == expected


def restart_after_summary_rollback(base):
    """Keep prior database rows intact after an aborted summary update."""
    run_job(base)
    work = base / "work/202611"
    summary = work / "sorted_department_summary.dat"
    original = summary.read_text()
    rows = original.splitlines()
    rows[1] = "X" + rows[1][1:]
    summary.write_text("\n".join(rows) + "\n")
    result = run_job(base, "--restart", "STEP27", success=False)
    assert "STEP27 failed" in result.stderr
    assert "rolled back" in result.stdout

    readback = work / "after_failed_summary.dat"
    result = subprocess.run(
        [ROOT / "src/database/build/bin/read_dept_summary_db",
         base / "state/summary.db", "202611", readback],
        capture_output=True, text=True, timeout=10,
    )
    assert result.returncode == 0, result.stdout + result.stderr
    assert readback.read_bytes() == (
        work / "readback_department_summary.dat"
    ).read_bytes()
    summary.write_text(original)
    run_job(base, "--restart", "STEP27")


def restart_after_publish_failure(base):
    """Retry report publication without leaving temporary output files."""
    run_job(base)
    work = base / "work/202611"
    report = work / "employees_before_cutoff.csv"
    original = report.read_bytes()
    report.unlink()
    result = run_job(base, "--restart", "STEP29", success=False)
    assert "STEP29 failed" in result.stderr
    assert not list((base / "output").glob(".publish.*"))
    report.write_bytes(original)
    run_job(base, "--restart", "STEP29")
    assert (base / "output/employees_before_cutoff.csv").read_bytes() == original


def rejects_invalid_step_and_month(base):
    """Reject unknown STEPs and invalid run months."""
    run_job(base, "--restart", "STEP99", success=False)
    result = subprocess.run(
        [JOB, "--run-month", "2026-13", "--base-dir", base],
        capture_output=True, text=True, timeout=10,
    )
    assert result.returncode != 0 and "Invalid run month" in result.stderr


def empty_inputs(base):
    """Complete an empty run with an empty summary and header-only CSV."""
    (base / "input/emp.csv").write_text(
        "employee_id,employee_name,department_id,join_date\n"
    )
    (base / "input/dept.csv").write_text("department_id,department_name\n")
    (base / "input/salary.csv").write_text(
        "salary_month,employee_id,monthly_salary\n"
    )
    run_job(base)
    work = base / "work/202611"
    assert (work / "department_change.dat").read_bytes() == b""
    assert (work / "readback_department_summary.dat").read_bytes() == b""
    assert (base / "output/salary.csv").read_text().splitlines() == [
        "salary_month,employee_id,monthly_salary"
    ]


def restart_after_summary_verification_failure(base):
    """Resume verification after a mismatch without changing persisted rows."""
    run_job(base)
    work = base / "work/202611"
    summary = work / "sorted_department_summary.dat"
    original = summary.read_text()
    rows = original.splitlines()
    rows[0] = rows[0][:4] + "X" + rows[0][5:]
    summary.write_text("\n".join(rows) + "\n")
    result = run_job(base, "--restart", "STEP28", success=False)
    assert "STEP28 failed" in result.stderr
    summary.write_text(original)
    run_job(base, "--restart", "STEP28")


def rejects_concurrent_job(base):
    """Prevent two jobs from changing shared state in the same base directory."""
    work = base / "work"
    work.mkdir()
    with (work / ".integration.lock").open("w") as lock:
        fcntl.flock(lock, fcntl.LOCK_EX | fcntl.LOCK_NB)
        result = run_job(base, success=False)
        assert "Another integration job is running" in result.stderr
        assert not (work / "202611").exists()
    run_job(base)


if __name__ == "__main__":
    for test in (complete_run_and_chained_month, restart_after_failed_input,
                 restart_without_saved_job,
                 restart_update_after_partial_failure,
                 restart_split_does_not_append_duplicates,
                 restart_after_summary_rollback, restart_after_publish_failure,
                 rejects_invalid_step_and_month, empty_inputs,
                 restart_after_summary_verification_failure,
                 rejects_concurrent_job):
        with tempfile.TemporaryDirectory(prefix="cobol-job-test-") as directory:
            base = Path(directory)
            shutil.copytree(ROOT / "input", base / "input")
            test(base)
        print(f"PASS: {test.__name__}")
