       IDENTIFICATION DIVISION.
       PROGRAM-ID. transform_from_emp_csv.

       ENVIRONMENT DIVISION.
       INPUT-OUTPUT SECTION.
       FILE-CONTROL.
           SELECT IN1-FILE     ASSIGN TO WS-IN1-FILE-PATH
                               ORGANIZATION IS LINE SEQUENTIAL
                               FILE STATUS IS WS-IN1-FILE-STATUS.
           SELECT OUT1-FILE    ASSIGN TO WS-OUT1-FILE-PATH
                               ORGANIZATION IS LINE SEQUENTIAL
                               FILE STATUS IS WS-OUT1-FILE-STATUS.

       DATA DIVISION.
       FILE SECTION.
       FD  IN1-FILE.
       01  IN1-REC                 PIC X(1024).
       FD  OUT1-FILE.
       01  OUT1-REC                PIC X(042).

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

       01  WS-IO-ERROR.
       COPY file_io_error.

       01  WS-OUT1-REC-GROUP.
       COPY emp_rec REPLACING ==:PREFIX:== BY ==WS-OUT1==.

       01  WS-CSV-FIELDS.
           05  WS-CSV-EMP-ID       PIC X(1024) VALUE SPACES.
           05  WS-CSV-EMP-NAME     PIC X(1024) VALUE SPACES.
           05  WS-CSV-DEPT-ID      PIC X(1024) VALUE SPACES.
           05  WS-CSV-JOIN-DATE    PIC X(1024) VALUE SPACES.
           05  WS-CSV-EXTRA        PIC X(1024) VALUE SPACES.
           05  WS-CSV-FIELD-COUNT  PIC 9(002) VALUE 0.
           05  WS-CSV-QUOTE-COUNT  PIC 9(004) COMP-5 VALUE 0.
           05  WS-NORMALIZED-EMP-ID PIC X(004) VALUE SPACES.
           05  WS-NORMALIZED-NAME  PIC X(010) VALUE SPACES.
           05  WS-NORMALIZED-DEPT-ID PIC X(004) VALUE SPACES.
           05  WS-NORMALIZED-DATE  PIC X(008) VALUE SPACES.

       01  WS-FLAGS.
           05  WS-FIRST-RECORD     PIC X VALUE "Y".

       PROCEDURE DIVISION.
           PERFORM INITIALIZE-PROCESS
           PERFORM MAIN-PROCESS
           PERFORM TERMINATE-PROCESS
           STOP RUN.

       INITIALIZE-PROCESS.
           ACCEPT WS-ARG-COUNT FROM ARGUMENT-NUMBER
           IF WS-ARG-COUNT NOT = 2
               PERFORM DISPLAY-USAGE
               MOVE 1 TO RETURN-CODE
               STOP RUN
           END-IF

           ACCEPT WS-IN1-FILE-PATH FROM ARGUMENT-VALUE
           ACCEPT WS-OUT1-FILE-PATH FROM ARGUMENT-VALUE
           IF WS-IN1-FILE-PATH = SPACES OR
              WS-OUT1-FILE-PATH = SPACES OR
              WS-IN1-FILE-PATH = WS-OUT1-FILE-PATH
               PERFORM INVALID-ARGUMENTS
           END-IF

           DISPLAY "Employee CSV transformation started."
           DISPLAY "INPUT FILE:  " FUNCTION TRIM(WS-IN1-FILE-PATH)
           DISPLAY "OUTPUT FILE: " FUNCTION TRIM(WS-OUT1-FILE-PATH)

           PERFORM OPEN-IN1-FILE
           PERFORM OPEN-OUT1-FILE.

       DISPLAY-USAGE.
           DISPLAY "Usage: transform_from_emp_csv"
           DISPLAY "       [INPUT_CSV] [OUTPUT_FILE]".

       INVALID-ARGUMENTS.
           DISPLAY "ERROR: Invalid arguments."
           PERFORM DISPLAY-USAGE
           MOVE 1 TO RETURN-CODE
           STOP RUN.

       TERMINATE-PROCESS.
           PERFORM CLOSE-IN1-FILE
           PERFORM CLOSE-OUT1-FILE
           DISPLAY "SUCCESS: Employee CSV transformation completed."
           DISPLAY "------------------------------"
           DISPLAY "INPUT1  READ  COUNT: " WS-IN1-COUNT
           DISPLAY "OUTPUT1 WRITE COUNT: " WS-OUT1-COUNT
           DISPLAY "------------------------------".

       MAIN-PROCESS.
           PERFORM READ-IN1-FILE
           PERFORM UNTIL WS-IN1-FILE-EOF
               IF WS-FIRST-RECORD = "Y" AND
                  FUNCTION TRIM(IN1-REC) =
                    "employee_id,employee_name,department_id,join_date"
                   MOVE "N" TO WS-FIRST-RECORD
               ELSE
                   MOVE "N" TO WS-FIRST-RECORD
                   PERFORM TRANSFORM-RECORD
                   PERFORM WRITE-OUT1-FILE
               END-IF
               PERFORM READ-IN1-FILE
           END-PERFORM.

       TRANSFORM-RECORD.
           MOVE SPACES TO WS-CSV-FIELDS
           MOVE 0 TO WS-CSV-FIELD-COUNT
           MOVE 0 TO WS-CSV-QUOTE-COUNT
           INSPECT IN1-REC
               TALLYING WS-CSV-QUOTE-COUNT FOR ALL X"22"

           UNSTRING IN1-REC DELIMITED BY ","
               INTO WS-CSV-EMP-ID
                    WS-CSV-EMP-NAME
                    WS-CSV-DEPT-ID
                    WS-CSV-JOIN-DATE
                    WS-CSV-EXTRA
               TALLYING IN WS-CSV-FIELD-COUNT
           END-UNSTRING

           IF WS-CSV-FIELD-COUNT NOT = 4 OR
              WS-CSV-QUOTE-COUNT > 0 OR
              WS-CSV-EXTRA NOT = SPACES
               PERFORM INVALID-RECORD
           END-IF

           IF FUNCTION LENGTH(FUNCTION TRIM(WS-CSV-EMP-ID)) NOT = 4 OR
              FUNCTION TRIM(WS-CSV-EMP-ID) IS NOT NUMERIC
               PERFORM INVALID-RECORD
           END-IF
           MOVE FUNCTION TRIM(WS-CSV-EMP-ID)
             TO WS-NORMALIZED-EMP-ID

           IF FUNCTION LENGTH(
                  FUNCTION TRIM(WS-CSV-EMP-NAME)) < 1 OR
              FUNCTION LENGTH(
                  FUNCTION TRIM(WS-CSV-EMP-NAME)) > 10
               PERFORM INVALID-RECORD
           END-IF
           MOVE FUNCTION TRIM(WS-CSV-EMP-NAME)
             TO WS-NORMALIZED-NAME

           IF FUNCTION LENGTH(FUNCTION TRIM(WS-CSV-DEPT-ID)) NOT = 4 OR
              FUNCTION TRIM(WS-CSV-DEPT-ID) IS NOT NUMERIC
               PERFORM INVALID-RECORD
           END-IF
           MOVE FUNCTION TRIM(WS-CSV-DEPT-ID)
             TO WS-NORMALIZED-DEPT-ID

           IF FUNCTION LENGTH(
                  FUNCTION TRIM(WS-CSV-JOIN-DATE)) NOT = 8 OR
              FUNCTION TRIM(WS-CSV-JOIN-DATE) IS NOT NUMERIC
               PERFORM INVALID-RECORD
           END-IF
           MOVE FUNCTION TRIM(WS-CSV-JOIN-DATE)
             TO WS-NORMALIZED-DATE

           INITIALIZE WS-OUT1-REC-GROUP
           MOVE WS-NORMALIZED-EMP-ID TO WS-OUT1-EMP-ID
           MOVE WS-NORMALIZED-NAME TO WS-OUT1-EMP-NAME
           MOVE WS-NORMALIZED-DEPT-ID TO WS-OUT1-EMP-DEPT-ID
           MOVE WS-NORMALIZED-DATE TO WS-OUT1-EMP-JOIN-DATE.

       INVALID-RECORD.
           DISPLAY "ERROR: Invalid employee CSV record at line "
                   WS-IN1-COUNT "."
           MOVE 1 TO RETURN-CODE
           STOP RUN.

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
           END-READ
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
           WRITE OUT1-REC FROM WS-OUT1-REC-GROUP
           IF NOT WS-OUT1-FILE-OK
               MOVE "OUT1-FILE" TO WS-IO-ERROR-FILE
               MOVE WS-OUT1-FILE-STATUS TO WS-IO-ERROR-CODE
               PERFORM FILE-IO-ERROR
           END-IF
           ADD 1 TO WS-OUT1-COUNT.

       COPY file_io_error_proc.
