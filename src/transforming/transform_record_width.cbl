       IDENTIFICATION DIVISION.
       PROGRAM-ID. transform_record_width.

       ENVIRONMENT DIVISION.
       INPUT-OUTPUT SECTION.
       FILE-CONTROL.
           SELECT IN1-FILE ASSIGN TO WS-IN1-FILE-PATH
               ORGANIZATION IS LINE SEQUENTIAL
               FILE STATUS IS WS-IN1-FILE-STATUS.
           SELECT OUT1-FILE ASSIGN TO WS-OUT1-FILE-PATH
               ORGANIZATION IS LINE SEQUENTIAL
               FILE STATUS IS WS-OUT1-FILE-STATUS.

       DATA DIVISION.
       FILE SECTION.
       FD  IN1-FILE.
       01  IN1-REC                 PIC X(100).
       FD  OUT1-FILE.
       01  OUT1-REC                PIC X(050).

       WORKING-STORAGE SECTION.
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

       01  WS-IO-ERROR-DATA.
       COPY file_io_error.

       PROCEDURE DIVISION.
           PERFORM INITIALIZE-PROCESS
           PERFORM MAIN-PROCESS
           PERFORM TERMINATE-PROCESS
           STOP RUN.

       INITIALIZE-PROCESS.
           ACCEPT WS-ARG-COUNT FROM ARGUMENT-NUMBER
           IF WS-ARG-COUNT NOT = 2
               DISPLAY "Usage: transform_record_width INPUT_FILE"
                       " OUTPUT_FILE"
               MOVE 1 TO RETURN-CODE
               STOP RUN
           END-IF
           ACCEPT WS-IN1-FILE-PATH FROM ARGUMENT-VALUE
           ACCEPT WS-OUT1-FILE-PATH FROM ARGUMENT-VALUE
           IF WS-IN1-FILE-PATH = SPACES OR
              WS-OUT1-FILE-PATH = SPACES OR
              WS-IN1-FILE-PATH = WS-OUT1-FILE-PATH
               DISPLAY "ERROR: Input and output paths must be"
                       " different."
               MOVE 1 TO RETURN-CODE
               STOP RUN
           END-IF
           PERFORM OPEN-IN1-FILE
           PERFORM OPEN-OUT1-FILE.

       TERMINATE-PROCESS.
           PERFORM CLOSE-IN1-FILE
           PERFORM CLOSE-OUT1-FILE
           DISPLAY "SUCCESS: Record-width transformation completed."
           DISPLAY "---------------------------"
           DISPLAY "INPUT1  READ  COUNT: " WS-IN1-COUNT
           DISPLAY "OUTPUT1 WRITE COUNT: " WS-OUT1-COUNT
           DISPLAY "---------------------------".

       MAIN-PROCESS.
           PERFORM READ-IN1-FILE
           PERFORM UNTIL WS-IN1-FILE-EOF
               MOVE IN1-REC(1:50) TO OUT1-REC
               PERFORM WRITE-OUT1-FILE
               PERFORM READ-IN1-FILE
           END-PERFORM.

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
           WRITE OUT1-REC
           IF NOT WS-OUT1-FILE-OK
               MOVE "OUT1-FILE" TO WS-IO-ERROR-FILE
               MOVE WS-OUT1-FILE-STATUS TO WS-IO-ERROR-CODE
               PERFORM FILE-IO-ERROR
           END-IF
           ADD 1 TO WS-OUT1-COUNT.

       COPY file_io_error_proc.
