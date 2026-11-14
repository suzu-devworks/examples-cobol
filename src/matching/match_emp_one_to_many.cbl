       IDENTIFICATION DIVISION.
       PROGRAM-ID. match_emp_one_to_many.

       ENVIRONMENT DIVISION.
       INPUT-OUTPUT SECTION.
       FILE-CONTROL.
           SELECT IN1-FILE     ASSIGN TO WS-IN1-FILE-PATH
                               ORGANIZATION IS LINE SEQUENTIAL
                               FILE STATUS IS WS-IN1-FILE-STATUS.
           SELECT IN2-FILE     ASSIGN TO WS-IN2-FILE-PATH
                               ORGANIZATION IS LINE SEQUENTIAL
                               FILE STATUS IS WS-IN2-FILE-STATUS.
           SELECT OUT1-FILE    ASSIGN TO WS-OUT1-FILE-PATH
                               ORGANIZATION IS LINE SEQUENTIAL
                               FILE STATUS IS WS-OUT1-FILE-STATUS.

       DATA DIVISION.
       FILE SECTION.
       FD  IN1-FILE.
       01  IN1-REC                 PIC X(050).
       FD  IN2-FILE.
       01  IN2-REC                 PIC X(050).
       FD  OUT1-FILE.
       01  OUT1-REC                PIC X(105).

       WORKING-STORAGE SECTION.
      *--- For receiving command line arguments
       01  WS-ARGS.
           05  WS-ARG-COUNT        PIC 9(002) VALUE 0.
           05  WS-IN1-FILE-PATH    PIC X(1024) VALUE SPACES.
           05  WS-IN2-FILE-PATH    PIC X(1024) VALUE SPACES.
           05  WS-OUT1-FILE-PATH   PIC X(1024) VALUE SPACES.

       01  WS-COUNTERS.
           05  WS-IN1-COUNT        PIC 9(006) VALUE 0.
           05  WS-IN2-COUNT        PIC 9(006) VALUE 0.
           05  WS-OUT1-COUNT       PIC 9(006) VALUE 0.

       01  WS-FILE-STATUSES.
       COPY file_statuses
           REPLACING ==:PREFIX:== BY ==WS-IN1==.
       COPY file_statuses
           REPLACING ==:PREFIX:== BY ==WS-IN2==.
       COPY file_statuses
           REPLACING ==:PREFIX:== BY ==WS-OUT1==.

       01  WS-IO-ERROR.
       COPY file_io_error.

       01  WS-IN1-REC.
       COPY dept_rec REPLACING ==:PREFIX:== BY ==WS-IN1==.
           05  FILLER              PIC X(018).

       01  WS-IN2-REC.
       COPY emp_rec REPLACING ==:PREFIX:== BY ==WS-IN2==.
           05  FILLER              PIC X(008).

       01  WS-OUT1-REC.
           05 DEPT-ID              PIC 9(004).
           05 FILLER               PIC X(001).
           05 EMP-REC              PIC X(050).
           05 DEPT-REC             PIC X(050).

       01  WS-VARS.
           05  WS-USAGE-STR        PIC X(100).

       PROCEDURE DIVISION.
           PERFORM INITIALIZE-PROCESS
           PERFORM MAIN-PROCESS
           PERFORM TERMINATE-PROCESS
           STOP RUN.

      * --- Initialize process
       INITIALIZE-PROCESS.
           ACCEPT WS-ARG-COUNT FROM ARGUMENT-NUMBER
           IF WS-ARG-COUNT < 3
               PERFORM DISPLAY-USAGE
               MOVE 1 TO RETURN-CODE
               STOP RUN
           END-IF

           ACCEPT WS-IN1-FILE-PATH     FROM ARGUMENT-VALUE
           ACCEPT WS-IN2-FILE-PATH     FROM ARGUMENT-VALUE
           ACCEPT WS-OUT1-FILE-PATH    FROM ARGUMENT-VALUE

           IF WS-IN1-FILE-PATH = SPACES OR WS-IN2-FILE-PATH = SPACES OR
              WS-OUT1-FILE-PATH = SPACES
               PERFORM DISPLAY-USAGE
               MOVE 1 TO RETURN-CODE
               STOP RUN
           END-IF

           DISPLAY "Transforming started."
           DISPLAY "INPUT1 FILE: " FUNCTION TRIM(WS-IN1-FILE-PATH)
           DISPLAY "INPUT2 FILE: " FUNCTION TRIM(WS-IN2-FILE-PATH)
           DISPLAY "OUTPUT FILE: " FUNCTION TRIM(WS-OUT1-FILE-PATH)

           PERFORM OPEN-IN1-FILE
           PERFORM OPEN-IN2-FILE
           PERFORM OPEN-OUT1-FILE.

       DISPLAY-USAGE.
           STRING "match_emp_one_to_many [INPUT1_FILE] [INPUT2_FILE]"
               " [OUTPUT_FILE]"
               INTO WS-USAGE-STR.
           DISPLAY "Usage: " WS-USAGE-STR.

       TERMINATE-PROCESS.
           PERFORM CLOSE-IN1-FILE
           PERFORM CLOSE-IN2-FILE
           PERFORM CLOSE-OUT1-FILE
           DISPLAY "SUCCESS: Transforming completed."
           DISPLAY "------------------------------"
           DISPLAY "INPUT1 READ  COUNT: " WS-IN1-COUNT
           DISPLAY "INPUT2 READ  COUNT: " WS-IN2-COUNT
           DISPLAY "OUTPUT WRITE COUNT: " WS-OUT1-COUNT
           DISPLAY "------------------------------".

       MAIN-PROCESS.
           PERFORM READ-IN1-FILE
           PERFORM READ-IN2-FILE

           PERFORM UNTIL WS-IN1-REC = HIGH-VALUES AND
                         WS-IN2-REC = HIGH-VALUES

               EVALUATE TRUE
                   WHEN WS-IN1-DEPT-ID OF WS-IN1-REC
                           = WS-IN2-EMP-DEPT-ID OF WS-IN2-REC
                       PERFORM UNTIL NOT WS-IN1-DEPT-ID OF WS-IN1-REC
                               = WS-IN2-EMP-DEPT-ID OF WS-IN2-REC
                           PERFORM EDIT-BOTH-RECORDS
                           PERFORM WRITE-OUT1-FILE
                           PERFORM READ-IN2-FILE
                       END-PERFORM

                   WHEN WS-IN1-DEPT-ID OF WS-IN1-REC
                           < WS-IN2-EMP-DEPT-ID OF WS-IN2-REC
                       PERFORM EDIT-DEPT-ONLY
                       PERFORM WRITE-OUT1-FILE

                   WHEN WS-IN1-DEPT-ID OF WS-IN1-REC
                           > WS-IN2-EMP-DEPT-ID OF WS-IN2-REC
                       DISPLAY "WARNING: Employee record with ID "
                               WS-IN2-EMP-ID OF WS-IN2-REC
                               " has no matching department record."
                       PERFORM READ-IN2-FILE

               END-EVALUATE

               PERFORM READ-IN1-FILE

           END-PERFORM.

       EDIT-BOTH-RECORDS.
           MOVE SPACE TO WS-OUT1-REC
           MOVE WS-IN2-EMP-REC OF WS-IN2-REC
             TO EMP-REC OF WS-OUT1-REC
           MOVE WS-IN1-DEPT-REC OF WS-IN1-REC
             TO DEPT-REC OF WS-OUT1-REC.

       EDIT-DEPT-ONLY.
           MOVE SPACE TO WS-OUT1-REC
           MOVE WS-IN1-DEPT-REC OF WS-IN1-REC
             TO DEPT-REC OF WS-OUT1-REC.

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
           READ IN1-FILE INTO WS-IN1-REC.
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
           READ IN2-FILE INTO WS-IN2-REC.
           EVALUATE TRUE
               WHEN WS-IN2-FILE-OK
                   ADD 1 TO WS-IN2-COUNT
               WHEN WS-IN2-FILE-EOF
                   MOVE HIGH-VALUES TO WS-IN2-REC
               WHEN OTHER
                   MOVE "IN2-FILE" TO WS-IO-ERROR-FILE
                   MOVE WS-IN2-FILE-STATUS TO WS-IO-ERROR-CODE
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
