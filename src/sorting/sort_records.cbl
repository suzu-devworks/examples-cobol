       IDENTIFICATION DIVISION.
       PROGRAM-ID. sort_records.

       ENVIRONMENT DIVISION.
       INPUT-OUTPUT SECTION.
       FILE-CONTROL.
           SELECT IN1-FILE     ASSIGN TO WS-IN1-FILE-PATH
                               ORGANIZATION IS LINE SEQUENTIAL.
           SELECT OUT1-FILE    ASSIGN TO WS-OUT1-FILE-PATH
                               ORGANIZATION IS LINE SEQUENTIAL.

           *> work file for sorting
           SELECT WORK-FILE    ASSIGN TO WS-WORK-FILE-PATH
                               ORGANIZATION IS LINE SEQUENTIAL.

       DATA DIVISION.
       FILE SECTION.
       FD  IN1-FILE.
       01  IN1-REC                 PIC X(100).
       FD  OUT1-FILE.
       01  OUT1-REC                PIC X(100).
       SD  WORK-FILE.
       01  WORK-REC.
           05 WORK-REC-KEY         PIC X(100).
           05 WORK-REC-ORIGINAL    PIC X(100).

       WORKING-STORAGE SECTION.
      *--- For receiving command line arguments
       01  WS-ARGS.
           05  WS-ARG-COUNT        PIC 9(002) VALUE 0.
           05  WS-IN1-FILE-PATH    PIC X(1024) VALUE SPACES.
           05  WS-OUT1-FILE-PATH   PIC X(1024) VALUE SPACES.
           05  WS-ARG-KEY-START    PIC 9(003) VALUE 1. *> Starting position (starting from 1)
           05  WS-ARG-KEY-LEN      PIC 9(003) VALUE 4. *> Number of character

       01  WS-WORK-FILES.
           05  WS-WORK-FILE-PATH   PIC X(1024) VALUE SPACES.

       01  WS-COUNTERS.
           05  WS-IN1-COUNT        PIC 9(006) VALUE 0.
           05  WS-OUT1-COUNT       PIC 9(006) VALUE 0.

       01  WS-VARS.
           05  WS-USAGE-STR        PIC X(100).
           05  WS-PID              PIC 9(008).
           05  EOF-FLG             PIC X(001) VALUE "N".
           05  EOF-WORK-FLG        PIC X(001) VALUE "N".

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
           ACCEPT WS-OUT1-FILE-PATH    FROM ARGUMENT-VALUE

           IF WS-IN1-FILE-PATH = SPACES OR WS-OUT1-FILE-PATH = SPACES
               PERFORM DISPLAY-USAGE
               STOP RUN
           END-IF

           DISPLAY "Sort started."
           DISPLAY "INPUT FILE:   " FUNCTION TRIM(WS-IN1-FILE-PATH)
           DISPLAY "OUTPUT FILE:  " FUNCTION TRIM(WS-OUT1-FILE-PATH)

           PERFORM BUILD-WORK-FILE-PATH

           if WS-ARG-COUNT >= 4
               ACCEPT WS-ARG-KEY-START FROM ARGUMENT-VALUE
               ACCEPT WS-ARG-KEY-LEN   FROM ARGUMENT-VALUE

               if WS-ARG-KEY-START < 1 OR
                  WS-ARG-KEY-LEN < 1 OR
                  WS-ARG-KEY-START + WS-ARG-KEY-LEN - 1 > 100
                   DISPLAY "ERROR: Invalid key start or length."
                   PERFORM DISPLAY-USAGE
                   STOP RUN
               END-IF
           END-IF

           DISPLAY "SORT KEY:     " WS-ARG-KEY-START ":" WS-ARG-KEY-LEN

           OPEN INPUT IN1-FILE
           OPEN OUTPUT OUT1-FILE.

       DISPLAY-USAGE.
           STRING
               "sort_records [IN-FILE] [OUT-FILE]"
               " [KEY-START] [KEY-LEN]"
               INTO WS-USAGE-STR.
           DISPLAY "Usage: " WS-USAGE-STR.

       BUILD-WORK-FILE-PATH.
           CALL "C$GETPID" RETURNING WS-PID
               STRING
                   WS-OUT1-FILE-PATH DELIMITED BY SPACE
                   ".tmp." WS-PID DELIMITED BY SIZE
                   INTO WS-WORK-FILE-PATH

           DISPLAY "WORK FILE  :  " FUNCTION TRIM(WS-WORK-FILE-PATH).

      * --- Terminate process
       TERMINATE-PROCESS.
           CLOSE IN1-FILE
           CLOSE OUT1-FILE
           DISPLAY "SUCCESS: Sort completed."
           DISPLAY "------------------------------"
           DISPLAY "INPUT1  READ  COUNT: " WS-IN1-COUNT
           DISPLAY "OUTPUT1 WRITE COUNT: " WS-OUT1-COUNT
           DISPLAY "------------------------------".

      * --- Main processing
       MAIN-PROCESS.
           *> Sort the records based on the specified key
           SORT WORK-FILE ON
               ASCENDING KEY WORK-REC-KEY
               INPUT PROCEDURE IS READ-AND-EXTRACT-KEY
               OUTPUT PROCEDURE IS WRITE-CLEAN-DATA
               .

       READ-AND-EXTRACT-KEY.
           MOVE "N" TO EOF-FLG
           PERFORM UNTIL EOF-FLG = "Y"
               READ IN1-FILE
                   AT END
                       MOVE "Y" TO EOF-FLG
                   NOT AT END
                       ADD 1 TO WS-IN1-COUNT

                       *> Clear work record
                       MOVE SPACES TO WORK-REC

                       *> Save original record
                       MOVE IN1-REC TO WORK-REC-ORIGINAL
                       *> [Important] Save key.
                       MOVE IN1-REC(WS-ARG-KEY-START:WS-ARG-KEY-LEN)
                           TO WORK-REC-KEY(1:WS-ARG-KEY-LEN)

                       *> Pass records to sort processing
                       RELEASE WORK-REC
               END-READ
           END-PERFORM.

       WRITE-CLEAN-DATA.
           MOVE "N" TO EOF-WORK-FLG
           PERFORM UNTIL EOF-WORK-FLG = "Y"
               *> Retrieve sorted records one by one
               RETURN WORK-FILE
                   AT END
                       MOVE "Y" TO EOF-WORK-FLG
                   NOT AT END
                       ADD 1 TO WS-OUT1-COUNT
                       *> write the original record to output file
                       MOVE WORK-REC-ORIGINAL TO OUT1-REC
                       WRITE OUT1-REC
               END-RETURN
           END-PERFORM.
