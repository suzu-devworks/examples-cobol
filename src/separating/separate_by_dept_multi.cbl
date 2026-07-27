       IDENTIFICATION DIVISION.
       PROGRAM-ID. separate_by_dept_multi.

       ENVIRONMENT DIVISION.
       INPUT-OUTPUT SECTION.
       FILE-CONTROL.
           SELECT IN1-FILE     ASSIGN TO WS-IN1-FILE-PATH
                               ORGANIZATION IS LINE SEQUENTIAL.
           SELECT OPTIONAL OUT1-FILE ASSIGN TO WS-OUT1-FILE-PATH
                               ORGANIZATION IS LINE SEQUENTIAL.

       DATA DIVISION.
       FILE SECTION.
       FD  IN1-FILE.
       01  IN1-REC      PIC X(050).
       FD  OUT1-FILE.
       01  OUT1-REC    PIC X(050).

       WORKING-STORAGE SECTION.
      *--- For receiving command line arguments
       01  WS-ARGS.
           05  WS-ARG-COUNT        PIC 9(002) VALUE 0.
           05  WS-IN1-FILE-PATH    PIC X(1024) VALUE SPACES.
           05  WS-OUT1-FILE-BASE   PIC X(1024) VALUE SPACES.

       01  WS-FILES.
           05  WS-OUT1-FILE-PATH   PIC X(1024) VALUE SPACES.

       01  WS-COUNTERS.
           05  WS-IN1-COUNT        PIC 9(006) VALUE 0.
           05  WS-OUT1-COUNT       PIC 9(006) VALUE 0.
           05  WS-OUT1-DEPT-COUNT  PIC 9(006) VALUE 0.

       01  WS-IN1-REC.
       COPY emp_rec.
           05  FILLER              PIC X(008).

       01  WS-VARS.
           05  WS-USAGE-STR        PIC X(100).
           05  WS-DEPT-ID          PIC 9(004).

       PROCEDURE DIVISION.
           PERFORM INITIALIZE-PROCESS
           PERFORM MAIN-PROCESS
           PERFORM TERMINATE-PROCESS
           STOP RUN.

      * --- Initialize process
       INITIALIZE-PROCESS.
           ACCEPT WS-ARG-COUNT FROM ARGUMENT-NUMBER
           IF WS-ARG-COUNT < 2
               PERFORM DISPLAY-USAGE
               STOP RUN
           END-IF

           ACCEPT WS-IN1-FILE-PATH     FROM ARGUMENT-VALUE
           ACCEPT WS-OUT1-FILE-BASE    FROM ARGUMENT-VALUE

           IF WS-IN1-FILE-PATH = SPACES OR WS-OUT1-FILE-BASE = SPACES
               PERFORM DISPLAY-USAGE
               STOP RUN
           END-IF

           DISPLAY "Separating started."
           DISPLAY "INPUT1 FILE:  " FUNCTION TRIM(WS-IN1-FILE-PATH)

           OPEN INPUT IN1-FILE.

       DISPLAY-USAGE.
           STRING "separate_by_dept_multi"
               " [INPUT_FILE] [OUTPUT_FILE_BASE]"
               INTO WS-USAGE-STR.
           DISPLAY "Usage: " WS-USAGE-STR.

      * --- Terminate process
       TERMINATE-PROCESS.
           CLOSE IN1-FILE.
           DISPLAY "SUCCESS: Separating completed."
           DISPLAY "------------------------------"
           DISPLAY "INPUT1  READ  COUNT: " WS-IN1-COUNT
           DISPLAY "OUTPUT1 WRITE COUNT: " WS-OUT1-COUNT
           DISPLAY "------------------------------".

      * --- Main processing
       MAIN-PROCESS.
           PERFORM READ-IN-FILE

           PERFORM UNTIL WS-IN1-REC = HIGH-VALUES
               MOVE EMP-DEPT-ID TO WS-DEPT-ID

               STRING WS-OUT1-FILE-BASE DELIMITED BY SPACE
                   "."
                   WS-DEPT-ID DELIMITED BY SIZE
                   INTO WS-OUT1-FILE-PATH
               DISPLAY "OUTPUT FILE: " FUNCTION TRIM(WS-OUT1-FILE-PATH)

               OPEN EXTEND OUT1-FILE
               MOVE 0 TO WS-OUT1-DEPT-COUNT

               PERFORM UNTIL WS-IN1-REC = HIGH-VALUES OR
                       WS-DEPT-ID NOT = EMP-DEPT-ID

                   WRITE OUT1-REC FROM WS-IN1-REC
                   ADD 1 TO WS-OUT1-COUNT
                   ADD 1 TO WS-OUT1-DEPT-COUNT

                   PERFORM READ-IN-FILE
               END-PERFORM

               CLOSE OUT1-FILE
               DISPLAY "OUTPUT WRITE COUNT: " WS-OUT1-DEPT-COUNT

           END-PERFORM.

       READ-IN-FILE.
           READ IN1-FILE INTO WS-IN1-REC
             AT END MOVE HIGH-VALUES TO WS-IN1-REC
             NOT AT END
                   ADD 1 TO WS-IN1-COUNT
           END-READ.
