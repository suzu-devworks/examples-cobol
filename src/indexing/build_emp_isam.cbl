       IDENTIFICATION DIVISION.
       PROGRAM-ID. build_emp_isam.

       ENVIRONMENT DIVISION.
       INPUT-OUTPUT SECTION.
       FILE-CONTROL.
           SELECT IN1-FILE     ASSIGN TO WS-IN1-FILE-PATH
                               ORGANIZATION IS LINE SEQUENTIAL
                               FILE STATUS IS WS-IN1-FILE-STATUS.
           SELECT IN2-FILE     ASSIGN TO WS-IN2-FILE-PATH
                               ORGANIZATION IS LINE SEQUENTIAL
                               FILE STATUS IS WS-IN2-FILE-STATUS.
           SELECT IO1-FILE     ASSIGN TO WS-OUT1-FILE-PATH
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
       01  IO1-REC.
       COPY emp_salary_rec
           REPLACING ==:PREFIX:== BY ==IO1==.

       WORKING-STORAGE SECTION.
       01  WS-ARGS.
           05  WS-ARG-COUNT        PIC 9(002) VALUE 0.
           05  WS-IN1-FILE-PATH    PIC X(1024) VALUE SPACES.
           05  WS-IN2-FILE-PATH    PIC X(1024) VALUE SPACES.
           05  WS-OUT1-FILE-PATH   PIC X(1024) VALUE SPACES.

       01  WS-COUNTERS.
           05  WS-IN1-COUNT        PIC 9(006) VALUE 0.
           05  WS-IN2-COUNT        PIC 9(006) VALUE 0.
           05  WS-OUT1-COUNT       PIC 9(006) VALUE 0.
           05  WS-IO1-UPDATE-COUNT PIC 9(006) VALUE 0.
           05  WS-MISSING-SALARY-COUNT PIC 9(006) VALUE 0.

       01  WS-FILE-STATUSES.
       COPY file_statuses
           REPLACING ==:PREFIX:== BY ==WS-IN1==.
       COPY file_statuses
           REPLACING ==:PREFIX:== BY ==WS-IN2==.
       COPY file_statuses
           REPLACING ==:PREFIX:== BY ==WS-IO1==.

       01  WS-IO-ERROR-DATA.
       COPY file_io_error.

       01  WS-IN2-REC.
       COPY salary_rec
           REPLACING ==:PREFIX:== BY ==WS-IN2==.

       PROCEDURE DIVISION.
           PERFORM INITIALIZE-PROCESS
           PERFORM MAIN-PROCESS
           PERFORM TERMINATE-PROCESS
           STOP RUN.

       INITIALIZE-PROCESS.
           ACCEPT WS-ARG-COUNT FROM ARGUMENT-NUMBER
           IF WS-ARG-COUNT NOT = 3
               PERFORM DISPLAY-USAGE
               MOVE 1 TO RETURN-CODE
               STOP RUN
           END-IF

           ACCEPT WS-IN1-FILE-PATH FROM ARGUMENT-VALUE
           ACCEPT WS-IN2-FILE-PATH FROM ARGUMENT-VALUE
           ACCEPT WS-OUT1-FILE-PATH FROM ARGUMENT-VALUE

           IF WS-IN1-FILE-PATH = SPACES OR
              WS-IN2-FILE-PATH = SPACES OR
              WS-OUT1-FILE-PATH = SPACES OR
              WS-IN1-FILE-PATH = WS-IN2-FILE-PATH OR
              WS-IN1-FILE-PATH = WS-OUT1-FILE-PATH OR
              WS-IN2-FILE-PATH = WS-OUT1-FILE-PATH
               PERFORM INVALID-ARGUMENTS
           END-IF

           DISPLAY "Employee ISAM build started."
           DISPLAY "EMPLOYEE FILE: " FUNCTION TRIM(WS-IN1-FILE-PATH)
           DISPLAY "SALARY FILE:   " FUNCTION TRIM(WS-IN2-FILE-PATH)
           DISPLAY "ISAM FILE:     " FUNCTION TRIM(WS-OUT1-FILE-PATH)

           PERFORM OPEN-IN1-FILE
           PERFORM OPEN-IN2-FILE
           PERFORM OPEN-IO1-FILE.

       DISPLAY-USAGE.
           DISPLAY "Usage: build_emp_isam"
           DISPLAY "       [EMPLOYEE_FILE] [PREVIOUS_SALARY_FILE]"
           DISPLAY "       [OUTPUT_ISAM_FILE]".

       INVALID-ARGUMENTS.
           DISPLAY "ERROR: Invalid arguments."
           PERFORM DISPLAY-USAGE
           MOVE 1 TO RETURN-CODE
           STOP RUN.

       TERMINATE-PROCESS.
           PERFORM CLOSE-IN1-FILE
           PERFORM CLOSE-IN2-FILE
           PERFORM CLOSE-IO1-FILE
           IF WS-MISSING-SALARY-COUNT > 0
               DISPLAY "WARNING: Employees without previous salary: "
                       WS-MISSING-SALARY-COUNT
           END-IF
           DISPLAY "SUCCESS: Employee ISAM build completed."
           DISPLAY "------------------------------"
           DISPLAY "INPUT1 READ COUNT:    " WS-IN1-COUNT
           DISPLAY "INPUT2 READ COUNT:    " WS-IN2-COUNT
           DISPLAY "OUTPUT1 WRITE COUNT:  " WS-OUT1-COUNT
           DISPLAY "IO1 UPDATE COUNT:     " WS-IO1-UPDATE-COUNT
           DISPLAY "------------------------------".

       MAIN-PROCESS.
           PERFORM LOAD-EMPLOYEES
           PERFORM CLOSE-IO1-FILE
           PERFORM OPEN-IO1-FILE-FOR-UPDATE
           PERFORM APPLY-SALARIES
           COMPUTE WS-MISSING-SALARY-COUNT =
               WS-OUT1-COUNT - WS-IO1-UPDATE-COUNT.

       LOAD-EMPLOYEES.
           PERFORM READ-IN1-FILE
           PERFORM UNTIL WS-IN1-FILE-EOF
               PERFORM VALIDATE-EMPLOYEE-RECORD
               INITIALIZE IO1-EMP-SALARY-REC
               MOVE IN1-REC(1:42) TO IO1-EMP-SALARY-REC(1:42)
               MOVE ZERO TO IO1-EMP-SALARY
               MOVE ZERO TO IO1-EMP-SALARY-MONTH
               PERFORM WRITE-IO1-FILE
               PERFORM READ-IN1-FILE
           END-PERFORM.

       VALIDATE-EMPLOYEE-RECORD.
           IF IN1-REC(1:4) IS NOT NUMERIC OR
              IN1-REC(15:4) IS NOT NUMERIC OR
              IN1-REC(29:14) IS NOT NUMERIC OR
              IN1-REC(43:982) NOT = SPACES
               DISPLAY "ERROR: Invalid employee record at line "
                       WS-IN1-COUNT "."
               MOVE 1 TO RETURN-CODE
               STOP RUN
           END-IF.

       APPLY-SALARIES.
           PERFORM READ-IN2-FILE
           PERFORM UNTIL WS-IN2-FILE-EOF
               PERFORM VALIDATE-SALARY-RECORD
               MOVE WS-IN2-SALARY-EMP-ID TO IO1-EMP-ID
               PERFORM READ-IO1-FILE
               IF IO1-EMP-SALARY-MONTH NOT = ZERO
                   DISPLAY "ERROR: Duplicate salary for employee ID "
                           WS-IN2-SALARY-EMP-ID "."
                   MOVE 1 TO RETURN-CODE
                   STOP RUN
               END-IF
               MOVE WS-IN2-SALARY-MONTH
                 TO IO1-EMP-SALARY-MONTH
               MOVE WS-IN2-MONTHLY-SALARY
                 TO IO1-EMP-SALARY
               PERFORM REWRITE-IO1-FILE
               PERFORM READ-IN2-FILE
           END-PERFORM.

       VALIDATE-SALARY-RECORD.
           IF IN2-REC(1:16) IS NOT NUMERIC OR
              IN2-REC(5:4) = "0000" OR
              IN2-REC(9:2) < "01" OR
              IN2-REC(9:2) > "12" OR
              IN2-REC(17:1008) NOT = SPACES
               DISPLAY "ERROR: Invalid salary record at line "
                       WS-IN2-COUNT "."
               MOVE 1 TO RETURN-CODE
               STOP RUN
           END-IF
           MOVE IN2-REC(1:16) TO WS-IN2-SALARY-REC.

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
           READ IN1-FILE.
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
           READ IN2-FILE.
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
           OPEN OUTPUT IO1-FILE
           IF NOT WS-IO1-FILE-OK
               MOVE "IO1-FILE" TO WS-IO-ERROR-FILE
               MOVE WS-IO1-FILE-STATUS TO WS-IO-ERROR-CODE
               PERFORM FILE-IO-ERROR
           END-IF.

       OPEN-IO1-FILE-FOR-UPDATE.
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

       READ-IO1-FILE.
           READ IO1-FILE KEY IS IO1-EMP-ID.
           EVALUATE TRUE
               WHEN WS-IO1-FILE-OK
                   CONTINUE
               WHEN WS-IO1-FILE-STATUS = "23"
                   DISPLAY "ERROR: Salary employee ID not found: "
                           WS-IN2-SALARY-EMP-ID "."
                   MOVE 1 TO RETURN-CODE
                   STOP RUN
               WHEN OTHER
                   MOVE "IO1-FILE" TO WS-IO-ERROR-FILE
                   MOVE WS-IO1-FILE-STATUS TO WS-IO-ERROR-CODE
                   PERFORM FILE-IO-ERROR
           END-EVALUATE.

       WRITE-IO1-FILE.
           WRITE IO1-REC
           EVALUATE TRUE
               WHEN WS-IO1-FILE-OK
                   ADD 1 TO WS-OUT1-COUNT
               WHEN WS-IO1-FILE-STATUS = "22"
                   DISPLAY "ERROR: Duplicate employee ID "
                           IO1-EMP-ID "."
                   MOVE 1 TO RETURN-CODE
                   STOP RUN
               WHEN OTHER
                   MOVE "IO1-FILE" TO WS-IO-ERROR-FILE
                   MOVE WS-IO1-FILE-STATUS TO WS-IO-ERROR-CODE
                   PERFORM FILE-IO-ERROR
           END-EVALUATE.

       REWRITE-IO1-FILE.
           REWRITE IO1-REC
           IF NOT WS-IO1-FILE-OK
               MOVE "IO1-FILE" TO WS-IO-ERROR-FILE
               MOVE WS-IO1-FILE-STATUS TO WS-IO-ERROR-CODE
               PERFORM FILE-IO-ERROR
           END-IF
           ADD 1 TO WS-IO1-UPDATE-COUNT.

       COPY file_io_error_proc.
