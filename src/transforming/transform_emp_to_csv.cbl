       IDENTIFICATION DIVISION.
       PROGRAM-ID. transform_emp_to_csv.

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
       01  IN1-REC         PIC X(050).
       FD  OUT1-FILE.
       01  OUT1-REC        PIC X(120).

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
               MOVE 1 TO RETURN-CODE
               STOP RUN
           END-IF

           ACCEPT WS-IN1-FILE-PATH  FROM ARGUMENT-VALUE
           ACCEPT WS-OUT1-FILE-PATH FROM ARGUMENT-VALUE

           IF WS-IN1-FILE-PATH = SPACES OR WS-OUT1-FILE-PATH = SPACES
               PERFORM DISPLAY-USAGE
               MOVE 1 TO RETURN-CODE
               STOP RUN
           END-IF

           ACCEPT WS-CURRENT-DATE FROM DATE YYYYMMDD

           DISPLAY "Transforming started."
           DISPLAY "INPUT1 FILE:  " FUNCTION TRIM(WS-IN1-FILE-PATH)
           DISPLAY "OUTPUT1 FILE: " FUNCTION TRIM(WS-OUT1-FILE-PATH)

           OPEN INPUT IN1-FILE
           OPEN OUTPUT OUT1-FILE.

       DISPLAY-USAGE.
           STRING "transform_emp_to_csv [INPUT_FILE] [OUTPUT_FILE_]"
               INTO WS-USAGE-STR.
           DISPLAY "Usage: " WS-USAGE-STR.

      * --- Terminate process
       TERMINATE-PROCESS.
           CLOSE IN1-FILE.
           CLOSE OUT1-FILE.
           DISPLAY "SUCCESS: Transforming completed."
           DISPLAY "------------------------------"
           DISPLAY "INPUT1  READ  COUNT: " WS-IN1-COUNT
           DISPLAY "OUTPUT1 WRITE COUNT: " WS-OUT1-COUNT
           DISPLAY "------------------------------".

      * --- Main processing
       MAIN-PROCESS.
           PERFORM READ-IN1-FILE

           PERFORM UNTIL WS-IN1-REC = HIGH-VALUES
               PERFORM TRANSFORM-RECORD
               PERFORM WRITE-OUT1-FILE
               PERFORM READ-IN1-FILE
           END-PERFORM.

       TRANSFORM-RECORD.
           *> 1. Department code name conversion (EVALUATE)
           EVALUATE FUNCTION TRIM(EMP-DEPT-NAME)
               WHEN "DEV"      MOVE "開発部"     TO WS-DEPT-NAME
               WHEN "SALES"    MOVE "営業部"     TO WS-DEPT-NAME
               WHEN "HR"       MOVE "人事部"     TO WS-DEPT-NAME
               WHEN "ACCOUNT"  MOVE "経理部"     TO WS-DEPT-NAME
               WHEN "GENERAL"  MOVE "総務部"     TO WS-DEPT-NAME
               WHEN OTHER      MOVE "その他"     TO WS-DEPT-NAME
           END-EVALUATE

           *> 2. Calculation of years of service (COMPUTE / MOVE)
           MOVE EMP-JOIN-DATE(1:4) TO WS-JOIN-YEAR
           COMPUTE WS-SERVICE-YEARS = WS-CURRENT-YEAR - WS-JOIN-YEAR

           *> 3. Annual salary calculation (monthly salary * 12 months + estimated 2 months bonus)
           COMPUTE WS-ANNUAL-SALARY = EMP-SALARY * 14

           *> 4. Formatting
           MOVE WS-SERVICE-YEARS   TO WS-FORMAT-YEARS
           MOVE EMP-SALARY         TO WS-FORMAT-SALARY
           MOVE WS-ANNUAL-SALARY   TO WS-FORMAT-ANNUAL

           MOVE SPACE TO OUT1-REC
           STRING
               EMP-ID                      DELIMITED BY SPACE
               ","                         DELIMITED BY SIZE
               EMP-NAME                    DELIMITED BY SPACE
               ","                         DELIMITED BY SIZE
               WS-DEPT-NAME                DELIMITED BY SPACE
               ","                         DELIMITED BY SIZE
               FUNCTION TRIM(WS-FORMAT-SALARY) DELIMITED BY SIZE
               ","                         DELIMITED BY SIZE
               FUNCTION TRIM(WS-FORMAT-ANNUAL) DELIMITED BY SIZE
               ","                         DELIMITED BY SIZE
               FUNCTION TRIM(WS-FORMAT-YEARS) DELIMITED BY SIZE
               "年"                        DELIMITED BY SIZE
               INTO OUT1-REC
           END-STRING.

       WRITE-OUT1-FILE.
           WRITE OUT1-REC
           ADD 1 TO WS-OUT1-COUNT.

       READ-IN1-FILE.
           READ IN1-FILE INTO WS-IN1-REC
             AT END MOVE HIGH-VALUES TO WS-IN1-REC
             NOT AT END
                   ADD 1 TO WS-IN1-COUNT
           END-READ.
