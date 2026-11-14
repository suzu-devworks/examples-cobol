       IDENTIFICATION DIVISION.
       PROGRAM-ID. transform_from_salary_csv.

       ENVIRONMENT DIVISION.
       INPUT-OUTPUT SECTION.
       FILE-CONTROL.
           SELECT IN1-FILE     ASSIGN TO WS-IN1-FILE-PATH
                               ORGANIZATION IS LINE SEQUENTIAL
                               FILE STATUS IS WS-IN1-FILE-STATUS.
           SELECT OUT1-FILE    ASSIGN TO WS-OUT1-FILE-PATH
                               ORGANIZATION IS LINE SEQUENTIAL
                               FILE STATUS IS WS-OUT1-FILE-STATUS.

       DATA DIVISION.
       FILE SECTION.
       FD  IN1-FILE.
       01  IN1-REC                 PIC X(1024).
       FD  OUT1-FILE.
       01  OUT1-REC                PIC X(016).

       WORKING-STORAGE SECTION.
       01  WS-ARGS.
           05  WS-ARG-COUNT        PIC 9(002) VALUE 0.
           05  WS-IN1-FILE-PATH    PIC X(1024) VALUE SPACES.
           05  WS-OUT1-FILE-PATH   PIC X(1024) VALUE SPACES.
           05  WS-RUN-MONTH-OPTION PIC X(1024) VALUE SPACES.
           05  WS-RUN-MONTH-ARG   PIC X(1024) VALUE SPACES.

       01  WS-COUNTERS.
           05  WS-IN1-COUNT        PIC 9(006) VALUE 0.
           05  WS-OUT1-COUNT       PIC 9(006) VALUE 0.

       01  WS-FILE-STATUSES.
       COPY file_statuses
           REPLACING ==:PREFIX:== BY ==WS-IN1==.
       COPY file_statuses
           REPLACING ==:PREFIX:== BY ==WS-OUT1==.

       01  WS-IO-ERROR.
       COPY file_io_error.

       01  WS-OUT1-REC.
       COPY salary_rec REPLACING ==:PREFIX:== BY ==WS-OUT1==.

       01  WS-DATE-VALUES.
           05  WS-RUN-YEAR         PIC 9(004) VALUE 0.
           05  WS-RUN-MONTH        PIC 9(002) VALUE 0.
           05  WS-PREVIOUS-YEAR    PIC 9(004) VALUE 0.
           05  WS-PREVIOUS-MONTH   PIC 9(002) VALUE 0.

       01  WS-CSV-FIELDS.
           05  WS-CSV-DATE         PIC X(1024) VALUE SPACES.
           05  WS-CSV-EMP-ID       PIC X(1024) VALUE SPACES.
           05  WS-CSV-SALARY      PIC X(1024) VALUE SPACES.
           05  WS-CSV-EXTRA        PIC X(1024) VALUE SPACES.
           05  WS-CSV-FIELD-COUNT  PIC 9(002) VALUE 0.
           05  WS-NORMALIZED-EMP-ID PIC X(004) VALUE SPACES.
           05  WS-NORMALIZED-SALARY PIC X(006) VALUE SPACES.

       01  WS-FLAGS.
           05  WS-FIRST-RECORD     PIC X(001) VALUE "Y".

       PROCEDURE DIVISION.
           PERFORM INITIALIZE-PROCESS
           PERFORM MAIN-PROCESS
           PERFORM TERMINATE-PROCESS
           STOP RUN.

       INITIALIZE-PROCESS.
           ACCEPT WS-ARG-COUNT FROM ARGUMENT-NUMBER
           IF WS-ARG-COUNT NOT = 4
               PERFORM DISPLAY-USAGE
               MOVE 1 TO RETURN-CODE
               STOP RUN
           END-IF

           ACCEPT WS-IN1-FILE-PATH FROM ARGUMENT-VALUE
           ACCEPT WS-OUT1-FILE-PATH FROM ARGUMENT-VALUE
           ACCEPT WS-RUN-MONTH-OPTION FROM ARGUMENT-VALUE
           ACCEPT WS-RUN-MONTH-ARG FROM ARGUMENT-VALUE

           IF WS-IN1-FILE-PATH = SPACES OR
              WS-OUT1-FILE-PATH = SPACES OR
              WS-IN1-FILE-PATH = WS-OUT1-FILE-PATH OR
              WS-RUN-MONTH-OPTION NOT = "--run-month" OR
              FUNCTION LENGTH(FUNCTION TRIM(WS-RUN-MONTH-ARG)) NOT = 7
               PERFORM INVALID-ARGUMENTS
           END-IF

           IF WS-RUN-MONTH-ARG(1:4) IS NOT NUMERIC OR
              WS-RUN-MONTH-ARG(5:1) NOT = "-" OR
              WS-RUN-MONTH-ARG(6:2) IS NOT NUMERIC
               PERFORM INVALID-ARGUMENTS
           END-IF

           MOVE WS-RUN-MONTH-ARG(1:4) TO WS-RUN-YEAR
           MOVE WS-RUN-MONTH-ARG(6:2) TO WS-RUN-MONTH
           IF WS-RUN-YEAR = 0 OR WS-RUN-MONTH < 1 OR
              WS-RUN-MONTH > 12 OR
              (WS-RUN-YEAR = 1 AND WS-RUN-MONTH = 1)
               PERFORM INVALID-ARGUMENTS
           END-IF

           PERFORM CALCULATE-PREVIOUS-MONTH

           DISPLAY "Salary CSV transformation started."
           DISPLAY "INPUT FILE:  " FUNCTION TRIM(WS-IN1-FILE-PATH)
           DISPLAY "OUTPUT FILE: " FUNCTION TRIM(WS-OUT1-FILE-PATH)
           DISPLAY "RUN MONTH:   " WS-RUN-MONTH-ARG(1:7)

           PERFORM OPEN-IN1-FILE
           PERFORM OPEN-OUT1-FILE.

       DISPLAY-USAGE.
           DISPLAY "Usage: transform_from_salary_csv [INPUT_CSV]"
           DISPLAY "       [OUTPUT_FILE] --run-month [YYYY-MM]".

       INVALID-ARGUMENTS.
           DISPLAY "ERROR: Invalid arguments or run month."
           PERFORM DISPLAY-USAGE
           MOVE 1 TO RETURN-CODE
           STOP RUN.

       CALCULATE-PREVIOUS-MONTH.
           IF WS-RUN-MONTH = 1
               COMPUTE WS-PREVIOUS-YEAR = WS-RUN-YEAR - 1
               MOVE 12 TO WS-PREVIOUS-MONTH
           ELSE
               MOVE WS-RUN-YEAR TO WS-PREVIOUS-YEAR
               COMPUTE WS-PREVIOUS-MONTH = WS-RUN-MONTH - 1
           END-IF.

       TERMINATE-PROCESS.
           PERFORM CLOSE-IN1-FILE
           PERFORM CLOSE-OUT1-FILE
           DISPLAY "SUCCESS: Salary CSV transformation completed."
           DISPLAY "------------------------------"
           DISPLAY "INPUT1  READ  COUNT: " WS-IN1-COUNT
           DISPLAY "OUTPUT1 WRITE COUNT: " WS-OUT1-COUNT
           DISPLAY "------------------------------".

       MAIN-PROCESS.
           PERFORM READ-IN1-FILE
           PERFORM UNTIL WS-IN1-FILE-EOF
               IF WS-FIRST-RECORD = "Y" AND
                  FUNCTION TRIM(IN1-REC) =
                    "salary_month,employee_id,monthly_salary"
                   MOVE "N" TO WS-FIRST-RECORD
               ELSE
                   MOVE "N" TO WS-FIRST-RECORD
                   PERFORM TRANSFORM-RECORD
                   PERFORM WRITE-OUT1-FILE
               END-IF
               PERFORM READ-IN1-FILE
           END-PERFORM.

       TRANSFORM-RECORD.
           MOVE SPACES TO WS-CSV-FIELDS
           MOVE 0 TO WS-CSV-FIELD-COUNT

           UNSTRING IN1-REC DELIMITED BY ","
               INTO WS-CSV-DATE
                    WS-CSV-EMP-ID
                    WS-CSV-SALARY
                    WS-CSV-EXTRA
               TALLYING IN WS-CSV-FIELD-COUNT
           END-UNSTRING

           IF WS-CSV-FIELD-COUNT NOT = 3 OR
              WS-CSV-EXTRA NOT = SPACES
               PERFORM INVALID-RECORD
           END-IF

           IF FUNCTION LENGTH(FUNCTION TRIM(WS-CSV-EMP-ID)) NOT = 4
               PERFORM INVALID-RECORD
           END-IF
           MOVE FUNCTION TRIM(WS-CSV-EMP-ID)
             TO WS-NORMALIZED-EMP-ID
           IF WS-NORMALIZED-EMP-ID IS NOT NUMERIC
               PERFORM INVALID-RECORD
           END-IF

           IF FUNCTION LENGTH(FUNCTION TRIM(WS-CSV-SALARY)) NOT = 6
               PERFORM INVALID-RECORD
           END-IF
           MOVE FUNCTION TRIM(WS-CSV-SALARY)
             TO WS-NORMALIZED-SALARY
           IF WS-NORMALIZED-SALARY IS NOT NUMERIC
               PERFORM INVALID-RECORD
           END-IF

           MOVE WS-NORMALIZED-EMP-ID TO WS-OUT1-SALARY-EMP-ID
           COMPUTE WS-OUT1-SALARY-MONTH =
               WS-PREVIOUS-YEAR * 100 + WS-PREVIOUS-MONTH
           MOVE WS-NORMALIZED-SALARY TO WS-OUT1-MONTHLY-SALARY.

       INVALID-RECORD.
           DISPLAY "ERROR: Invalid salary CSV record at line "
                   WS-IN1-COUNT "."
           MOVE 1 TO RETURN-CODE
           STOP RUN.

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

       OPEN-OUT1-FILE.
           OPEN OUTPUT OUT1-FILE
           IF NOT WS-OUT1-FILE-OK
               MOVE "OUT1-FILE" TO WS-IO-ERROR-FILE
               MOVE WS-OUT1-FILE-STATUS TO WS-IO-ERROR-CODE
               PERFORM FILE-IO-ERROR
           END-IF.

       CLOSE-OUT1-FILE.
           CLOSE OUT1-FILE
           IF NOT WS-OUT1-FILE-OK
               MOVE "OUT1-FILE" TO WS-IO-ERROR-FILE
               MOVE WS-OUT1-FILE-STATUS TO WS-IO-ERROR-CODE
               PERFORM FILE-IO-ERROR
           END-IF.

       WRITE-OUT1-FILE.
           WRITE OUT1-REC FROM WS-OUT1-REC
           IF NOT WS-OUT1-FILE-OK
               MOVE "OUT1-FILE" TO WS-IO-ERROR-FILE
               MOVE WS-OUT1-FILE-STATUS TO WS-IO-ERROR-CODE
               PERFORM FILE-IO-ERROR
           END-IF
           ADD 1 TO WS-OUT1-COUNT.

       COPY file_io_error_proc.
