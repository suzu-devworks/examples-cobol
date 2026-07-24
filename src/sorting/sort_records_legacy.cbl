       IDENTIFICATION DIVISION.
       PROGRAM-ID. sort_records_legacy.

       ENVIRONMENT DIVISION.
       INPUT-OUTPUT SECTION.
       FILE-CONTROL.
           SELECT IN-FILE  ASSIGN TO WS-IN-FILE-PATH
                           ORGANIZATION IS LINE SEQUENTIAL.
           SELECT OUT-FILE ASSIGN TO WS-OUT-FILE-PATH
                           ORGANIZATION IS LINE SEQUENTIAL.

           *> work file for sorting
           SELECT WORK-F1 ASSIGN TO WS-WORK-F1-PATH
                           ORGANIZATION IS LINE SEQUENTIAL.
           SELECT WORK-F2 ASSIGN TO WS-WORK-F2-PATH
                           ORGANIZATION IS LINE SEQUENTIAL.
           SELECT WORK-F3 ASSIGN TO WS-WORK-F3-PATH
                           ORGANIZATION IS LINE SEQUENTIAL.
           SELECT WORK-F4 ASSIGN TO WS-WORK-F4-PATH
                           ORGANIZATION IS LINE SEQUENTIAL.

       DATA DIVISION.
       FILE SECTION.
       FD  IN-FILE.
       01  IN-REC          PIC X(100).
       FD  OUT-FILE.
       01  OUT-REC         PIC X(100).
       FD  WORK-F1.
       01  W1-REC          PIC X(100).
       FD  WORK-F2.
       01  W2-REC          PIC X(100).
       FD  WORK-F3.
       01  W3-REC          PIC X(100).
       FD  WORK-F4.
       01  W4-REC          PIC X(100).

       WORKING-STORAGE SECTION.
      *--- For receiving command line arguments
       01  WS-ARGS.
           05  WS-ARG-COUNT            PIC 9(002) VALUE 0.
           05  WS-IN-FILE-PATH         PIC X(100) VALUE SPACES.
           05  WS-OUT-FILE-PATH        PIC X(100) VALUE SPACES.
           05  WS-ARG-KEY-START        PIC 9(003) VALUE 1. *> Starting position (starting from 1)
           05  WS-ARG-KEY-LEN          PIC 9(003) VALUE 4. *> Number of character

       01  WS-WORK-FILES.
           05  WS-WORK-F1-PATH         PIC X(100) VALUE SPACES.
           05  WS-WORK-F2-PATH         PIC X(100) VALUE SPACES.
           05  WS-WORK-F3-PATH         PIC X(100) VALUE SPACES.
           05  WS-WORK-F4-PATH         PIC X(100) VALUE SPACES.

       01  WS-WORK-FILE-ARRAY REDEFINES WS-WORK-FILES.
           05 WS-WORK-FILE-PATH OCCURS 4 TIMES PIC X(100).
       01  WS-WORK-IDX                 PIC 9(001) VALUE 0.

       01  WS-COUNTERS.
           05  WS-IN-COUNT             PIC 9(006) VALUE 0.
           05  WS-OUT-COUNT            PIC 9(006) VALUE 0.
           05  WS-I                    PIC 9(005) COMP-5 VALUE 0.

       01  WS-VARS.
           05  WS-USAGE-STR            PIC X(100).
           05  WS-PID                  PIC 9(008).

      * --- For quick sort ---
       COPY "quick_sort.cpy" REPLACING ==:PREFIX:== BY ==WS==.
       01  WS-REC-MAX                  PIC 9(005) VALUE 100.

      * --- For division phase ---
       01  WS-DIV-CTRL.
           05  IN-EOF                  PIC X(1) VALUE "N".
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
               STOP RUN
           END-IF

           ACCEPT WS-IN-FILE-PATH  FROM ARGUMENT-VALUE
           ACCEPT WS-OUT-FILE-PATH FROM ARGUMENT-VALUE

           IF WS-IN-FILE-PATH = SPACES OR WS-OUT-FILE-PATH = SPACES
               PERFORM DISPLAY-USAGE
               STOP RUN
           END-IF

           DISPLAY "Sort started."
           DISPLAY "INPUT FILE:   " FUNCTION TRIM(WS-IN-FILE-PATH)
           DISPLAY "OUTPUT FILE:  " FUNCTION TRIM(WS-OUT-FILE-PATH)

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

           OPEN INPUT IN-FILE
           OPEN OUTPUT OUT-FILE.

       DISPLAY-USAGE.
           STRING
               "sort_records_legacy [IN-FILE] [OUT-FILE]"
               " [KEY-START] [KEY-LEN]"
               INTO WS-USAGE-STR.
           DISPLAY "Usage: " WS-USAGE-STR.

       BUILD-WORK-FILE-PATH.
           CALL "C$GETPID" RETURNING WS-PID
           PERFORM VARYING WS-WORK-IDX FROM 1 BY 1
                   UNTIL WS-WORK-IDX > 4
               STRING
                   WS-OUT-FILE-PATH DELIMITED BY SPACE
                   ".tmp@w" WS-WORK-IDX DELIMITED BY SIZE
                   "." WS-PID DELIMITED BY SIZE
                   INTO WS-WORK-FILE-PATH(WS-WORK-IDX)
           END-PERFORM

           DISPLAY "WORK FILE 1:  " FUNCTION TRIM(WS-WORK-F1-PATH)
           DISPLAY "WORK FILE 2:  " FUNCTION TRIM(WS-WORK-F2-PATH)
           DISPLAY "WORK FILE 3:  " FUNCTION TRIM(WS-WORK-F3-PATH)
           DISPLAY "WORK FILE 4:  " FUNCTION TRIM(WS-WORK-F4-PATH).

      * --- Terminate process
       TERMINATE-PROCESS.
           DELETE FILE WORK-F1 WORK-F2 WORK-F3 WORK-F4

           CLOSE IN-FILE
           CLOSE OUT-FILE
           DISPLAY "SUCCESS: Sort Completed."
           DISPLAY "--------------------------"
           DISPLAY "INPUT  READ COUNT:  " WS-IN-COUNT
           DISPLAY "OUTPUT WRITE COUNT: " WS-OUT-COUNT
           DISPLAY "--------------------------".

      * --- Main processing
       MAIN-PROCESS.
           PERFORM INITIAL-DIVISION-PHASE

           PERFORM PAIRWISE-MERGE-PHASE

           PERFORM FINAL-OUTPUT-PHASE.

      * ---------------------------------------------
       INITIAL-DIVISION-PHASE.
           OPEN OUTPUT WORK-F1 WORK-F2

           MOVE "N" TO IN-EOF
           MOVE 1   TO WS-DIV-TOGGLE

           PERFORM UNTIL IN-EOF = "Y"
               MOVE 0 TO WS-REC-CNT

               *> [Safety guard] Read so as not to exceed the maximum number of arrays
               PERFORM UNTIL WS-REC-CNT = WS-REC-MAX OR IN-EOF = "Y"
                   READ IN-FILE
                       AT END
                           MOVE "Y" TO IN-EOF
                       NOT AT END
                           ADD 1 TO WS-IN-COUNT
                           ADD 1 TO WS-REC-CNT
                           MOVE IN-REC TO WS-REC(WS-REC-CNT)
                   END-READ
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

           CLOSE WORK-F1 WORK-F2.

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
                   ADD 1 TO WS-I
               END-PERFORM
           ELSE
               PERFORM UNTIL WS-I > WS-REC-CNT
                   WRITE W2-REC FROM WS-REC(WS-I)
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
           OPEN INPUT WORK-F1 WORK-F2
           OPEN OUTPUT WORK-F3 WORK-F4

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

           CLOSE WORK-F1 WORK-F2 WORK-F3 WORK-F4.

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
           OPEN INPUT WORK-F3 WORK-F4
           OPEN OUTPUT WORK-F1 WORK-F2

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

           CLOSE WORK-F3 WORK-F4 WORK-F1 WORK-F2.

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
           READ WORK-F1
               AT END MOVE "Y" TO W1-EOF
                      MOVE HIGH-VALUES TO W1-CUR-KEY
               NOT AT END MOVE SPACE TO W1-CUR-KEY
                          MOVE W1-REC(WS-KEY-START:WS-KEY-LEN)
                            TO W1-CUR-KEY(1:WS-KEY-LEN)
           END-READ.

       READ-WORK2.
           MOVE W2-CUR-KEY TO W2-PREV-KEY
           READ WORK-F2
               AT END MOVE "Y" TO W2-EOF
                      MOVE HIGH-VALUES TO W2-CUR-KEY
               NOT AT END MOVE SPACE TO W2-CUR-KEY
                          MOVE W2-REC(WS-KEY-START:WS-KEY-LEN)
                            TO W2-CUR-KEY(1:WS-KEY-LEN)
           END-READ.

       READ-WORK3.
           MOVE W3-CUR-KEY TO W3-PREV-KEY
           READ WORK-F3
               AT END MOVE "Y" TO W3-EOF
                      MOVE HIGH-VALUES TO W3-CUR-KEY
               NOT AT END MOVE SPACE TO W3-CUR-KEY
                          MOVE W3-REC(WS-KEY-START:WS-KEY-LEN)
                            TO W3-CUR-KEY(1:WS-KEY-LEN)
           END-READ.

       READ-WORK4.
           MOVE W4-CUR-KEY TO W4-PREV-KEY
           READ WORK-F4
               AT END MOVE "Y" TO W4-EOF
                      MOVE HIGH-VALUES TO W4-CUR-KEY
               NOT AT END MOVE SPACE TO W4-CUR-KEY
                          MOVE W4-REC(WS-KEY-START:WS-KEY-LEN)
                            TO W4-CUR-KEY(1:WS-KEY-LEN)
           END-READ.

       WRITE-OUT-W34-FROM-W1.
           IF WS-WRITE-TOGGLE = 3
               WRITE W3-REC FROM W1-REC
           ELSE
               WRITE W4-REC FROM W1-REC
           END-IF.

       WRITE-OUT-W34-FROM-W2.
           IF WS-WRITE-TOGGLE = 3
               WRITE W3-REC FROM W2-REC
           ELSE
               WRITE W4-REC FROM W2-REC
           END-IF.

       WRITE-OUT-W12-FROM-W3.
           IF WS-WRITE-TOGGLE = 1
               WRITE W1-REC FROM W3-REC
           ELSE
               WRITE W2-REC FROM W3-REC
           END-IF.

       WRITE-OUT-W12-FROM-W4.
           IF WS-WRITE-TOGGLE = 1
               WRITE W1-REC FROM W4-REC
           ELSE
               WRITE W2-REC FROM W4-REC
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
           OPEN INPUT WORK-F1
           MOVE "N" TO W1-EOF
           PERFORM UNTIL W1-EOF = "Y"
               READ WORK-F1
                   AT END MOVE "Y" TO W1-EOF
                   NOT AT END
                       WRITE OUT-REC FROM W1-REC
                       ADD 1 TO WS-OUT-COUNT
               END-READ
           END-PERFORM
           CLOSE WORK-F1.

       WRITE-OUTPUT-FROM-W3.
           OPEN INPUT WORK-F3
           MOVE "N" TO W3-EOF
           PERFORM UNTIL W3-EOF = "Y"
               READ WORK-F3
                   AT END MOVE "Y" TO W3-EOF
                   NOT AT END
                       WRITE OUT-REC FROM W3-REC
                       ADD 1 TO WS-OUT-COUNT
               END-READ
           END-PERFORM
           CLOSE WORK-F3.
