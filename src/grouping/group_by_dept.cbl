       IDENTIFICATION DIVISION.
       PROGRAM-ID. group_by_dept.

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
       01  IN1-REC                 PIC X(050).
       FD  OUT1-FILE.
       01  OUT1-REC                PIC X(050).

       WORKING-STORAGE SECTION.
      *--- For receiving command line arguments
       01  WS-ARGS.
           05  WS-ARG-COUNT        PIC 9(002) VALUE 0.
           05  WS-IN1-FILE-PATH    PIC X(1024) VALUE SPACES.
           05  WS-OUT1-FILE-PATH   PIC X(1024) VALUE SPACES.

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
           05  FILLER              PIC X(008).

       01  WS-OUT1-REC.
       COPY dept_rec REPLACING ==:PREFIX:== BY ==WS-OUT1==.
           05  FILLER              PIC X(016).

       01  WS-VARS.
           05  WS-USAGE-STR        PIC X(100).
           05  WS-DEPT-MAX-SALARY  PIC 9(006) VALUE 0.

       PROCEDURE DIVISION.
           PERFORM INITIALIZE-PROCESS
           PERFORM MAIN-PROCESS
           PERFORM TERMINATE-PROCESS
           STOP RUN.

       INITIALIZE-PROCESS.
           ACCEPT WS-ARG-COUNT FROM ARGUMENT-NUMBER
           IF WS-ARG-COUNT < 2
               PERFORM DISPLAY-USAGE
               MOVE 1 TO RETURN-CODE
               STOP RUN
           END-IF

           ACCEPT WS-IN1-FILE-PATH     FROM ARGUMENT-VALUE
           ACCEPT WS-OUT1-FILE-PATH    FROM ARGUMENT-VALUE

           IF WS-IN1-FILE-PATH = SPACES OR WS-OUT1-FILE-PATH = SPACES
               PERFORM DISPLAY-USAGE
               MOVE 1 TO RETURN-CODE
               STOP RUN
           END-IF

           DISPLAY "Grouping started."
           DISPLAY "INPUT1 FILE:  " FUNCTION TRIM(WS-IN1-FILE-PATH)
           DISPLAY "OUTPUT2 FILE: " FUNCTION TRIM(WS-OUT1-FILE-PATH)

           PERFORM OPEN-IN1-FILE
           PERFORM OPEN-OUT1-FILE.

       DISPLAY-USAGE.
           STRING "group_by_dept [INPUT_FILE] [OUTPUT_FILE]"
               INTO WS-USAGE-STR.
           DISPLAY "Usage: " WS-USAGE-STR.

       TERMINATE-PROCESS.
           PERFORM CLOSE-IN1-FILE
           PERFORM CLOSE-OUT1-FILE
           DISPLAY "SUCCESS: Grouping completed."
           DISPLAY "------------------------------"
           DISPLAY "INPUT1  READ  COUNT: " WS-IN1-COUNT
           DISPLAY "OUTPUT1 WRITE COUNT: " WS-OUT1-COUNT
           DISPLAY "------------------------------".

       MAIN-PROCESS.
           PERFORM READ-IN1-FILE

           PERFORM UNTIL WS-IN1-REC = HIGH-VALUES
               INITIALIZE WS-OUT1-REC
               MOVE WS-IN1-EMP-DEPT-ID TO WS-OUT1-DEPT-ID
               MOVE 0 TO WS-DEPT-MAX-SALARY

               PERFORM UNTIL WS-IN1-REC = HIGH-VALUES OR
                       NOT WS-IN1-EMP-DEPT-ID = WS-OUT1-DEPT-ID
                   PERFORM EDIT-OUT1-REC
                   PERFORM READ-IN1-FILE
               END-PERFORM

               PERFORM WRITE-OUT1-FILE
           END-PERFORM.

       EDIT-OUT1-REC.
           MOVE WS-IN1-EMP-DEPT-ID TO WS-OUT1-DEPT-ID
           MOVE WS-IN1-EMP-DEPT-NAME TO WS-OUT1-DEPT-NAME

           IF WS-DEPT-MAX-SALARY < WS-IN1-EMP-SALARY
               MOVE WS-IN1-EMP-ID TO WS-OUT1-DEPT-MANAGER-ID
               MOVE WS-IN1-EMP-NAME TO WS-OUT1-DEPT-MANAGER-NAME

               MOVE WS-IN1-EMP-SALARY TO WS-DEPT-MAX-SALARY
           END-IF

           ADD 1 TO WS-OUT1-DEPT-MEMBER-COUNT.

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
           END-READ.
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
           DISPLAY "DEPT-ID: " WS-OUT1-DEPT-ID
                   " DEPT-NAME: " WS-OUT1-DEPT-NAME
                   " MANAGER-ID: " WS-OUT1-DEPT-MANAGER-ID
                   " MANAGER-NAME: " WS-OUT1-DEPT-MANAGER-NAME
                   " MEMBER-COUNT: " WS-OUT1-DEPT-MEMBER-COUNT
                   " MAX-SALARY: " WS-DEPT-MAX-SALARY.

       COPY file_io_error_proc.
