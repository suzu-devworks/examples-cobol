       IDENTIFICATION DIVISION.
       PROGRAM-ID. match_emp_one_to_one.

       ENVIRONMENT DIVISION.
       INPUT-OUTPUT SECTION.
       FILE-CONTROL.
           SELECT IN1-FILE     ASSIGN TO WS-IN1-FILE-PATH
                               ORGANIZATION IS LINE SEQUENTIAL.
           SELECT IN2-FILE     ASSIGN TO WS-IN2-FILE-PATH
                               ORGANIZATION IS LINE SEQUENTIAL.
           SELECT OUT1-FILE    ASSIGN TO WS-OUT1-FILE-PATH
                               ORGANIZATION IS LINE SEQUENTIAL.

       DATA DIVISION.
       FILE SECTION.
       FD  IN1-FILE.
       01  IN1-REC      PIC X(050).
       FD  IN2-FILE.
       01  IN2-REC      PIC X(050).
       FD  OUT1-FILE.
       01  OUT1-REC     PIC X(105).

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

       01  WS-IN1-REC.
       COPY emp_rec REPLACING ==:PREFIX:== BY ==WK-IN1==.
           05  FILLER              PIC X(008).

       01  WS-IN2-REC.
       COPY emp_rec REPLACING ==:PREFIX:== BY ==WK-IN2==.
           05  FILLER              PIC X(008).

       01  WS-OUT1-REC.
           05  EMP-ID              PIC 9(004).
           05  FILLER              PIC X(001).
           05  LEFT-REC            PIC X(050).
           05  RIGHT-REC           PIC X(050).

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

           OPEN INPUT IN1-FILE IN2-FILE
           OPEN OUTPUT OUT1-FILE.

       DISPLAY-USAGE.
           STRING "match_emp_one_to_one [INPUT1_FILE] [INPUT2_FILE]"
               " [OUTPUT_FILE]"
               INTO WS-USAGE-STR.
           DISPLAY "Usage: " WS-USAGE-STR.

      * --- Terminate process
       TERMINATE-PROCESS.
           CLOSE IN1-FILE IN2-FILE
           CLOSE OUT1-FILE
           DISPLAY "SUCCESS: Transforming completed."
           DISPLAY "------------------------------"
           DISPLAY "INPUT1 READ  COUNT: " WS-IN1-COUNT
           DISPLAY "INPUT2 READ  COUNT: " WS-IN2-COUNT
           DISPLAY "OUTPUT WRITE COUNT: " WS-OUT1-COUNT
           DISPLAY "------------------------------".

      * --- Main processing
       MAIN-PROCESS.
           PERFORM READ-IN1-FILE
           PERFORM READ-IN2-FILE

           PERFORM UNTIL WS-IN1-REC = HIGH-VALUES AND
                         WS-IN2-REC = HIGH-VALUES

               EVALUATE TRUE
                   WHEN EMP-ID OF WS-IN1-REC = EMP-ID OF WS-IN2-REC
                       PERFORM EDIT-BOTH-RECORDS
                       PERFORM WRITE-OUT1-FILE
                       PERFORM READ-IN1-FILE
                       PERFORM READ-IN2-FILE

                   WHEN EMP-ID OF WS-IN1-REC < EMP-ID OF WS-IN2-REC
                       PERFORM EDIT-LEFT-ONLY
                       PERFORM WRITE-OUT1-FILE
                       PERFORM READ-IN1-FILE

                   WHEN EMP-ID OF WS-IN1-REC > EMP-ID OF WS-IN2-REC
                       PERFORM EDIT-RIGHT-ONLY
                       PERFORM WRITE-OUT1-FILE
                       PERFORM READ-IN2-FILE

               END-EVALUATE
           END-PERFORM.

       EDIT-BOTH-RECORDS.
           MOVE SPACE TO WS-OUT1-REC
           MOVE EMP-REC OF WS-IN1-REC TO LEFT-REC
           MOVE EMP-REC OF WS-IN2-REC TO RIGHT-REC
           MOVE EMP-ID OF WS-IN1-REC TO EMP-ID OF WS-OUT1-REC.

       EDIT-LEFT-ONLY.
           MOVE SPACE TO WS-OUT1-REC
           MOVE EMP-REC OF WS-IN1-REC TO LEFT-REC
           MOVE EMP-ID OF WS-IN1-REC TO EMP-ID OF WS-OUT1-REC.

       EDIT-RIGHT-ONLY.
           MOVE SPACE TO WS-OUT1-REC
           MOVE EMP-REC OF WS-IN2-REC TO RIGHT-REC
           MOVE EMP-ID OF WS-IN2-REC TO EMP-ID OF WS-OUT1-REC.

       WRITE-OUT1-FILE.
           WRITE OUT1-REC FROM WS-OUT1-REC
           ADD 1 TO WS-OUT1-COUNT.

       READ-IN1-FILE.
           READ IN1-FILE INTO WS-IN1-REC
             AT END MOVE HIGH-VALUES TO WS-IN1-REC
             NOT AT END
                   ADD 1 TO WS-IN1-COUNT
           END-READ.

       READ-IN2-FILE.
           READ IN2-FILE INTO WS-IN2-REC
              AT END MOVE HIGH-VALUES TO WS-IN2-REC
              NOT AT END
                  ADD 1 TO WS-IN2-COUNT
           END-READ.
