       IDENTIFICATION DIVISION.
       PROGRAM-ID. update_salary_isam.

       ENVIRONMENT DIVISION.
       INPUT-OUTPUT SECTION.
       FILE-CONTROL.
           SELECT IN1-FILE     ASSIGN TO WS-IN1-FILE-PATH
                               ORGANIZATION IS LINE SEQUENTIAL
                               FILE STATUS IS WS-IN1-FILE-STATUS.
           SELECT IN2-FILE     ASSIGN TO WS-IN2-FILE-PATH
                               ORGANIZATION IS LINE SEQUENTIAL
                               FILE STATUS IS WS-IN2-FILE-STATUS.
           SELECT IO1-FILE     ASSIGN TO WS-IO1-FILE-PATH
                               ORGANIZATION IS INDEXED
                               ACCESS MODE IS DYNAMIC
                               RECORD KEY IS IO1-EMP-ID
                               FILE STATUS IS WS-IO1-FILE-STATUS.

       DATA DIVISION.
       FILE SECTION.
       FD  IN1-FILE.
       01  IN1-REC                 PIC X(1024).
       FD  IN2-FILE.
       01  IN2-REC                 PIC X(1024).
       FD  IO1-FILE.
       01  IO1-EMP-SALARY-REC.
       COPY emp_rec
           REPLACING ==:PREFIX:== BY ==IO1==.
           03  IO1-EMP-SALARY-MONTH PIC 9(006).

       WORKING-STORAGE SECTION.
       01  WS-ARGS.
           05  WS-ARG-COUNT        PIC 9(002) VALUE 0.
           05  WS-IO1-FILE-PATH    PIC X(1024) VALUE SPACES.
           05  WS-IN1-FILE-PATH    PIC X(1024) VALUE SPACES.
           05  WS-IN2-FILE-PATH    PIC X(1024) VALUE SPACES.
           05  WS-RUN-MONTH-OPTION PIC X(1024) VALUE SPACES.
           05  WS-RUN-MONTH-ARG    PIC X(1024) VALUE SPACES.

       01  WS-COUNTERS.
           05  WS-IN1-COUNT        PIC 9(006) VALUE 0.
           05  WS-IN2-COUNT        PIC 9(006) VALUE 0.
           05  WS-IO1-READ-COUNT   PIC 9(006) VALUE 0.
           05  WS-IO1-UPDATE-COUNT PIC 9(006) VALUE 0.
           05  WS-SALARY-UPDATE-COUNT PIC 9(006) VALUE 0.
           05  WS-UNKNOWN-ATTENDANCE-COUNT PIC 9(006) VALUE 0.
           05  WS-MISSING-DEPT-COUNT PIC 9(006) VALUE 0.

       01  WS-FILE-STATUSES.
       COPY file_statuses
           REPLACING ==:PREFIX:== BY ==WS-IN1==.
       COPY file_statuses
           REPLACING ==:PREFIX:== BY ==WS-IN2==.
       COPY file_statuses
           REPLACING ==:PREFIX:== BY ==WS-IO1==.

       01  WS-IO-ERROR-DATA.
       COPY file_io_error.

       01  WS-IN1-ATTENDANCE-DATA.
       COPY attendance_rec
           REPLACING ==:PREFIX:== BY ==WS-IN1==.

       01  WS-IN2-DEPARTMENT-DATA.
       COPY dept_master_rec
           REPLACING ==:PREFIX:== BY ==WS-IN2==.

       01  WS-RUN-MONTH-VALUES.
           05  WS-RUN-YEAR         PIC 9(004) VALUE 0.
           05  WS-RUN-MONTH        PIC 9(002) VALUE 0.
           05  WS-RUN-MONTH-NUM    PIC 9(006) VALUE 0.

       01  WS-LOOKUP-TABLES.
           05  WS-ATTENDANCE-TABLE.
               10  WS-ATTENDANCE-ENTRY OCCURS 10000 TIMES.
                   15  WS-ATTENDANCE-PRESENT PIC X.
                   15  WS-ATTENDANCE-FOUND PIC X.
                   15  WS-ATTENDANCE-HOURS PIC 9(003).
                   15  WS-ATTENDANCE-DAYS PIC 9(002).
           05  WS-DEPARTMENT-TABLE.
               10  WS-DEPARTMENT-ENTRY OCCURS 10000 TIMES.
                   15  WS-DEPARTMENT-PRESENT PIC X.
                   15  WS-DEPARTMENT-NAME PIC X(010).

       01  WS-CALCULATION.
           05  WS-EMPLOYEE-ID      PIC 9(004) VALUE 0.
           05  WS-DEPARTMENT-ID    PIC 9(004) VALUE 0.
           05  WS-LOOKUP-INDEX     PIC 9(005) COMP-5 VALUE 0.
           05  WS-NEW-SALARY       PIC S9(006) VALUE 0.
           05  WS-IO1-EOF          PIC X VALUE "N".

       PROCEDURE DIVISION.
           PERFORM INITIALIZE-PROCESS
           PERFORM MAIN-PROCESS
           PERFORM TERMINATE-PROCESS
           STOP RUN.

       INITIALIZE-PROCESS.
           ACCEPT WS-ARG-COUNT FROM ARGUMENT-NUMBER
           IF WS-ARG-COUNT NOT = 5
               PERFORM DISPLAY-USAGE
               MOVE 1 TO RETURN-CODE
               STOP RUN
           END-IF

           ACCEPT WS-IO1-FILE-PATH FROM ARGUMENT-VALUE
           ACCEPT WS-IN1-FILE-PATH FROM ARGUMENT-VALUE
           ACCEPT WS-IN2-FILE-PATH FROM ARGUMENT-VALUE
           ACCEPT WS-RUN-MONTH-OPTION FROM ARGUMENT-VALUE
           ACCEPT WS-RUN-MONTH-ARG FROM ARGUMENT-VALUE

           IF WS-IO1-FILE-PATH = SPACES OR
              WS-IN1-FILE-PATH = SPACES OR
              WS-IN2-FILE-PATH = SPACES OR
              WS-IO1-FILE-PATH = WS-IN1-FILE-PATH OR
              WS-IO1-FILE-PATH = WS-IN2-FILE-PATH OR
              WS-IN1-FILE-PATH = WS-IN2-FILE-PATH OR
              WS-RUN-MONTH-OPTION NOT = "--run-month" OR
              FUNCTION LENGTH(
                  FUNCTION TRIM(WS-RUN-MONTH-ARG)) NOT = 7 OR
              WS-RUN-MONTH-ARG(1:4) IS NOT NUMERIC OR
              WS-RUN-MONTH-ARG(5:1) NOT = "-" OR
              WS-RUN-MONTH-ARG(6:2) IS NOT NUMERIC
               PERFORM INVALID-ARGUMENTS
           END-IF

           MOVE WS-RUN-MONTH-ARG(1:4) TO WS-RUN-YEAR
           MOVE WS-RUN-MONTH-ARG(6:2) TO WS-RUN-MONTH
           IF WS-RUN-YEAR = 0 OR WS-RUN-MONTH < 1 OR
              WS-RUN-MONTH > 12
               PERFORM INVALID-ARGUMENTS
           END-IF
           COMPUTE WS-RUN-MONTH-NUM =
               WS-RUN-YEAR * 100 + WS-RUN-MONTH

           DISPLAY "Employee salary ISAM update started."
           DISPLAY "ISAM FILE:      "
                   FUNCTION TRIM(WS-IO1-FILE-PATH)
           DISPLAY "ATTENDANCE FILE: "
                   FUNCTION TRIM(WS-IN1-FILE-PATH)
           DISPLAY "DEPARTMENT FILE: "
                   FUNCTION TRIM(WS-IN2-FILE-PATH)
           DISPLAY "RUN MONTH:      " WS-RUN-MONTH-ARG(1:7)

           INITIALIZE WS-LOOKUP-TABLES
           PERFORM OPEN-IN1-FILE
           PERFORM OPEN-IN2-FILE
           PERFORM OPEN-IO1-FILE.

       DISPLAY-USAGE.
           DISPLAY "Usage: update_salary_isam"
           DISPLAY "       [ISAM_FILE] [ATTENDANCE_FILE]"
           DISPLAY "       [DEPARTMENT_FILE] --run-month [YYYY-MM]".

       INVALID-ARGUMENTS.
           DISPLAY "ERROR: Invalid arguments or run month."
           PERFORM DISPLAY-USAGE
           MOVE 1 TO RETURN-CODE
           STOP RUN.

       INVALID-ATTENDANCE-RECORD.
           DISPLAY "ERROR: Invalid attendance record at line "
                   WS-IN1-COUNT "."
           MOVE 1 TO RETURN-CODE
           STOP RUN.

       INVALID-DEPARTMENT-RECORD.
           DISPLAY "ERROR: Invalid department record at line "
                   WS-IN2-COUNT "."
           MOVE 1 TO RETURN-CODE
           STOP RUN.

       MAIN-PROCESS.
           PERFORM LOAD-ATTENDANCE
           PERFORM LOAD-DEPARTMENTS
           PERFORM UPDATE-ISAM-RECORDS
           PERFORM REPORT-UNKNOWN-ATTENDANCE.

       LOAD-ATTENDANCE.
           PERFORM READ-IN1-FILE
           PERFORM UNTIL WS-IN1-FILE-EOF
               PERFORM SAVE-ATTENDANCE-RECORD
               PERFORM READ-IN1-FILE
           END-PERFORM.

       SAVE-ATTENDANCE-RECORD.
           IF IN1-REC(1:9) IS NOT NUMERIC OR
              IN1-REC(10:1015) NOT = SPACES
               PERFORM INVALID-ATTENDANCE-RECORD
           END-IF

           MOVE IN1-REC(1:4) TO WS-EMPLOYEE-ID
           MOVE IN1-REC(5:3) TO WS-IN1-OVERTIME-HOURS
           MOVE IN1-REC(8:2) TO WS-IN1-ABSENCE-DAYS
           IF WS-IN1-OVERTIME-HOURS > 40 OR
              WS-IN1-ABSENCE-DAYS > 5
               PERFORM INVALID-ATTENDANCE-RECORD
           END-IF

           COMPUTE WS-LOOKUP-INDEX = WS-EMPLOYEE-ID + 1
           IF WS-ATTENDANCE-PRESENT(WS-LOOKUP-INDEX) = "Y"
               DISPLAY "ERROR: Duplicate attendance for employee ID "
                       WS-EMPLOYEE-ID "."
               MOVE 1 TO RETURN-CODE
               STOP RUN
           END-IF
           MOVE "Y" TO WS-ATTENDANCE-PRESENT(WS-LOOKUP-INDEX)
           MOVE WS-IN1-OVERTIME-HOURS
             TO WS-ATTENDANCE-HOURS(WS-LOOKUP-INDEX)
           MOVE WS-IN1-ABSENCE-DAYS
             TO WS-ATTENDANCE-DAYS(WS-LOOKUP-INDEX).

       LOAD-DEPARTMENTS.
           PERFORM READ-IN2-FILE
           PERFORM UNTIL WS-IN2-FILE-EOF
               PERFORM SAVE-DEPARTMENT-RECORD
               PERFORM READ-IN2-FILE
           END-PERFORM.

       SAVE-DEPARTMENT-RECORD.
           IF IN2-REC(1:4) IS NOT NUMERIC OR
              IN2-REC(5:10) = SPACES OR
              IN2-REC(15:1010) NOT = SPACES
               PERFORM INVALID-DEPARTMENT-RECORD
           END-IF

           MOVE IN2-REC(1:4) TO WS-DEPARTMENT-ID
           COMPUTE WS-LOOKUP-INDEX = WS-DEPARTMENT-ID + 1
           IF WS-DEPARTMENT-PRESENT(WS-LOOKUP-INDEX) = "Y"
               DISPLAY "ERROR: Duplicate department ID "
                       WS-DEPARTMENT-ID "."
               MOVE 1 TO RETURN-CODE
               STOP RUN
           END-IF
           MOVE "Y" TO WS-DEPARTMENT-PRESENT(WS-LOOKUP-INDEX)
           MOVE IN2-REC(5:10)
             TO WS-DEPARTMENT-NAME(WS-LOOKUP-INDEX).

       UPDATE-ISAM-RECORDS.
           MOVE ZERO TO IO1-EMP-ID
           START IO1-FILE KEY IS NOT LESS THAN IO1-EMP-ID
           EVALUATE TRUE
               WHEN WS-IO1-FILE-OK
                   PERFORM READ-NEXT-IO1-RECORD
                   PERFORM UNTIL WS-IO1-EOF = "Y"
                       PERFORM UPDATE-ISAM-RECORD
                       PERFORM READ-NEXT-IO1-RECORD
                   END-PERFORM
               WHEN WS-IO1-FILE-STATUS = "23"
                   CONTINUE
               WHEN OTHER
                   MOVE "IO1-FILE" TO WS-IO-ERROR-FILE
                   MOVE WS-IO1-FILE-STATUS TO WS-IO-ERROR-CODE
                   PERFORM FILE-IO-ERROR
           END-EVALUATE.

       UPDATE-ISAM-RECORD.
           PERFORM VALIDATE-ISAM-RECORD
           MOVE IO1-EMP-ID TO WS-EMPLOYEE-ID
           MOVE IO1-EMP-DEPT-ID TO WS-DEPARTMENT-ID
           COMPUTE WS-LOOKUP-INDEX = WS-DEPARTMENT-ID + 1
           IF WS-DEPARTMENT-PRESENT(WS-LOOKUP-INDEX) = "Y"
               MOVE WS-DEPARTMENT-NAME(WS-LOOKUP-INDEX)
                 TO IO1-EMP-DEPT-NAME
           ELSE
               MOVE SPACES TO IO1-EMP-DEPT-NAME
               ADD 1 TO WS-MISSING-DEPT-COUNT
           END-IF

           COMPUTE WS-LOOKUP-INDEX = WS-EMPLOYEE-ID + 1
           IF WS-ATTENDANCE-PRESENT(WS-LOOKUP-INDEX) = "Y"
               MOVE WS-ATTENDANCE-HOURS(WS-LOOKUP-INDEX)
                 TO WS-IN1-OVERTIME-HOURS
               MOVE WS-ATTENDANCE-DAYS(WS-LOOKUP-INDEX)
                 TO WS-IN1-ABSENCE-DAYS
               COMPUTE WS-NEW-SALARY =
                   IO1-EMP-SALARY +
                   WS-IN1-OVERTIME-HOURS * 25 -
                   WS-IN1-ABSENCE-DAYS * 80
                   ON SIZE ERROR
                       DISPLAY "ERROR: Salary out of range: "
                               WS-EMPLOYEE-ID "."
                       MOVE 1 TO RETURN-CODE
                       STOP RUN
               END-COMPUTE
               IF WS-NEW-SALARY < 0
                   DISPLAY "ERROR: Salary out of range for employee ID "
                           WS-EMPLOYEE-ID "."
                   MOVE 1 TO RETURN-CODE
                   STOP RUN
               END-IF
               MOVE WS-NEW-SALARY TO IO1-EMP-SALARY
               MOVE "Y" TO WS-ATTENDANCE-FOUND(WS-LOOKUP-INDEX)
               ADD 1 TO WS-SALARY-UPDATE-COUNT
           END-IF

           MOVE WS-RUN-MONTH-NUM TO IO1-EMP-SALARY-MONTH
           PERFORM REWRITE-IO1-RECORD.

       VALIDATE-ISAM-RECORD.
           IF IO1-EMP-ID IS NOT NUMERIC OR
              IO1-EMP-DEPT-ID IS NOT NUMERIC OR
              IO1-EMP-SALARY IS NOT NUMERIC OR
              IO1-EMP-SALARY-MONTH IS NOT NUMERIC
               DISPLAY "ERROR: Invalid employee ISAM record."
               MOVE 1 TO RETURN-CODE
               STOP RUN
           END-IF.

       REPORT-UNKNOWN-ATTENDANCE.
           PERFORM VARYING WS-LOOKUP-INDEX FROM 1 BY 1
               UNTIL WS-LOOKUP-INDEX > 10000
               IF WS-ATTENDANCE-PRESENT(WS-LOOKUP-INDEX) = "Y" AND
                  WS-ATTENDANCE-FOUND(WS-LOOKUP-INDEX) NOT = "Y"
                   COMPUTE WS-EMPLOYEE-ID = WS-LOOKUP-INDEX - 1
                   DISPLAY "WARNING: Attendance employee ID not found: "
                           WS-EMPLOYEE-ID "."
                   ADD 1 TO WS-UNKNOWN-ATTENDANCE-COUNT
               END-IF
           END-PERFORM.

       TERMINATE-PROCESS.
           PERFORM CLOSE-IN1-FILE
           PERFORM CLOSE-IN2-FILE
           PERFORM CLOSE-IO1-FILE
           IF WS-MISSING-DEPT-COUNT > 0
               DISPLAY "WARNING: Employees with unknown department: "
                       WS-MISSING-DEPT-COUNT
           END-IF
           DISPLAY "SUCCESS: Employee salary ISAM update completed."
           DISPLAY "------------------------------"
           DISPLAY "INPUT1 READ COUNT:     " WS-IN1-COUNT
           DISPLAY "INPUT2 READ COUNT:     " WS-IN2-COUNT
           DISPLAY "IO1 READ COUNT:        " WS-IO1-READ-COUNT
           DISPLAY "IO1 UPDATE COUNT:      " WS-IO1-UPDATE-COUNT
           DISPLAY "SALARY UPDATE COUNT:   " WS-SALARY-UPDATE-COUNT
           DISPLAY "UNKNOWN ATTENDANCE:    "
                   WS-UNKNOWN-ATTENDANCE-COUNT
           DISPLAY "------------------------------".

       OPEN-IN1-FILE.
           OPEN INPUT IN1-FILE
           IF NOT WS-IN1-FILE-OK
               MOVE "IN1-FILE" TO WS-IO-ERROR-FILE
               MOVE WS-IN1-FILE-STATUS TO WS-IO-ERROR-CODE
               PERFORM FILE-IO-ERROR
           END-IF.

       CLOSE-IN1-FILE.
           CLOSE IN1-FILE
           IF NOT WS-IN1-FILE-OK
               MOVE "IN1-FILE" TO WS-IO-ERROR-FILE
               MOVE WS-IN1-FILE-STATUS TO WS-IO-ERROR-CODE
               PERFORM FILE-IO-ERROR
           END-IF.

       READ-IN1-FILE.
           READ IN1-FILE
           EVALUATE TRUE
               WHEN WS-IN1-FILE-OK
                   ADD 1 TO WS-IN1-COUNT
               WHEN WS-IN1-FILE-EOF
                   MOVE HIGH-VALUES TO IN1-REC
               WHEN OTHER
                   MOVE "IN1-FILE" TO WS-IO-ERROR-FILE
                   MOVE WS-IN1-FILE-STATUS TO WS-IO-ERROR-CODE
                   PERFORM FILE-IO-ERROR
           END-EVALUATE.

       OPEN-IN2-FILE.
           OPEN INPUT IN2-FILE
           IF NOT WS-IN2-FILE-OK
               MOVE "IN2-FILE" TO WS-IO-ERROR-FILE
               MOVE WS-IN2-FILE-STATUS TO WS-IO-ERROR-CODE
               PERFORM FILE-IO-ERROR
           END-IF.

       CLOSE-IN2-FILE.
           CLOSE IN2-FILE
           IF NOT WS-IN2-FILE-OK
               MOVE "IN2-FILE" TO WS-IO-ERROR-FILE
               MOVE WS-IN2-FILE-STATUS TO WS-IO-ERROR-CODE
               PERFORM FILE-IO-ERROR
           END-IF.

       READ-IN2-FILE.
           READ IN2-FILE
           EVALUATE TRUE
               WHEN WS-IN2-FILE-OK
                   ADD 1 TO WS-IN2-COUNT
               WHEN WS-IN2-FILE-EOF
                   MOVE HIGH-VALUES TO IN2-REC
               WHEN OTHER
                   MOVE "IN2-FILE" TO WS-IO-ERROR-FILE
                   MOVE WS-IN2-FILE-STATUS TO WS-IO-ERROR-CODE
                   PERFORM FILE-IO-ERROR
           END-EVALUATE.

       OPEN-IO1-FILE.
           OPEN I-O IO1-FILE
           IF NOT WS-IO1-FILE-OK
               MOVE "IO1-FILE" TO WS-IO-ERROR-FILE
               MOVE WS-IO1-FILE-STATUS TO WS-IO-ERROR-CODE
               PERFORM FILE-IO-ERROR
           END-IF.

       CLOSE-IO1-FILE.
           CLOSE IO1-FILE
           IF NOT WS-IO1-FILE-OK
               MOVE "IO1-FILE" TO WS-IO-ERROR-FILE
               MOVE WS-IO1-FILE-STATUS TO WS-IO-ERROR-CODE
               PERFORM FILE-IO-ERROR
           END-IF.

       READ-NEXT-IO1-RECORD.
           READ IO1-FILE NEXT RECORD
           EVALUATE TRUE
               WHEN WS-IO1-FILE-OK
                   MOVE "N" TO WS-IO1-EOF
                   ADD 1 TO WS-IO1-READ-COUNT
               WHEN WS-IO1-FILE-EOF
                   MOVE HIGH-VALUES TO IO1-EMP-SALARY-REC
                   MOVE "Y" TO WS-IO1-EOF
               WHEN OTHER
                   MOVE "IO1-FILE" TO WS-IO-ERROR-FILE
                   MOVE WS-IO1-FILE-STATUS TO WS-IO-ERROR-CODE
                   PERFORM FILE-IO-ERROR
           END-EVALUATE.

       REWRITE-IO1-RECORD.
           REWRITE IO1-EMP-SALARY-REC
           IF NOT WS-IO1-FILE-OK
               MOVE "IO1-FILE" TO WS-IO-ERROR-FILE
               MOVE WS-IO1-FILE-STATUS TO WS-IO-ERROR-CODE
               PERFORM FILE-IO-ERROR
           END-IF
           ADD 1 TO WS-IO1-UPDATE-COUNT.

       COPY file_io_error_proc.
