       IDENTIFICATION DIVISION.
       PROGRAM-ID. separate_by_join_date.

       ENVIRONMENT DIVISION.
       INPUT-OUTPUT SECTION.
       FILE-CONTROL.
           SELECT IN1-FILE     ASSIGN TO WS-IN1-FILE-PATH
                               ORGANIZATION IS LINE SEQUENTIAL.
           SELECT OUT1-FILE    ASSIGN TO WS-OUT1-FILE-PATH
                               ORGANIZATION IS LINE SEQUENTIAL.
           SELECT OUT2-FILE    ASSIGN TO WS-OUT2-FILE-PATH
                               ORGANIZATION IS LINE SEQUENTIAL.

       DATA DIVISION.
       FILE SECTION.
       FD  IN1-FILE.
       01  IN1-REC         PIC X(050).
       FD  OUT1-FILE.
       01  OUT1-REC        PIC X(050).
       FD  OUT2-FILE.
       01  OUT2-REC        PIC X(050).

       WORKING-STORAGE SECTION.
      *--- For receiving command line arguments
       01  WS-ARGS.
           05  WS-ARG-COUNT        PIC 9(002) VALUE 0.
           05  WS-SEPARATE-DATE    PIC 9(008) VALUE 0.
           05  WS-IN1-FILE-PATH    PIC X(1024) VALUE SPACES.
           05  WS-OUT1-FILE-PATH   PIC X(1024) VALUE SPACES.
           05  WS-OUT2-FILE-PATH   PIC X(1024) VALUE SPACES.

       01  WS-COUNTERS.
           05  WS-IN1-COUNT        PIC 9(006) VALUE 0.
           05  WS-OUT1-COUNT       PIC 9(006) VALUE 0.
           05  WS-OUT2-COUNT       PIC 9(006) VALUE 0.

       01  WS-IN1-REC.
       COPY emp_rec.
           05  FILLER              PIC X(008).

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
           IF WS-ARG-COUNT < 4
               PERFORM DISPLAY-USAGE
               MOVE 1 TO RETURN-CODE
               STOP RUN
           END-IF

           ACCEPT WS-IN1-FILE-PATH     FROM ARGUMENT-VALUE
           ACCEPT WS-OUT1-FILE-PATH    FROM ARGUMENT-VALUE
           ACCEPT WS-OUT2-FILE-PATH    FROM ARGUMENT-VALUE
           ACCEPT WS-SEPARATE-DATE     FROM ARGUMENT-VALUE

           IF WS-IN1-FILE-PATH = SPACES OR WS-OUT1-FILE-PATH = SPACES
               OR WS-OUT2-FILE-PATH = SPACES OR WS-SEPARATE-DATE = 0
               PERFORM DISPLAY-USAGE
               MOVE 1 TO RETURN-CODE
               STOP RUN
           END-IF

           IF (WS-SEPARATE-DATE < 19000101 OR
               WS-SEPARATE-DATE > 21001231)
               DISPLAY "ERROR: Invalid date. Please provide a date in YY
      -            "YYMMDD format."
               PERFORM DISPLAY-USAGE
               MOVE 1 TO RETURN-CODE
               STOP RUN
           END-IF

           DISPLAY "Separating started."
           DISPLAY "INPUT1 FILE:   " FUNCTION TRIM(WS-IN1-FILE-PATH)
           DISPLAY "OUTPUT1 FILE:  " FUNCTION TRIM(WS-OUT1-FILE-PATH)
           DISPLAY "OUTPUT2 FILE:  " FUNCTION TRIM(WS-OUT2-FILE-PATH)
           DISPLAY "SEPARATE DATE: " WS-SEPARATE-DATE

           OPEN INPUT IN1-FILE
           OPEN OUTPUT OUT1-FILE OUT2-FILE.

       DISPLAY-USAGE.
           STRING "separate_by_join_date"
               " [INPUT1_FILE] [OUTPUT1_FILE] [OUTPUT2_FILE]"
               " [SEPARATE-DATE]"
               INTO WS-USAGE-STR.
           DISPLAY "Usage: " WS-USAGE-STR.

      * --- Terminate process
       TERMINATE-PROCESS.
           CLOSE IN1-FILE.
           CLOSE OUT1-FILE OUT2-FILE.
           DISPLAY "SUCCESS: Separating completed."
           DISPLAY "------------------------------"
           DISPLAY "INPUT1  READ  COUNT: " WS-IN1-COUNT
           DISPLAY "OUTPUT1 WRITE COUNT: " WS-OUT1-COUNT
           DISPLAY "OUTPUT2 WRITE COUNT: " WS-OUT2-COUNT
           DISPLAY "------------------------------".

      * --- Main processing
       MAIN-PROCESS.
           PERFORM READ-IN1-FILE

           PERFORM UNTIL WS-IN1-REC = HIGH-VALUES

               IF EMP-JOIN-DATE < WS-SEPARATE-DATE
                   WRITE OUT1-REC FROM WS-IN1-REC
                   ADD 1 TO WS-OUT1-COUNT
               ELSE
                   WRITE OUT2-REC FROM WS-IN1-REC
                   ADD 1 TO WS-OUT2-COUNT
               END-IF

               PERFORM READ-IN1-FILE
           END-PERFORM.

       READ-IN1-FILE.
           READ IN1-FILE INTO WS-IN1-REC
             AT END MOVE HIGH-VALUES TO WS-IN1-REC
             NOT AT END
                   ADD 1 TO WS-IN1-COUNT
           END-READ.
