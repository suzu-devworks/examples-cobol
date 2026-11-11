       IDENTIFICATION DIVISION.
       PROGRAM-ID. group_by_dept.

       ENVIRONMENT DIVISION.
       INPUT-OUTPUT SECTION.
       FILE-CONTROL.
           SELECT IN1-FILE     ASSIGN TO WS-IN1-FILE-PATH
                               ORGANIZATION IS LINE SEQUENTIAL.
           SELECT OUT1-FILE    ASSIGN TO WS-OUT1-FILE-PATH
                               ORGANIZATION IS LINE SEQUENTIAL.

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

       01  WS-IN1-REC.
       COPY emp_rec.
           05  FILLER              PIC X(008).

       01  WS-OUT1-REC.
       COPY dept_rec.
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

           OPEN INPUT IN1-FILE
           OPEN OUTPUT OUT1-FILE.

       DISPLAY-USAGE.
           STRING "group_by_dept [INPUT_FILE] [OUTPUT_FILE]"
               INTO WS-USAGE-STR.
           DISPLAY "Usage: " WS-USAGE-STR.

      * --- Terminate process
       TERMINATE-PROCESS.
           CLOSE IN1-FILE.
           CLOSE OUT1-FILE.
           DISPLAY "SUCCESS: Grouping completed."
           DISPLAY "------------------------------"
           DISPLAY "INPUT1  READ  COUNT: " WS-IN1-COUNT
           DISPLAY "OUTPUT1 WRITE COUNT: " WS-OUT1-COUNT
           DISPLAY "------------------------------".

      * --- Main processing
       MAIN-PROCESS.
           PERFORM READ-IN1-FILE

           PERFORM UNTIL WS-IN1-REC = HIGH-VALUES
               INITIALIZE WS-OUT1-REC
               MOVE EMP-DEPT-ID TO DEPT-ID
               MOVE 0 TO WS-DEPT-MAX-SALARY

               PERFORM UNTIL WS-IN1-REC = HIGH-VALUES OR
                       NOT EMP-DEPT-ID = DEPT-ID
                   PERFORM EDIT-OUT1-REC
                   PERFORM READ-IN1-FILE
               END-PERFORM

               PERFORM WRITE-OUT1-FILE
           END-PERFORM.

       EDIT-OUT1-REC.
           MOVE EMP-DEPT-ID TO DEPT-ID
           MOVE EMP-DEPT-NAME TO DEPT-NAME

           IF WS-DEPT-MAX-SALARY < EMP-SALARY
               MOVE EMP-ID TO DEPT-MANAGER-ID
               MOVE EMP-NAME TO DEPT-MANAGER-NAME

               MOVE EMP-SALARY TO WS-DEPT-MAX-SALARY
           END-IF

           ADD 1 TO DEPT-MEMBER-COUNT.

       WRITE-OUT1-FILE.
           WRITE OUT1-REC FROM WS-OUT1-REC
           ADD 1 TO WS-OUT1-COUNT.
           DISPLAY "DEPT-ID: " DEPT-ID
                   " DEPT-NAME: " DEPT-NAME
                   " MANAGER-ID: " DEPT-MANAGER-ID
                   " MANAGER-NAME: " DEPT-MANAGER-NAME
                   " MEMBER-COUNT: " DEPT-MEMBER-COUNT
                   " MAX-SALARY: " WS-DEPT-MAX-SALARY.

       READ-IN1-FILE.
           READ IN1-FILE INTO WS-IN1-REC
             AT END MOVE HIGH-VALUES TO WS-IN1-REC
             NOT AT END
                   ADD 1 TO WS-IN1-COUNT
           END-READ.
