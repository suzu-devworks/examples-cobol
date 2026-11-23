       IDENTIFICATION DIVISION.
       PROGRAM-ID. report_emp_by_dept.

       ENVIRONMENT DIVISION.
       INPUT-OUTPUT SECTION.
       FILE-CONTROL.
           SELECT IN1-FILE ASSIGN TO WS-IN1-FILE-PATH
               ORGANIZATION IS LINE SEQUENTIAL
               FILE STATUS IS WS-IN1-FILE-STATUS.
           SELECT REPORT-FILE ASSIGN TO WS-REPORT-FILE-PATH
               ORGANIZATION IS LINE SEQUENTIAL
               FILE STATUS IS WS-REPORT-FILE-STATUS.

       DATA DIVISION.
       FILE SECTION.
       FD  IN1-FILE.
       01  IN1-REC                 PIC X(050).
       FD  REPORT-FILE
           REPORT IS EMPLOYEE-REPORT.

       WORKING-STORAGE SECTION.
       01  WS-ARGS.
           05  WS-ARG-COUNT        PIC 9(002) VALUE 0.
           05  WS-IN1-FILE-PATH    PIC X(1024) VALUE SPACES.
           05  WS-REPORT-FILE-PATH PIC X(1024) VALUE SPACES.

       01  WS-COUNTERS.
           05  WS-IN1-COUNT        PIC 9(009) VALUE 0.
           05  WS-REPORT-PAGES     PIC 9(009) VALUE 0.
           05  WS-INVALID-RECORD-COUNT
                                   PIC 9(009) VALUE 0.

       01  WS-FILE-STATUSES.
       COPY file_statuses
           REPLACING ==:PREFIX:== BY ==WS-IN1==.
       COPY file_statuses
           REPLACING ==:PREFIX:== BY ==WS-REPORT==.

       01  WS-IO-ERROR-DATA.
       COPY file_io_error.

       01  WS-IN1-REC.
       COPY emp_rec REPLACING ==:PREFIX:== BY ==WS-IN1==.
           05  FILLER              PIC X(008).

       01  WS-GRAND-TOTALS.
           05  WS-TOTAL-COUNT      PIC 9(009) VALUE 0.
           05  WS-TOTAL-SALARY     PIC 9(015) VALUE 0.
       01  WS-DEPT-TOTALS.
           05  WS-DEPT-COUNT       PIC 9(009) VALUE 0.
           05  WS-DEPT-SALARY      PIC 9(015) VALUE 0.

       01  WS-DEPT-CONTROL.
           05  WS-LAST-DEPT-ID-RAW PIC X(004) VALUE SPACES.
           05  WS-LAST-DEPT-NAME   PIC X(010) VALUE SPACES.
           05  WS-DEPT-STARTED     PIC X VALUE "N".

       01  WS-FORMATTED-DETAIL.
           05 WS-FORMATTED-JOIN-DATE   PIC X(010).
           05 WS-FORMATTED-SALARY      PIC X(009).

       01  WS-FORMAT.
           05  WS-DATE-CHECK           PIC 9(008) VALUE 0.
           05  WS-DATE-EDIT            PIC 9999/99/99.
           05  WS-SALARY-EDIT          PIC ZZZ,ZZ9.
           05  WS-CURRENT-RECORD-INVALID   PIC X VALUE "N".

       REPORT SECTION.
       RD  EMPLOYEE-REPORT
           CONTROLS ARE WS-IN1-EMP-DEPT-ID-RAW
           PAGE LIMIT IS 60 LINES
               HEADING 1
               FIRST DETAIL 6
               LAST CONTROL HEADING 54
               LAST DETAIL 56
               FOOTING 59.

       01  EMPLOYEE-PAGE-HEADING TYPE PAGE HEADING.
           05  LINE 1.
               10  COLUMN 1    PIC X(024)
                   VALUE "DEPARTMENT EMPLOYEE LIST".
           05  LINE 2.
               10  COLUMN 47   PIC X(005) VALUE "PAGE.".
               10  COLUMN 52   PIC ZZZ,ZZ9
                   SOURCE PAGE-COUNTER.
           05  LINE 4.
               10  COLUMN 1    PIC X(004) VALUE "DEPT".
               10  COLUMN 7    PIC X(010) VALUE "DEPARTMENT".
               10  COLUMN 19   PIC X(002) VALUE "ID".
               10  COLUMN 25   PIC X(013) VALUE "EMPLOYEE NAME".
               10  COLUMN 41   PIC X(009) VALUE "JOIN DATE".
               10  COLUMN 53   PIC X(006) VALUE "SALARY".
           05  LINE 5.
               10  COLUMN 1    PIC X(061) VALUE ALL "-".

       01  EMPLOYEE-DEPT-FOOTING TYPE CONTROL FOOTING
           WS-IN1-EMP-DEPT-ID-RAW
           NEXT GROUP IS PLUS 1.
           05  LINE PLUS 1.
               10  COLUMN 1    PIC X(004)
                   SOURCE WS-LAST-DEPT-ID-RAW.
               10  COLUMN 7    PIC X(010)
                   SOURCE WS-LAST-DEPT-NAME.
               10  COLUMN 25   PIC X(008) VALUE "RECORDS:".
               10  COLUMN 49   PIC ZZZ,ZZZ,ZZ9
                   SOURCE WS-DEPT-COUNT.
           05  LINE PLUS 1.
               10  COLUMN 25   PIC X(007) VALUE "SALARY:".
               10  COLUMN 41   PIC ZZZ,ZZZ,ZZZ,ZZZ,ZZ9
                   SOURCE WS-DEPT-SALARY.

       01  EMPLOYEE-DETAIL TYPE DETAIL.
           05  LINE PLUS 1.
               10  COLUMN 1    PIC X(004)
                   SOURCE WS-IN1-EMP-DEPT-ID-RAW
                   GROUP INDICATE.
               10  COLUMN 7    PIC X(010)
                   SOURCE WS-IN1-EMP-DEPT-NAME
                   GROUP INDICATE.
               10  COLUMN 19   PIC X(004)
                   SOURCE WS-IN1-EMP-ID-RAW.
               10  COLUMN 25   PIC X(010)
                   SOURCE WS-IN1-EMP-NAME.
               10  COLUMN 41   PIC X(010)
                   SOURCE WS-FORMATTED-JOIN-DATE.
               10  COLUMN 53   PIC X(009)
                   SOURCE WS-FORMATTED-SALARY.
       01  NO-EMPLOYEE-DETAIL TYPE DETAIL.
           05  LINE PLUS 1.
               10  COLUMN 1    PIC X(020)
                   VALUE "NO EMPLOYEE RECORDS".

       01  EMPLOYEE-REPORT-FOOTING TYPE REPORT FOOTING.
           05  LINE PLUS 2.
               10  COLUMN 1    PIC X(005) VALUE 'TOTAL'.
               10  COLUMN 25   PIC X(019)
                   VALUE "RECORDS:".
               10  COLUMN 49   PIC ZZZ,ZZZ,ZZ9
                   SOURCE WS-TOTAL-COUNT.
           05  LINE PLUS 1.
               10  COLUMN 25   PIC X(013)
                   VALUE "SALARY:".
               10  COLUMN 41   PIC ZZZ,ZZZ,ZZZ,ZZZ,ZZ9
                   SOURCE WS-TOTAL-SALARY.

       PROCEDURE DIVISION.
           PERFORM INITIALIZE-PROCESS
           PERFORM MAIN-PROCESS
           PERFORM TERMINATE-PROCESS
           STOP RUN.

       INITIALIZE-PROCESS.
           ACCEPT WS-ARG-COUNT FROM ARGUMENT-NUMBER
           IF WS-ARG-COUNT NOT = 2
               DISPLAY "Usage: report_emp_by_dept"
                       " INPUT_FILE OUTPUT_FILE"
               MOVE 1 TO RETURN-CODE
               STOP RUN
           END-IF

           ACCEPT WS-IN1-FILE-PATH FROM ARGUMENT-VALUE
           ACCEPT WS-REPORT-FILE-PATH FROM ARGUMENT-VALUE
           IF WS-IN1-FILE-PATH = SPACES OR
              WS-REPORT-FILE-PATH = SPACES OR
              WS-IN1-FILE-PATH = WS-REPORT-FILE-PATH
               DISPLAY "ERROR: Input and output paths must be"
                       " different."
               MOVE 1 TO RETURN-CODE
               STOP RUN
           END-IF

           PERFORM OPEN-IN1-FILE
           PERFORM OPEN-REPORT-FILE
           INITIATE EMPLOYEE-REPORT.

       TERMINATE-PROCESS.
           MOVE PAGE-COUNTER TO WS-REPORT-PAGES
           TERMINATE EMPLOYEE-REPORT
           PERFORM VALIDATE-REPORT-FILE-STATUS
           PERFORM CLOSE-IN1-FILE
           PERFORM CLOSE-REPORT-FILE
           DISPLAY "SUCCESS: Department employee report completed."
           DISPLAY "------------------------------"
           DISPLAY "INPUT1 READ COUNT: " WS-IN1-COUNT
           DISPLAY "REPORT PAGE:       " WS-REPORT-PAGES
           DISPLAY "INVALID RECORD COUNT: " WS-INVALID-RECORD-COUNT
           DISPLAY "------------------------------".

       MAIN-PROCESS.
           PERFORM READ-IN1-FILE
           IF WS-IN1-FILE-EOF
               GENERATE NO-EMPLOYEE-DETAIL
               PERFORM VALIDATE-REPORT-FILE-STATUS
           ELSE
               INITIALIZE WS-GRAND-TOTALS
               PERFORM UNTIL WS-IN1-FILE-EOF
                   ADD 1 TO WS-TOTAL-COUNT
                   IF WS-IN1-EMP-SALARY-RAW IS NUMERIC
                       ADD WS-IN1-EMP-SALARY TO WS-TOTAL-SALARY
                   END-IF

                   PERFORM FORMAT-EMPLOYEE-DETAIL
                   GENERATE EMPLOYEE-DETAIL
                   PERFORM VALIDATE-REPORT-FILE-STATUS

                   IF WS-DEPT-STARTED = "Y" AND
                      WS-LAST-DEPT-ID-RAW NOT = WS-IN1-EMP-DEPT-ID-RAW
                       INITIALIZE WS-DEPT-TOTALS
                   END-IF

                   ADD 1 TO WS-DEPT-COUNT
                   IF WS-IN1-EMP-SALARY-RAW IS NUMERIC
                       ADD WS-IN1-EMP-SALARY TO WS-DEPT-SALARY
                   END-IF
                   MOVE WS-IN1-EMP-DEPT-ID-RAW TO WS-LAST-DEPT-ID-RAW
                   MOVE WS-IN1-EMP-DEPT-NAME TO WS-LAST-DEPT-NAME
                   MOVE "Y" TO WS-DEPT-STARTED

                   PERFORM READ-IN1-FILE
               END-PERFORM
           END-IF.

       FORMAT-EMPLOYEE-DETAIL.
           MOVE "N" TO WS-CURRENT-RECORD-INVALID

           IF WS-IN1-EMP-JOIN-DATE-RAW IS NUMERIC
               IF FUNCTION TEST-DATE-YYYYMMDD(WS-IN1-EMP-JOIN-DATE) = 0
                   MOVE WS-IN1-EMP-JOIN-DATE TO WS-DATE-EDIT
                   MOVE WS-DATE-EDIT TO WS-FORMATTED-JOIN-DATE
               ELSE
                   MOVE "NAN" TO WS-FORMATTED-JOIN-DATE
                   MOVE "Y" TO WS-CURRENT-RECORD-INVALID
               END-IF
           ELSE
               MOVE "NAN" TO WS-FORMATTED-JOIN-DATE
               MOVE "Y" TO WS-CURRENT-RECORD-INVALID
           END-IF

           IF WS-IN1-EMP-SALARY-RAW IS NUMERIC
               MOVE WS-IN1-EMP-SALARY TO WS-SALARY-EDIT
               MOVE WS-SALARY-EDIT TO WS-FORMATTED-SALARY
           ELSE
               MOVE "NAN" TO WS-FORMATTED-SALARY
               MOVE "Y" TO WS-CURRENT-RECORD-INVALID
           END-IF

           IF WS-CURRENT-RECORD-INVALID = "Y"
               ADD 1 TO WS-INVALID-RECORD-COUNT
           END-IF.

       VALIDATE-REPORT-FILE-STATUS.
           IF NOT WS-REPORT-FILE-OK
               MOVE "REPORT-FILE" TO WS-IO-ERROR-FILE
               MOVE WS-REPORT-FILE-STATUS TO WS-IO-ERROR-CODE
               PERFORM FILE-IO-ERROR
           END-IF.

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
                   MOVE IN1-REC TO WS-IN1-REC
               WHEN WS-IN1-FILE-EOF
                   MOVE HIGH-VALUES TO WS-IN1-REC
               WHEN OTHER
                   MOVE "IN1-FILE" TO WS-IO-ERROR-FILE
                   MOVE WS-IN1-FILE-STATUS TO WS-IO-ERROR-CODE
                   PERFORM FILE-IO-ERROR
           END-EVALUATE.

       OPEN-REPORT-FILE.
           OPEN OUTPUT REPORT-FILE
           IF NOT WS-REPORT-FILE-OK
               MOVE "REPORT-FILE" TO WS-IO-ERROR-FILE
               MOVE WS-REPORT-FILE-STATUS TO WS-IO-ERROR-CODE
               PERFORM FILE-IO-ERROR
           END-IF.

       CLOSE-REPORT-FILE.
           CLOSE REPORT-FILE
           IF NOT WS-REPORT-FILE-OK
               MOVE "REPORT-FILE" TO WS-IO-ERROR-FILE
               MOVE WS-REPORT-FILE-STATUS TO WS-IO-ERROR-CODE
               PERFORM FILE-IO-ERROR
           END-IF.

       COPY file_io_error_proc.
