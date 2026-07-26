       IDENTIFICATION DIVISION.
       PROGRAM-ID. transform_to_csv.

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
       01  OUT-REC     PIC X(120).

       WORKING-STORAGE SECTION.
      *--- For receiving command line arguments
       01  WS-ARGS.
           05  WS-ARG-COUNT        PIC 9(002) VALUE 0.
           05  WS-IN-FILE-PATH     PIC X(1024) VALUE SPACES.
           05  WS-OUT-FILE-PATH    PIC X(1024) VALUE SPACES.

       01  WS-COUNTERS.
           05  WS-IN-COUNT         PIC 9(006) VALUE 0.
           05  WS-OUT-COUNT        PIC 9(006) VALUE 0.

       COPY emp_rec REPLACING ==:PREFIX:== BY ==WK==.
           05  FILLER              PIC X(008).

       01  WS-VARS.
           05  WS-USAGE-STR        PIC X(100).
           05  WS-CURRENT-DATE.
               10 WS-CURRENT-YEAR  PIC 9(04).
               10 WS-CURRENT-MONTH PIC 9(02).
               10 WS-CURRENT-DAY   PIC 9(02).

       01 WS-TRANS-RECORD.
           05  WS-DEPT-NAME        PIC X(020).
           05  WS-SERVICE-YEARS    PIC 9(04).
           05  WS-JOIN-YEAR        PIC 9(04).
           05  WS-ANNUAL-SALARY    PIC 9(08).
           05  WS-FORMAT-YEARS     PIC Z,ZZ9.
           05  WS-FORMAT-SALARY    PIC $$$$,$$9.
           05  WS-FORMAT-ANNUAL    PIC $$$,$$$,$$9.

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

           ACCEPT WS-CURRENT-DATE FROM DATE YYYYMMDD

           DISPLAY "Transforming started."
           DISPLAY "INPUT FILE:  " FUNCTION TRIM(WS-IN-FILE-PATH)
           DISPLAY "OUTPUT FILE: " FUNCTION TRIM(WS-OUT-FILE-PATH)

           OPEN INPUT IN-FILE
           OPEN OUTPUT OUT-FILE.

       DISPLAY-USAGE.
           STRING "transform_to_csv [INPUT_FILE] [OUTPUT_FILE_]"
               INTO WS-USAGE-STR.
           DISPLAY "Usage: " WS-USAGE-STR.

      * --- Terminate process
       TERMINATE-PROCESS.
           CLOSE IN-FILE.
           CLOSE OUT-FILE.
           DISPLAY "SUCCESS: Transforming Completed."
           DISPLAY "--------------------------"
           DISPLAY "INPUT  READ COUNT:  " WS-IN-COUNT
           DISPLAY "OUTPUT WRITE COUNT: " WS-OUT-COUNT
           DISPLAY "--------------------------".

      * --- Main processing
       MAIN-PROCESS.
           PERFORM READ-IN-FILE

           PERFORM UNTIL WK-EMP-REC = HIGH-VALUES
               PERFORM TRANSFORM-RECORD
               PERFORM WRITE-OUT-FILE
               PERFORM READ-IN-FILE
           END-PERFORM.

       TRANSFORM-RECORD.
           *> 1. Department code name conversion (EVALUATE)
           EVALUATE FUNCTION TRIM(WK-EMP-DEPT-NAME)
               WHEN "DEV"      MOVE "開発部"     TO WS-DEPT-NAME
               WHEN "SALES"    MOVE "営業部"     TO WS-DEPT-NAME
               WHEN "HR"       MOVE "人事部"     TO WS-DEPT-NAME
               WHEN "ACCOUNT"  MOVE "経理部"     TO WS-DEPT-NAME
               WHEN "GENERAL"  MOVE "総務部"     TO WS-DEPT-NAME
               WHEN OTHER      MOVE "その他"     TO WS-DEPT-NAME
           END-EVALUATE

           *> 2. Calculation of years of service (COMPUTE / MOVE)
           MOVE WK-EMP-JOIN-DATE(1:4) TO WS-JOIN-YEAR
           COMPUTE WS-SERVICE-YEARS = WS-CURRENT-YEAR - WS-JOIN-YEAR

           *> 3. Annual salary calculation (monthly salary * 12 months + estimated 2 months bonus)
           COMPUTE WS-ANNUAL-SALARY = WK-EMP-SALARY * 14

           *> 4. Formatting
           MOVE WS-SERVICE-YEARS TO WS-FORMAT-YEARS
           MOVE WK-EMP-SALARY    TO WS-FORMAT-SALARY
           MOVE WS-ANNUAL-SALARY TO WS-FORMAT-ANNUAL

           MOVE SPACE TO OUT-REC
           STRING
               WK-EMP-ID                   DELIMITED BY SPACE
               ","                         DELIMITED BY SIZE
               WK-EMP-NAME                 DELIMITED BY SPACE
               ","                         DELIMITED BY SIZE
               WS-DEPT-NAME                DELIMITED BY SPACE
               ","                         DELIMITED BY SIZE
               FUNCTION TRIM(WS-FORMAT-SALARY) DELIMITED BY SIZE
               ","                         DELIMITED BY SIZE
               FUNCTION TRIM(WS-FORMAT-ANNUAL) DELIMITED BY SIZE
               ","                         DELIMITED BY SIZE
               FUNCTION TRIM(WS-FORMAT-YEARS) DELIMITED BY SIZE
               "年"                        DELIMITED BY SIZE
               INTO OUT-REC
           END-STRING.

       WRITE-OUT-FILE.
           WRITE OUT-REC
           ADD 1 TO WS-OUT-COUNT.

       READ-IN-FILE.
           READ IN-FILE INTO WK-EMP-REC
             AT END MOVE HIGH-VALUES TO WK-EMP-REC
             NOT AT END
                   ADD 1 TO WS-IN-COUNT
           END-READ.
