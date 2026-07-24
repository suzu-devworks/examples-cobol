       IDENTIFICATION DIVISION.
       PROGRAM-ID. generate_emp.

       ENVIRONMENT DIVISION.
       INPUT-OUTPUT SECTION.
       FILE-CONTROL.
           SELECT OUT-FILE ASSIGN TO WS-FILE-NAME
               ORGANIZATION IS LINE SEQUENTIAL.

       DATA DIVISION.
       FILE SECTION.
       FD  OUT-FILE.
       01  OUT-REC             PIC X(050).

       WORKING-STORAGE SECTION.
      *--- For receiving command line arguments
       01  WS-ARGS.
           05  WS-ARG-COUNT    PIC 9(002) VALUE 0.
           05  WS-FILE-NAME    PIC X(050) VALUE SPACES.
           05  WS-MODE         PIC X(010) VALUE SPACES.
           05  WS-COUNT-STR    PIC X(006) VALUE SPACES.
           05  WS-MAX-RECORDS  PIC 9(006) VALUE 50.  *> Default 50 items

      *--- For loop control
       01  WS-COUNTERS.
           05  WS-OUT1-COUNT   PIC 9(006) VALUE 0.
           05  WS-I            PIC 9(006) VALUE 0.

      *--- Record definition for EMP (employee)
       COPY emp_rec REPLACING ==:PREFIX:== BY ==WK==.
           05  FILLER              PIC X(008).

      *--- For random numbers/logic
       01  WS-RANDOM-SEED      PIC 9(008) VALUE 12345678.
       01  WS-RAND-NUM         PIC 9V9999.
       01  WS-RAND-IDX         PIC 9(001).
search
       01  WS-CURRENT-DATE.
           05  WS-YEAR         PIC 9(004).
           05  FILLER          PIC X(017).

      *--- name table
      *> spell-checker: disable
       01  WS-EMP-TABLE.
           05  FILLER PIC X(010) VALUE "SATO      ".
           05  FILLER PIC X(010) VALUE "SUZUKI    ".
           05  FILLER PIC X(010) VALUE "TANAKA    ".
           05  FILLER PIC X(010) VALUE "TAKAHASHI ".
           05  FILLER PIC X(010) VALUE "WATANABE  ".
           05  FILLER PIC X(010) VALUE "ITO       ".
           05  FILLER PIC X(010) VALUE "NAKAMURA  ".
           05  FILLER PIC X(010) VALUE "KOBAYASHI ".
       01  FILLER REDEFINES WS-EMP-TABLE.
           05  WS-NAMES PIC X(010) OCCURS 8 TIMES.
      *> spell-checker: enable

      *--- Department list
       01  WS-DEPT-TABLE.
           05  FILLER PIC X(014) VALUE "1000SALES     ".
           05  FILLER PIC X(014) VALUE "2000DEV       ".
           05  FILLER PIC X(014) VALUE "3000HR        ".
           05  FILLER PIC X(014) VALUE "4000ACCOUNT   ".
           05  FILLER PIC X(014) VALUE "5000GENERAL   ".
       01  FILLER REDEFINES WS-DEPT-TABLE.
           05  WS-DEPT-ITEMS OCCURS 5 TIMES.
               10  WS-MAP-DEPT-ID   PIC X(004).
               10  WS-MAP-DEPT-NAME PIC X(010).

       PROCEDURE DIVISION.
           PERFORM INITIALIZE-PROCESS
           PERFORM MAIN-PROCESS
           PERFORM TERMINATE-PROCESS
           STOP RUN.

      * --- Initialize process
       INITIALIZE-PROCESS.
           ACCEPT WS-ARG-COUNT FROM ARGUMENT-NUMBER
           IF WS-ARG-COUNT < 1
               PERFORM DISPLAY-USAGE
               STOP RUN
           END-IF

           ACCEPT WS-FILE-NAME FROM ARGUMENT-VALUE
           ACCEPT WS-MODE      FROM ARGUMENT-VALUE
           ACCEPT WS-COUNT-STR FROM ARGUMENT-VALUE

           IF WS-FILE-NAME = SPACES
               PERFORM DISPLAY-USAGE
               STOP RUN
           END-IF

           IF WS-MODE = SPACES
               MOVE "rand" TO WS-MODE
           END-IF

           IF WS-MODE NOT = "rand" AND WS-MODE NOT = "sorted"
               PERFORM DISPLAY-USAGE
               STOP RUN
           END-IF

           IF WS-COUNT-STR NOT = SPACES
               COMPUTE WS-MAX-RECORDS = FUNCTION NUMVAL(WS-COUNT-STR)
           END-IF

           DISPLAY "Generator started."

           MOVE FUNCTION CURRENT-DATE TO WS-CURRENT-DATE
           DISPLAY "CURRENT YEAR: " WS-YEAR

           DISPLAY "OUTPUT FILE:  " FUNCTION TRIM(WS-FILE-NAME)
           DISPLAY "MODE:         " FUNCTION TRIM(WS-MODE)
           DISPLAY "COUNT:        " WS-MAX-RECORDS

           OPEN OUTPUT OUT-FILE.

       DISPLAY-USAGE.
           DISPLAY "Usage: generate_emp [FILENAME] [MODE] [COUNT]"
           DISPLAY "       MODE:   'rand' or 'sorted'"
           DISPLAY "       COUNT:  1 - 999999 (default: 50)".

      * --- Terminate process
       TERMINATE-PROCESS.
           CLOSE OUT-FILE.
           DISPLAY "SUCCESS: Generator Completed."
           DISPLAY "--------------------------"
           DISPLAY "OUTPUT WRITE COUNT: " WS-OUT1-COUNT
           DISPLAY "--------------------------".

      * --- Main processing
       MAIN-PROCESS.
           COMPUTE WS-RAND-NUM = FUNCTION RANDOM(WS-RANDOM-SEED)

           PERFORM VARYING WS-I FROM 1 BY 1 UNTIL WS-I > WS-MAX-RECORDS
               PERFORM GENERATE-RECORD
               PERFORM WRITE-OUT1-RECORD
           END-PERFORM.

       GENERATE-RECORD.
           INITIALIZE WK-EMP-REC

           *> 1. Select employee number
           IF WS-MODE = "sorted"
               COMPUTE WK-EMP-ID = 1000 + WS-I
           ELSE
               COMPUTE WS-RAND-NUM = FUNCTION RANDOM
               COMPUTE WK-EMP-ID = 1001 + (WS-RAND-NUM * 50)
           END-IF

           *> 2. Select employee name
           COMPUTE WS-RAND-NUM = FUNCTION RANDOM
           COMPUTE WS-RAND-IDX = 1 + (WS-RAND-NUM * 8)
           MOVE WS-NAMES(WS-RAND-IDX) TO WK-EMP-NAME

           *> 3 & 4. Select your department id and name
           COMPUTE WS-RAND-NUM = FUNCTION RANDOM
           COMPUTE WS-RAND-IDX = 1 + (WS-RAND-NUM * 5)
           MOVE WS-MAP-DEPT-ID(WS-RAND-IDX) TO WK-EMP-DEPT-ID
           MOVE WS-MAP-DEPT-NAME(WS-RAND-IDX) TO WK-EMP-DEPT-NAME

           *> 5. Joining date
           COMPUTE WS-RAND-NUM = FUNCTION RANDOM
           COMPUTE WK-EMP-JOIN-DATE = (WS-YEAR * 10000)
                   + (1 + FUNCTION INTEGER(WS-RAND-NUM * 12)) * 100
                   + (1 + FUNCTION INTEGER(WS-RAND-NUM * 28))

           *> 6. Generate random salaries
           COMPUTE WS-RAND-NUM = FUNCTION RANDOM
           COMPUTE WK-EMP-SALARY = 200000 + (WS-RAND-NUM * 400000).

       WRITE-OUT1-RECORD.
           WRITE OUT-REC FROM WK-EMP-REC
           ADD 1 TO WS-OUT1-COUNT.
