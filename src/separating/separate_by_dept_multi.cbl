       IDENTIFICATION DIVISION.
       PROGRAM-ID. separate_by_dept_multi.

       ENVIRONMENT DIVISION.
       INPUT-OUTPUT SECTION.
       FILE-CONTROL.
           SELECT IN-FILE  ASSIGN TO WS-IN-FILE-PATH
                           ORGANIZATION IS LINE SEQUENTIAL.
           SELECT OPTIONAL OUT-FILE ASSIGN TO WS-OUT-FILE-PATH
                           ORGANIZATION IS LINE SEQUENTIAL.

       DATA DIVISION.
       FILE SECTION.
       FD  IN-FILE.
       01  IN-REC      PIC X(050).
       FD  OUT-FILE.
       01  OUT-REC    PIC X(050).

       WORKING-STORAGE SECTION.
      *--- For receiving command line arguments
       01  WS-ARGS.
           05  WS-ARG-COUNT        PIC 9(002) VALUE 0.
           05  WS-IN-FILE-PATH     PIC X(1024) VALUE SPACES.
           05  WS-OUT-BASE-PATH    PIC X(1024) VALUE SPACES.

       01  WS-FILES.
           05  WS-OUT-FILE-PATH    PIC X(1024) VALUE SPACES.

       01  WS-COUNTERS.
           05  WS-IN-COUNT         PIC 9(006) VALUE 0.
           05  WS-OUT-COUNT        PIC 9(006) VALUE 0.
           05  WS-OUT-DEPT-COUNT   PIC 9(006) VALUE 0.

       COPY emp_rec REPLACING ==:PREFIX:== BY ==WK==.
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

           ACCEPT WS-IN-FILE-PATH  FROM ARGUMENT-VALUE
           ACCEPT WS-OUT-BASE-PATH FROM ARGUMENT-VALUE

           IF WS-IN-FILE-PATH = SPACES OR WS-OUT-BASE-PATH = SPACES
               PERFORM DISPLAY-USAGE
               STOP RUN
           END-IF

           DISPLAY "Separating started."
           DISPLAY "INPUT FILE:  " FUNCTION TRIM(WS-IN-FILE-PATH)

           OPEN INPUT IN-FILE.

       DISPLAY-USAGE.
           STRING "separate_by_dept_multi"
               " [INPUT_FILE] [OUTPUT_FILE_BASE]"
               INTO WS-USAGE-STR.
           DISPLAY "Usage: " WS-USAGE-STR.

      * --- Terminate process
       TERMINATE-PROCESS.
           CLOSE IN-FILE.
           DISPLAY "SUCCESS: Separating Completed."
           DISPLAY "--------------------------"
           DISPLAY "INPUT  READ COUNT:  " WS-IN-COUNT
           DISPLAY "OUTPUT WRITE COUNT: " WS-OUT-COUNT
           DISPLAY "--------------------------".

      * --- Main processing
       MAIN-PROCESS.
           PERFORM READ-IN-FILE

           PERFORM UNTIL WK-EMP-REC = HIGH-VALUES
               MOVE WK-EMP-DEPT-ID TO WS-DEPT-ID
               STRING WS-OUT-BASE-PATH DELIMITED BY SPACE
                   "."
                   WS-DEPT-ID DELIMITED BY SIZE
                   INTO WS-OUT-FILE-PATH
               DISPLAY "OUTPUT FILE: " FUNCTION TRIM(WS-OUT-FILE-PATH)

               OPEN EXTEND OUT-FILE
               MOVE 0 TO WS-OUT-DEPT-COUNT

               PERFORM UNTIL WK-EMP-REC = HIGH-VALUES OR
                       WS-DEPT-ID NOT = WK-EMP-DEPT-ID

                   WRITE OUT-REC FROM WK-EMP-REC
                   ADD 1 TO WS-OUT-COUNT
                   ADD 1 TO WS-OUT-DEPT-COUNT

                   PERFORM READ-IN-FILE
               END-PERFORM

               CLOSE OUT-FILE
               DISPLAY "OUTPUT WRITE COUNT: " WS-OUT-DEPT-COUNT

           END-PERFORM.

       READ-IN-FILE.
           READ IN-FILE INTO WK-EMP-REC
             AT END MOVE HIGH-VALUES TO WK-EMP-REC
             NOT AT END
                   ADD 1 TO WS-IN-COUNT
           END-READ.
