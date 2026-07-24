       IDENTIFICATION DIVISION.
       PROGRAM-ID. group_by_dept.

       ENVIRONMENT DIVISION.
       INPUT-OUTPUT SECTION.
       FILE-CONTROL.
           SELECT IN-FILE  ASSIGN TO WS-IN-FILE-PATH
                           ORGANIZATION IS LINE SEQUENTIAL.
           SELECT OUT-FILE ASSIGN TO WS-OUT-FILE-PATH
                           ORGANIZATION IS LINE SEQUENTIAL.

       DATA DIVISION.
       FILE SECTION.
       FD  IN-FILE.
       01  IN-REC      PIC X(050).
       FD  OUT-FILE.
       01  OUT-REC     PIC X(050).

       WORKING-STORAGE SECTION.
      *--- For receiving command line arguments
       01  WS-ARGS.
           05  WS-ARG-COUNT        PIC 9(002) VALUE 0.
           05  WS-IN-FILE-PATH     PIC X(100) VALUE SPACES.
           05  WS-OUT-FILE-PATH    PIC X(100) VALUE SPACES.

       01  WS-COUNTERS.
           05  WS-IN-COUNT         PIC 9(006) VALUE 0.
           05  WS-OUT-COUNT        PIC 9(006) VALUE 0.

       COPY emp_rec REPLACING ==:PREFIX:== BY ==WK==.
           05  FILLER              PIC X(008).

       COPY dept_rec REPLACING ==:PREFIX:== BY ==WK==.
           05  FILLER              PIC X(016).

       01  WS-VARS.
           05  WS-USAGE-STR        PIC X(100).
           05  WS-DEPT-MAX-SALARY  PIC 9(006) VALUE 0.

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
           ACCEPT WS-OUT-FILE-PATH FROM ARGUMENT-VALUE

           IF WS-IN-FILE-PATH = SPACES OR WS-OUT-FILE-PATH = SPACES
               PERFORM DISPLAY-USAGE
               STOP RUN
           END-IF

           DISPLAY "Grouping started."
           DISPLAY "INPUT FILE:   " FUNCTION TRIM(WS-IN-FILE-PATH)
           DISPLAY "OUTPUT FILE:  " FUNCTION TRIM(WS-OUT-FILE-PATH)

           OPEN INPUT IN-FILE
           OPEN OUTPUT OUT-FILE.

       DISPLAY-USAGE.
           STRING "group_by_dept [INPUT_FILE] [OUTPUT_FILE]"
               INTO WS-USAGE-STR.
           DISPLAY "Usage: " WS-USAGE-STR.

      * --- Terminate process
       TERMINATE-PROCESS.
           CLOSE IN-FILE.
           CLOSE OUT-FILE.
           DISPLAY "SUCCESS: Grouping Completed."
           DISPLAY "--------------------------"
           DISPLAY "INPUT  READ COUNT:  " WS-IN-COUNT
           DISPLAY "OUTPUT WRITE COUNT: " WS-OUT-COUNT
           DISPLAY "--------------------------".

      * --- Main processing
       MAIN-PROCESS.
           PERFORM READ-IN-FILE

           PERFORM UNTIL WK-EMP-REC = HIGH-VALUES
               INITIALIZE WK-DEPT-REC
               MOVE WK-EMP-DEPT-ID TO WK-DEPT-ID
               MOVE 0 TO WS-DEPT-MAX-SALARY

               PERFORM UNTIL WK-EMP-REC = HIGH-VALUES OR
                           NOT WK-EMP-DEPT-ID = WK-DEPT-ID
                   PERFORM EDIT-DEPT-REC
                   PERFORM READ-IN-FILE
               END-PERFORM

               PERFORM WRITE-DEPT-FILE
           END-PERFORM.

       EDIT-DEPT-REC.
           MOVE WK-EMP-DEPT-ID TO WK-DEPT-ID
           MOVE WK-EMP-DEPT-NAME TO WK-DEPT-NAME

           IF WS-DEPT-MAX-SALARY < WK-EMP-SALARY
               MOVE WK-EMP-ID TO WK-DEPT-MANAGER-ID
               MOVE WK-EMP-NAME TO WK-DEPT-MANAGER-NAME
               MOVE WK-EMP-SALARY TO WS-DEPT-MAX-SALARY
           END-IF

           ADD 1 TO WK-DEPT-MEMBER-COUNT.

       WRITE-DEPT-FILE.
           WRITE OUT-REC FROM WK-DEPT-REC
           ADD 1 TO WS-OUT-COUNT.
           DISPLAY "DEPT-ID: " WK-DEPT-ID
                   " DEPT-NAME: " WK-DEPT-NAME
                   " MANAGER-ID: " WK-DEPT-MANAGER-ID
                   " MANAGER-NAME: " WK-DEPT-MANAGER-NAME
                   " MEMBER-COUNT: " WK-DEPT-MEMBER-COUNT
                   " MAX-SALARY: " WS-DEPT-MAX-SALARY.

       READ-IN-FILE.
           READ IN-FILE INTO WK-EMP-REC
             AT END MOVE HIGH-VALUES TO WK-EMP-REC
             NOT AT END
                   ADD 1 TO WS-IN-COUNT
           END-READ.
