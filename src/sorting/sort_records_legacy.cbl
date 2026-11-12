       IDENTIFICATION DIVISION.
       PROGRAM-ID. sort_records_legacy.

       ENVIRONMENT DIVISION.
       INPUT-OUTPUT SECTION.
       FILE-CONTROL.
           SELECT IN1-FILE     ASSIGN TO WS-IN1-FILE-PATH
                               ORGANIZATION IS LINE SEQUENTIAL
                               FILE STATUS IS WS-IN1-FILE-STATUS.
           SELECT OUT1-FILE    ASSIGN TO WS-OUT1-FILE-PATH
                               ORGANIZATION IS LINE SEQUENTIAL
                               FILE STATUS IS WS-OUT1-FILE-STATUS.

           *> work file for sorting
           SELECT WORK1-FILE   ASSIGN TO WS-WORK1-PATH
                               ORGANIZATION IS LINE SEQUENTIAL
                               FILE STATUS IS WS-WORK1-FILE-STATUS.
           SELECT WORK2-FILE   ASSIGN TO WS-WORK2-PATH
                               ORGANIZATION IS LINE SEQUENTIAL
                               FILE STATUS IS WS-WORK2-FILE-STATUS.
           SELECT WORK3-FILE   ASSIGN TO WS-WORK3-PATH
                               ORGANIZATION IS LINE SEQUENTIAL
                               FILE STATUS IS WS-WORK3-FILE-STATUS.
           SELECT WORK4-FILE   ASSIGN TO WS-WORK4-PATH
                               ORGANIZATION IS LINE SEQUENTIAL
                               FILE STATUS IS WS-WORK4-FILE-STATUS.

       DATA DIVISION.
       FILE SECTION.
       FD  IN1-FILE.
       01  IN1-REC         PIC X(100).
       FD  OUT1-FILE.
       01  OUT1-REC        PIC X(100).
       FD  WORK1-FILE.
       01  W1-REC          PIC X(100).
       FD  WORK2-FILE.
       01  W2-REC          PIC X(100).
       FD  WORK3-FILE.
       01  W3-REC          PIC X(100).
       FD  WORK4-FILE.
       01  W4-REC          PIC X(100).

       WORKING-STORAGE SECTION.
      *--- For receiving command line arguments
       01  WS-ARGS.
           05  WS-ARG-COUNT            PIC 9(002) VALUE 0.
           05  WS-IN1-FILE-PATH        PIC X(1024) VALUE SPACES.
           05  WS-OUT1-FILE-PATH       PIC X(1024) VALUE SPACES.
           05  WS-ARG-KEY-START        PIC 9(003) VALUE 1. *> Starting position (starting from 1)
           05  WS-ARG-KEY-LEN          PIC 9(003) VALUE 4. *> Number of character

       01  WS-WORK-FILES.
           05  WS-WORK1-PATH           PIC X(1024) VALUE SPACES.
           05  WS-WORK2-PATH           PIC X(1024) VALUE SPACES.
           05  WS-WORK3-PATH           PIC X(1024) VALUE SPACES.
           05  WS-WORK4-PATH           PIC X(1024) VALUE SPACES.

       01  WS-WORKS-ARRAY REDEFINES WS-WORK-FILES.
           05 WS-WORKS-PATH OCCURS 4 TIMES PIC X(1024).
       01  WS-WORKS-IDX                PIC 9(001) VALUE 0.

       01  WS-COUNTERS.
           05  WS-IN1-COUNT            PIC 9(006) VALUE 0.
           05  WS-OUT1-COUNT           PIC 9(006) VALUE 0.
           05  WS-I                    PIC 9(005) COMP-5 VALUE 0.

       01  WS-FILE-STATUSES.
       COPY file_statuses
           REPLACING ==:PREFIX:== BY ==WS-IN1==.
       COPY file_statuses
           REPLACING ==:PREFIX:== BY ==WS-OUT1==.
       COPY file_statuses
           REPLACING ==:PREFIX:== BY ==WS-WORK1==.
       COPY file_statuses
           REPLACING ==:PREFIX:== BY ==WS-WORK2==.
       COPY file_statuses
           REPLACING ==:PREFIX:== BY ==WS-WORK3==.
       COPY file_statuses
           REPLACING ==:PREFIX:== BY ==WS-WORK4==.

       01  WS-IO-ERROR.
       COPY file_io_error.

       01  WS-VARS.
           05  WS-USAGE-STR            PIC X(100).
           05  WS-PID                  PIC 9(008).

      * --- For quick sort ---
       COPY quick_sort REPLACING ==:PREFIX:== BY ==WS==.
       01  WS-REC-MAX                  PIC 9(005) VALUE 100.

      * --- For division phase ---
       01  WS-DIV-CTRL.
           05  IN1-EOF                 PIC X(1) VALUE "N".
           05  WS-DIV-TOGGLE           PIC 9(1) VALUE 1.

      * --- For merge phase ---
       01  WS-MERGE-CTRL.
           05  ALL-SORT-DONE           PIC X(1) VALUE "N".
           05  WS-RUN-COUNT            PIC 9(5) VALUE 0.
           05  WS-WRITE-TOGGLE         PIC 9(1) VALUE 3.

       01  WS-MERGE-RECORDS.
           05  W1-CUR-KEY              PIC X(50).
           05  W1-PREV-KEY             PIC X(50).
           05  W1-EOF                  PIC X(1).
           05  W2-CUR-KEY              PIC X(50).
           05  W2-PREV-KEY             PIC X(50).
           05  W2-EOF                  PIC X(1).
           05  W3-CUR-KEY              PIC X(50).
           05  W3-PREV-KEY             PIC X(50).
           05  W3-EOF                  PIC X(1).
           05  W4-CUR-KEY              PIC X(50).
           05  W4-PREV-KEY             PIC X(50).
           05  W4-EOF                  PIC X(1).

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

           DISPLAY "Sort started."
           DISPLAY "INPUT1 FILE:  " FUNCTION TRIM(WS-IN1-FILE-PATH)
           DISPLAY "OUTPUT1 FILE: " FUNCTION TRIM(WS-OUT1-FILE-PATH)

           PERFORM BUILD-WORK-FILE-PATH

           IF WS-ARG-COUNT >= 4
               ACCEPT WS-ARG-KEY-START FROM ARGUMENT-VALUE
               ACCEPT WS-ARG-KEY-LEN   FROM ARGUMENT-VALUE

               IF WS-ARG-KEY-START < 1 OR
                  WS-ARG-KEY-LEN < 1 OR
                  WS-ARG-KEY-START + WS-ARG-KEY-LEN - 1 > 100
                   DISPLAY "ERROR: Invalid key start or length."
                   PERFORM DISPLAY-USAGE
                   MOVE 1 TO RETURN-CODE
                   STOP RUN
               END-IF
           END-IF

           DISPLAY "SORT KEY:     " WS-ARG-KEY-START ":" WS-ARG-KEY-LEN

           PERFORM OPEN-IN1-FILE
           PERFORM OPEN-OUT1-FILE.

       DISPLAY-USAGE.
           STRING
               "sort_records_legacy [IN-FILE] [OUT-FILE]"
               " [KEY-START] [KEY-LEN]"
               INTO WS-USAGE-STR.
           DISPLAY "Usage: " WS-USAGE-STR.

       BUILD-WORK-FILE-PATH.
           CALL "C$GETPID" RETURNING WS-PID
           PERFORM VARYING WS-WORKS-IDX FROM 1 BY 1
                   UNTIL WS-WORKS-IDX > 4
               STRING
                   WS-OUT1-FILE-PATH DELIMITED BY SPACE
                   ".tmp@w" WS-WORKS-IDX DELIMITED BY SIZE
                   "." WS-PID DELIMITED BY SIZE
                   INTO WS-WORKS-PATH(WS-WORKS-IDX)
           END-PERFORM

           DISPLAY "WORK1 FILE: " FUNCTION TRIM(WS-WORK1-PATH)
           DISPLAY "WORK2 FILE: " FUNCTION TRIM(WS-WORK2-PATH)
           DISPLAY "WORK3 FILE: " FUNCTION TRIM(WS-WORK3-PATH)
           DISPLAY "WORK4 FILE: " FUNCTION TRIM(WS-WORK4-PATH).

       TERMINATE-PROCESS.
           DELETE FILE WORK1-FILE WORK2-FILE WORK3-FILE WORK4-FILE
           PERFORM CLOSE-IN1-FILE
           PERFORM CLOSE-OUT1-FILE
           DISPLAY "SUCCESS: Sort completed."
           DISPLAY "------------------------------"
           DISPLAY "INPUT1  READ  COUNT: " WS-IN1-COUNT
           DISPLAY "OUTPUT1 WRITE COUNT: " WS-OUT1-COUNT
           DISPLAY "------------------------------".

       MAIN-PROCESS.
           PERFORM INITIAL-DIVISION-PHASE

           PERFORM PAIRWISE-MERGE-PHASE

           PERFORM FINAL-OUTPUT-PHASE.

      * ---------------------------------------------
       INITIAL-DIVISION-PHASE.
           PERFORM OPEN-WORK1-OUTPUT
           PERFORM OPEN-WORK2-OUTPUT

           MOVE "N" TO IN1-EOF
           MOVE 1   TO WS-DIV-TOGGLE

           PERFORM UNTIL IN1-EOF = "Y"
               MOVE 0 TO WS-REC-CNT

               *> [Safety guard] Read so as not to exceed the maximum number of arrays
               PERFORM UNTIL WS-REC-CNT = WS-REC-MAX OR IN1-EOF = "Y"
                   READ IN1-FILE
                   END-READ
                   EVALUATE TRUE
                       WHEN WS-IN1-FILE-OK
                           ADD 1 TO WS-IN1-COUNT
                           ADD 1 TO WS-REC-CNT
                           MOVE IN1-REC TO WS-REC(WS-REC-CNT)
                       WHEN WS-IN1-FILE-EOF
                           MOVE "Y" TO IN1-EOF
                       WHEN OTHER
                           MOVE "IN1-FILE" TO WS-IO-ERROR-FILE
                           MOVE WS-IN1-FILE-STATUS
                             TO WS-IO-ERROR-CODE
                           PERFORM FILE-IO-ERROR
                   END-EVALUATE
               END-PERFORM

               IF WS-REC-CNT > 0
                   *> Sort the records in memory
                   PERFORM QUICK-SORT-START
                   *> Export sorted chunks to intermediate file
                   PERFORM WRITE-SORTED-RUN

                   IF WS-DIV-TOGGLE = 1
                       MOVE 2 TO WS-DIV-TOGGLE
                   ELSE
                       MOVE 1 TO WS-DIV-TOGGLE
                   END-IF
               END-IF
           END-PERFORM

           PERFORM CLOSE-WORK1-FILE
           PERFORM CLOSE-WORK2-FILE.

       QUICK-SORT-START.
           MOVE WS-ARG-KEY-START TO WS-KEY-START
           MOVE WS-ARG-KEY-LEN   TO WS-KEY-LEN
           CALL "quick_sort" USING BY CONTENT WS-SORT-CONFIG
                                   BY CONTENT WS-REC-CNT
                                   BY REFERENCE WS-MEM-TABLE.

       WRITE-SORTED-RUN.
           MOVE 1 TO WS-I
           IF WS-DIV-TOGGLE = 1
               PERFORM UNTIL WS-I > WS-REC-CNT
                   WRITE W1-REC FROM WS-REC(WS-I)
                   PERFORM VERIFY-WORK1-FILE
                   ADD 1 TO WS-I
               END-PERFORM
           ELSE
               PERFORM UNTIL WS-I > WS-REC-CNT
                   WRITE W2-REC FROM WS-REC(WS-I)
                   PERFORM VERIFY-WORK2-FILE
                   ADD 1 TO WS-I
               END-PERFORM
           END-IF.

      * ---------------------------------------------
       PAIRWISE-MERGE-PHASE.
           PERFORM UNTIL ALL-SORT-DONE = "Y"
               *> WORK1, WORK2 => WORK3, WORK4
               PERFORM MERGE-PASS-1-TO-2

               IF WS-RUN-COUNT <= 1
                   MOVE "Y" TO ALL-SORT-DONE
               ELSE
                   *> WORK3, WORK4 => WORK1, WORK2
                   PERFORM MERGE-PASS-2-TO-1

                   IF WS-RUN-COUNT <= 1
                       MOVE "Y" TO ALL-SORT-DONE
                   END-IF
               END-IF

           END-PERFORM.

       MERGE-PASS-1-TO-2.
           PERFORM OPEN-WORK1-INPUT
           PERFORM OPEN-WORK2-INPUT
           PERFORM OPEN-WORK3-OUTPUT
           PERFORM OPEN-WORK4-OUTPUT

           MOVE "N" TO W1-EOF W2-EOF
           MOVE LOW-VALUES TO W1-PREV-KEY W2-PREV-KEY
           MOVE 0 TO WS-RUN-COUNT
           MOVE 3 TO WS-WRITE-TOGGLE

           PERFORM READ-WORK1
           PERFORM READ-WORK2

           PERFORM UNTIL W1-EOF = "Y" AND W2-EOF = "Y"
               ADD 1 TO WS-RUN-COUNT
               PERFORM MERGE-SINGLE-RUN-12

               IF WS-WRITE-TOGGLE = 3
                   MOVE 4 TO WS-WRITE-TOGGLE
               ELSE
                   MOVE 3 TO WS-WRITE-TOGGLE
               END-IF
           END-PERFORM

           PERFORM CLOSE-WORK1-FILE
           PERFORM CLOSE-WORK2-FILE
           PERFORM CLOSE-WORK3-FILE
           PERFORM CLOSE-WORK4-FILE.

       MERGE-SINGLE-RUN-12.
           PERFORM UNTIL (W1-EOF = "Y" OR W1-CUR-KEY < W1-PREV-KEY) AND
                         (W2-EOF = "Y" OR W2-CUR-KEY < W2-PREV-KEY)

               IF (W1-EOF = "N" AND W1-CUR-KEY >= W1-PREV-KEY) AND
                  (W2-EOF = "Y" OR W2-CUR-KEY < W2-PREV-KEY
                   OR W1-CUR-KEY <= W2-CUR-KEY)
                   PERFORM WRITE-OUT-W34-FROM-W1
                   PERFORM READ-WORK1
               ELSE
                   PERFORM WRITE-OUT-W34-FROM-W2
                   PERFORM READ-WORK2
               END-IF
           END-PERFORM

           PERFORM UNTIL W1-EOF = "Y" OR W1-CUR-KEY < W1-PREV-KEY
               PERFORM WRITE-OUT-W34-FROM-W1
               PERFORM READ-WORK1
           END-PERFORM

           PERFORM UNTIL W2-EOF = "Y" OR W2-CUR-KEY < W2-PREV-KEY
               PERFORM WRITE-OUT-W34-FROM-W2
               PERFORM READ-WORK2
           END-PERFORM

           MOVE LOW-VALUES TO W1-PREV-KEY W2-PREV-KEY.

       MERGE-PASS-2-TO-1.
           PERFORM OPEN-WORK3-INPUT
           PERFORM OPEN-WORK4-INPUT
           PERFORM OPEN-WORK1-OUTPUT
           PERFORM OPEN-WORK2-OUTPUT

           MOVE "N" TO W3-EOF W4-EOF
           MOVE LOW-VALUES TO W3-PREV-KEY W4-PREV-KEY
           MOVE 0 TO WS-RUN-COUNT
           MOVE 1 TO WS-WRITE-TOGGLE

           PERFORM READ-WORK3
           PERFORM READ-WORK4

           PERFORM UNTIL W3-EOF = "Y" AND W4-EOF = "Y"
               ADD 1 TO WS-RUN-COUNT
               PERFORM MERGE-SINGLE-RUN-34

               IF WS-WRITE-TOGGLE = 1
                   MOVE 2 TO WS-WRITE-TOGGLE
               ELSE
                   MOVE 1 TO WS-WRITE-TOGGLE
               END-IF
           END-PERFORM

           PERFORM CLOSE-WORK3-FILE
           PERFORM CLOSE-WORK4-FILE
           PERFORM CLOSE-WORK1-FILE
           PERFORM CLOSE-WORK2-FILE.

       MERGE-SINGLE-RUN-34.
           PERFORM UNTIL (W3-EOF = "Y" OR W3-CUR-KEY < W3-PREV-KEY) AND
                         (W4-EOF = "Y" OR W4-CUR-KEY < W4-PREV-KEY)

               IF (W3-EOF = "N" AND W3-CUR-KEY >= W3-PREV-KEY) AND
                  (W4-EOF = "Y" OR W4-CUR-KEY < W4-PREV-KEY OR
                   W3-CUR-KEY <= W4-CUR-KEY)
                   PERFORM WRITE-OUT-W12-FROM-W3
                   PERFORM READ-WORK3
               ELSE
                   PERFORM WRITE-OUT-W12-FROM-W4
                   PERFORM READ-WORK4
               END-IF
           END-PERFORM

           PERFORM UNTIL W3-EOF = "Y" OR W3-CUR-KEY < W3-PREV-KEY
               PERFORM WRITE-OUT-W12-FROM-W3
               PERFORM READ-WORK3
           END-PERFORM

           PERFORM UNTIL W4-EOF = "Y" OR W4-CUR-KEY < W4-PREV-KEY
               PERFORM WRITE-OUT-W12-FROM-W4
               PERFORM READ-WORK4
           END-PERFORM

           MOVE LOW-VALUES TO W3-PREV-KEY W4-PREV-KEY.

       READ-WORK1.
           MOVE W1-CUR-KEY TO W1-PREV-KEY
           READ WORK1-FILE
           END-READ
           EVALUATE TRUE
               WHEN WS-WORK1-FILE-OK
                   MOVE SPACE TO W1-CUR-KEY
                   MOVE W1-REC(WS-KEY-START:WS-KEY-LEN)
                     TO W1-CUR-KEY(1:WS-KEY-LEN)
               WHEN WS-WORK1-FILE-EOF
                   MOVE "Y" TO W1-EOF
                   MOVE HIGH-VALUES TO W1-CUR-KEY
               WHEN OTHER
                   MOVE "WORK1-FILE" TO WS-IO-ERROR-FILE
                   MOVE WS-WORK1-FILE-STATUS TO WS-IO-ERROR-CODE
                   PERFORM FILE-IO-ERROR
           END-EVALUATE.

       READ-WORK2.
           MOVE W2-CUR-KEY TO W2-PREV-KEY
           READ WORK2-FILE
           END-READ
           EVALUATE TRUE
               WHEN WS-WORK2-FILE-OK
                   MOVE SPACE TO W2-CUR-KEY
                   MOVE W2-REC(WS-KEY-START:WS-KEY-LEN)
                     TO W2-CUR-KEY(1:WS-KEY-LEN)
               WHEN WS-WORK2-FILE-EOF
                   MOVE "Y" TO W2-EOF
                   MOVE HIGH-VALUES TO W2-CUR-KEY
               WHEN OTHER
                   MOVE "WORK2-FILE" TO WS-IO-ERROR-FILE
                   MOVE WS-WORK2-FILE-STATUS TO WS-IO-ERROR-CODE
                   PERFORM FILE-IO-ERROR
           END-EVALUATE.

       READ-WORK3.
           MOVE W3-CUR-KEY TO W3-PREV-KEY
           READ WORK3-FILE
           END-READ
           EVALUATE TRUE
               WHEN WS-WORK3-FILE-OK
                   MOVE SPACE TO W3-CUR-KEY
                   MOVE W3-REC(WS-KEY-START:WS-KEY-LEN)
                     TO W3-CUR-KEY(1:WS-KEY-LEN)
               WHEN WS-WORK3-FILE-EOF
                   MOVE "Y" TO W3-EOF
                   MOVE HIGH-VALUES TO W3-CUR-KEY
               WHEN OTHER
                   MOVE "WORK3-FILE" TO WS-IO-ERROR-FILE
                   MOVE WS-WORK3-FILE-STATUS TO WS-IO-ERROR-CODE
                   PERFORM FILE-IO-ERROR
           END-EVALUATE.

       READ-WORK4.
           MOVE W4-CUR-KEY TO W4-PREV-KEY
           READ WORK4-FILE
           END-READ
           EVALUATE TRUE
               WHEN WS-WORK4-FILE-OK
                   MOVE SPACE TO W4-CUR-KEY
                   MOVE W4-REC(WS-KEY-START:WS-KEY-LEN)
                     TO W4-CUR-KEY(1:WS-KEY-LEN)
               WHEN WS-WORK4-FILE-EOF
                   MOVE "Y" TO W4-EOF
                   MOVE HIGH-VALUES TO W4-CUR-KEY
               WHEN OTHER
                   MOVE "WORK4-FILE" TO WS-IO-ERROR-FILE
                   MOVE WS-WORK4-FILE-STATUS TO WS-IO-ERROR-CODE
                   PERFORM FILE-IO-ERROR
           END-EVALUATE.

       WRITE-OUT-W34-FROM-W1.
           IF WS-WRITE-TOGGLE = 3
               WRITE W3-REC FROM W1-REC
               PERFORM VERIFY-WORK3-FILE
           ELSE
               WRITE W4-REC FROM W1-REC
               PERFORM VERIFY-WORK4-FILE
           END-IF.

       WRITE-OUT-W34-FROM-W2.
           IF WS-WRITE-TOGGLE = 3
               WRITE W3-REC FROM W2-REC
               PERFORM VERIFY-WORK3-FILE
           ELSE
               WRITE W4-REC FROM W2-REC
               PERFORM VERIFY-WORK4-FILE
           END-IF.

       WRITE-OUT-W12-FROM-W3.
           IF WS-WRITE-TOGGLE = 1
               WRITE W1-REC FROM W3-REC
               PERFORM VERIFY-WORK1-FILE
           ELSE
               WRITE W2-REC FROM W3-REC
               PERFORM VERIFY-WORK2-FILE
           END-IF.

       WRITE-OUT-W12-FROM-W4.
           IF WS-WRITE-TOGGLE = 1
               WRITE W1-REC FROM W4-REC
               PERFORM VERIFY-WORK1-FILE
           ELSE
               WRITE W2-REC FROM W4-REC
               PERFORM VERIFY-WORK2-FILE
           END-IF.

      * ---------------------------------------------
       FINAL-OUTPUT-PHASE.
      *    Determine which location has the final data based on the previous value of WS-WRITE-TOGGLE
           IF WS-WRITE-TOGGLE = 1 OR WS-WRITE-TOGGLE = 2
               PERFORM WRITE-OUTPUT-FROM-W1
           ELSE
               PERFORM WRITE-OUTPUT-FROM-W3
           END-IF.

       WRITE-OUTPUT-FROM-W1.
           PERFORM OPEN-WORK1-INPUT
           MOVE "N" TO W1-EOF
           PERFORM UNTIL W1-EOF = "Y"
               READ WORK1-FILE
               END-READ
               EVALUATE TRUE
                   WHEN WS-WORK1-FILE-OK
                       WRITE OUT1-REC FROM W1-REC
                       PERFORM VERIFY-OUT1-FILE
                       ADD 1 TO WS-OUT1-COUNT
                   WHEN WS-WORK1-FILE-EOF
                       MOVE "Y" TO W1-EOF
                   WHEN OTHER
                       MOVE "WORK1-FILE" TO WS-IO-ERROR-FILE
                       MOVE WS-WORK1-FILE-STATUS TO WS-IO-ERROR-CODE
                       PERFORM FILE-IO-ERROR
               END-EVALUATE
           END-PERFORM
           PERFORM CLOSE-WORK1-FILE.

       WRITE-OUTPUT-FROM-W3.
           PERFORM OPEN-WORK3-INPUT
           MOVE "N" TO W3-EOF
           PERFORM UNTIL W3-EOF = "Y"
               READ WORK3-FILE
               END-READ
               EVALUATE TRUE
                   WHEN WS-WORK3-FILE-OK
                       WRITE OUT1-REC FROM W3-REC
                       PERFORM VERIFY-OUT1-FILE
                       ADD 1 TO WS-OUT1-COUNT
                   WHEN WS-WORK3-FILE-EOF
                       MOVE "Y" TO W3-EOF
                   WHEN OTHER
                       MOVE "WORK3-FILE" TO WS-IO-ERROR-FILE
                       MOVE WS-WORK3-FILE-STATUS TO WS-IO-ERROR-CODE
                       PERFORM FILE-IO-ERROR
               END-EVALUATE
           END-PERFORM
           PERFORM CLOSE-WORK3-FILE.

       OPEN-IN1-FILE.
           OPEN INPUT IN1-FILE
           PERFORM VERIFY-IN1-FILE.

       CLOSE-IN1-FILE.
           CLOSE IN1-FILE
           PERFORM VERIFY-IN1-FILE.

       VERIFY-IN1-FILE.
           IF NOT WS-IN1-FILE-OK
               MOVE "IN1-FILE" TO WS-IO-ERROR-FILE
               MOVE WS-IN1-FILE-STATUS TO WS-IO-ERROR-CODE
               PERFORM FILE-IO-ERROR
           END-IF.

       OPEN-OUT1-FILE.
           OPEN OUTPUT OUT1-FILE
           PERFORM VERIFY-OUT1-FILE.

       CLOSE-OUT1-FILE.
           CLOSE OUT1-FILE
           PERFORM VERIFY-OUT1-FILE.

       VERIFY-OUT1-FILE.
           IF NOT WS-OUT1-FILE-OK
               MOVE "OUT1-FILE" TO WS-IO-ERROR-FILE
               MOVE WS-OUT1-FILE-STATUS TO WS-IO-ERROR-CODE
               PERFORM FILE-IO-ERROR
           END-IF.

       OPEN-WORK1-INPUT.
           OPEN INPUT WORK1-FILE
           PERFORM VERIFY-WORK1-FILE.

       OPEN-WORK1-OUTPUT.
           OPEN OUTPUT WORK1-FILE
           PERFORM VERIFY-WORK1-FILE.

       CLOSE-WORK1-FILE.
           CLOSE WORK1-FILE
           PERFORM VERIFY-WORK1-FILE.

       VERIFY-WORK1-FILE.
           IF NOT WS-WORK1-FILE-OK
               MOVE "WORK1-FILE" TO WS-IO-ERROR-FILE
               MOVE WS-WORK1-FILE-STATUS TO WS-IO-ERROR-CODE
               PERFORM FILE-IO-ERROR
           END-IF.

       OPEN-WORK2-INPUT.
           OPEN INPUT WORK2-FILE
           PERFORM VERIFY-WORK2-FILE.

       OPEN-WORK2-OUTPUT.
           OPEN OUTPUT WORK2-FILE
           PERFORM VERIFY-WORK2-FILE.

       CLOSE-WORK2-FILE.
           CLOSE WORK2-FILE
           PERFORM VERIFY-WORK2-FILE.

       VERIFY-WORK2-FILE.
           IF NOT WS-WORK2-FILE-OK
               MOVE "WORK2-FILE" TO WS-IO-ERROR-FILE
               MOVE WS-WORK2-FILE-STATUS TO WS-IO-ERROR-CODE
               PERFORM FILE-IO-ERROR
           END-IF.

       OPEN-WORK3-INPUT.
           OPEN INPUT WORK3-FILE
           PERFORM VERIFY-WORK3-FILE.

       OPEN-WORK3-OUTPUT.
           OPEN OUTPUT WORK3-FILE
           PERFORM VERIFY-WORK3-FILE.

       CLOSE-WORK3-FILE.
           CLOSE WORK3-FILE
           PERFORM VERIFY-WORK3-FILE.


       VERIFY-WORK3-FILE.
           IF NOT WS-WORK3-FILE-OK
               MOVE "WORK3-FILE" TO WS-IO-ERROR-FILE
               MOVE WS-WORK3-FILE-STATUS TO WS-IO-ERROR-CODE
               PERFORM FILE-IO-ERROR
           END-IF.

       OPEN-WORK4-INPUT.
           OPEN INPUT WORK4-FILE
           PERFORM VERIFY-WORK4-FILE.

       OPEN-WORK4-OUTPUT.
           OPEN OUTPUT WORK4-FILE
           PERFORM VERIFY-WORK4-FILE.

       CLOSE-WORK4-FILE.
           CLOSE WORK4-FILE
           PERFORM VERIFY-WORK4-FILE.

       VERIFY-WORK4-FILE.
           IF NOT WS-WORK4-FILE-OK
               MOVE "WORK4-FILE" TO WS-IO-ERROR-FILE
               MOVE WS-WORK4-FILE-STATUS TO WS-IO-ERROR-CODE
               PERFORM FILE-IO-ERROR
           END-IF.
       COPY file_io_error_proc.
