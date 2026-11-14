       IDENTIFICATION DIVISION.
       PROGRAM-ID. generate_attendance.

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
       01  IN1-REC                 PIC X(042).
       FD  OUT1-FILE.
       01  OUT1-REC                PIC X(009).

       WORKING-STORAGE SECTION.
       01  WS-ARGS.
           05  WS-ARG-COUNT        PIC 9(002) VALUE 0.
           05  WS-IN1-FILE-PATH    PIC X(1024) VALUE SPACES.
           05  WS-OUT1-FILE-PATH   PIC X(1024) VALUE SPACES.
           05  WS-RUN-MONTH-OPTION PIC X(1024) VALUE SPACES.
           05  WS-RUN-MONTH-ARG    PIC X(1024) VALUE SPACES.
           05  WS-SEED-OPTION      PIC X(1024) VALUE SPACES.
           05  WS-SEED-ARG         PIC X(1024) VALUE SPACES.

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

       01  WS-IN1-REC.
       COPY emp_rec REPLACING ==:PREFIX:== BY ==WS-IN1==.

       01  WS-OUT1-REC.
       COPY attendance_rec
           REPLACING ==:PREFIX:== BY ==WS-OUT1==.

       01  WS-GENERATOR-VALUES.
           05  WS-RUN-YEAR         PIC 9(004) VALUE 0.
           05  WS-RUN-MONTH        PIC 9(002) VALUE 0.
           05  WS-RUN-MONTH-NUM    PIC 9(006) VALUE 0.
           05  WS-SEED             PIC 9(008) VALUE 0.
           05  WS-EMPLOYEE-SEED    PIC 9(010) COMP-5 VALUE 0.
           05  WS-RANDOM-VALUE     PIC 9V999999 COMP-3 VALUE 0.

       PROCEDURE DIVISION.
           PERFORM INITIALIZE-PROCESS
           PERFORM MAIN-PROCESS
           PERFORM TERMINATE-PROCESS
           STOP RUN.

       INITIALIZE-PROCESS.
           ACCEPT WS-ARG-COUNT FROM ARGUMENT-NUMBER
           IF WS-ARG-COUNT NOT = 6
               PERFORM DISPLAY-USAGE
               MOVE 1 TO RETURN-CODE
               STOP RUN
           END-IF

           ACCEPT WS-IN1-FILE-PATH FROM ARGUMENT-VALUE
           ACCEPT WS-OUT1-FILE-PATH FROM ARGUMENT-VALUE
           ACCEPT WS-RUN-MONTH-OPTION FROM ARGUMENT-VALUE
           ACCEPT WS-RUN-MONTH-ARG FROM ARGUMENT-VALUE
           ACCEPT WS-SEED-OPTION FROM ARGUMENT-VALUE
           ACCEPT WS-SEED-ARG FROM ARGUMENT-VALUE

           IF WS-IN1-FILE-PATH = SPACES OR
              WS-OUT1-FILE-PATH = SPACES OR
              WS-IN1-FILE-PATH = WS-OUT1-FILE-PATH OR
              WS-RUN-MONTH-OPTION NOT = "--run-month" OR
              WS-SEED-OPTION NOT = "--seed" OR
              FUNCTION LENGTH(
                  FUNCTION TRIM(WS-RUN-MONTH-ARG)) NOT = 7 OR
              FUNCTION LENGTH(
                  FUNCTION TRIM(WS-SEED-ARG)) < 1 OR
              FUNCTION LENGTH(
                  FUNCTION TRIM(WS-SEED-ARG)) > 8 OR
              FUNCTION TRIM(WS-SEED-ARG) IS NOT NUMERIC
               PERFORM INVALID-ARGUMENTS
           END-IF

           IF WS-RUN-MONTH-ARG(1:4) IS NOT NUMERIC OR
              WS-RUN-MONTH-ARG(5:1) NOT = "-" OR
              WS-RUN-MONTH-ARG(6:2) IS NOT NUMERIC
               PERFORM INVALID-ARGUMENTS
           END-IF
           MOVE WS-RUN-MONTH-ARG(1:4) TO WS-RUN-YEAR
           MOVE WS-RUN-MONTH-ARG(6:2) TO WS-RUN-MONTH
           MOVE FUNCTION TRIM(WS-SEED-ARG) TO WS-SEED
           IF WS-RUN-YEAR = 0 OR WS-RUN-MONTH < 1 OR
              WS-RUN-MONTH > 12 OR WS-SEED = 0
               PERFORM INVALID-ARGUMENTS
           END-IF
           COMPUTE WS-RUN-MONTH-NUM =
               WS-RUN-YEAR * 100 + WS-RUN-MONTH

           DISPLAY "Attendance generation started."
           DISPLAY "INPUT FILE:  " FUNCTION TRIM(WS-IN1-FILE-PATH)
           DISPLAY "OUTPUT FILE: " FUNCTION TRIM(WS-OUT1-FILE-PATH)
           DISPLAY "RUN MONTH:   " WS-RUN-MONTH-ARG(1:7)
           DISPLAY "SEED:        " WS-SEED

           PERFORM OPEN-IN1-FILE
           PERFORM OPEN-OUT1-FILE.

       DISPLAY-USAGE.
           DISPLAY "Usage: generate_attendance [EMP_FILE]"
           DISPLAY "       [OUTPUT_FILE] --run-month [YYYY-MM]"
           DISPLAY "       --seed [1-99999999]".

       INVALID-ARGUMENTS.
           DISPLAY "ERROR: Invalid arguments or run month."
           PERFORM DISPLAY-USAGE
           MOVE 1 TO RETURN-CODE
           STOP RUN.

       TERMINATE-PROCESS.
           PERFORM CLOSE-IN1-FILE
           PERFORM CLOSE-OUT1-FILE
           DISPLAY "SUCCESS: Attendance generation completed."
           DISPLAY "------------------------------"
           DISPLAY "INPUT1  READ  COUNT: " WS-IN1-COUNT
           DISPLAY "OUTPUT1 WRITE COUNT: " WS-OUT1-COUNT
           DISPLAY "------------------------------".

       MAIN-PROCESS.
           PERFORM READ-IN1-FILE
           PERFORM UNTIL WS-IN1-FILE-EOF
               PERFORM GENERATE-ATTENDANCE-RECORD
               PERFORM WRITE-OUT1-FILE
               PERFORM READ-IN1-FILE
           END-PERFORM.

       GENERATE-ATTENDANCE-RECORD.
           IF WS-IN1-EMP-ID IS NOT NUMERIC
               DISPLAY "ERROR: Invalid employee record at line "
                       WS-IN1-COUNT "."
               MOVE 1 TO RETURN-CODE
               STOP RUN
           END-IF
           INITIALIZE WS-OUT1-REC
           MOVE WS-IN1-EMP-ID TO WS-OUT1-ATTENDANCE-EMP-ID
           COMPUTE WS-EMPLOYEE-SEED =
               FUNCTION MOD(
                   (WS-SEED * 31) +
                   (WS-RUN-MONTH-NUM * 97) +
                   WS-IN1-EMP-ID,
                   99999989) + 1
           COMPUTE WS-RANDOM-VALUE =
               FUNCTION RANDOM(WS-EMPLOYEE-SEED)
           COMPUTE WS-OUT1-OVERTIME-HOURS =
               FUNCTION INTEGER(WS-RANDOM-VALUE * 41)
           COMPUTE WS-RANDOM-VALUE = FUNCTION RANDOM
           COMPUTE WS-OUT1-ABSENCE-DAYS =
               FUNCTION INTEGER(WS-RANDOM-VALUE * 6).

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
           READ IN1-FILE INTO WS-IN1-REC
           EVALUATE TRUE
               WHEN WS-IN1-FILE-OK
                   ADD 1 TO WS-IN1-COUNT
               WHEN WS-IN1-FILE-EOF
                   MOVE HIGH-VALUES TO WS-IN1-REC
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
