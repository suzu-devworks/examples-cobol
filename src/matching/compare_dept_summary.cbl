       IDENTIFICATION DIVISION.
       PROGRAM-ID. compare_dept_summary.

       ENVIRONMENT DIVISION.
       INPUT-OUTPUT SECTION.
       FILE-CONTROL.
           SELECT IN1-FILE ASSIGN TO WS-IN1-FILE-PATH
               ORGANIZATION IS LINE SEQUENTIAL
               FILE STATUS IS WS-IN1-FILE-STATUS.
           SELECT IN2-FILE ASSIGN TO WS-IN2-FILE-PATH
               ORGANIZATION IS LINE SEQUENTIAL
               FILE STATUS IS WS-IN2-FILE-STATUS.
           SELECT OUT1-FILE ASSIGN TO WS-OUT1-FILE-PATH
               ORGANIZATION IS LINE SEQUENTIAL
               FILE STATUS IS WS-OUT1-FILE-STATUS.

       DATA DIVISION.
       FILE SECTION.
       FD  IN1-FILE.
       01  IN1-REC                 PIC X(032).
       FD  IN2-FILE.
       01  IN2-REC                 PIC X(032).
       FD  OUT1-FILE.
       01  OUT1-REC                PIC X(069).

       WORKING-STORAGE SECTION.
       01  WS-ARGS.
           05  WS-ARG-COUNT        PIC 9(002) VALUE 0.
           05  WS-IN1-FILE-PATH    PIC X(1024) VALUE SPACES.
           05  WS-IN2-FILE-PATH    PIC X(1024) VALUE SPACES.
           05  WS-OUT1-FILE-PATH   PIC X(1024) VALUE SPACES.

       01  WS-COUNTERS.
           05  WS-IN1-COUNT        PIC 9(006) VALUE 0.
           05  WS-IN2-COUNT        PIC 9(006) VALUE 0.
           05  WS-OUT1-COUNT       PIC 9(006) VALUE 0.

       01  WS-FILE-STATUSES.
       COPY file_statuses
           REPLACING ==:PREFIX:== BY ==WS-IN1==.
       COPY file_statuses
           REPLACING ==:PREFIX:== BY ==WS-IN2==.
       COPY file_statuses
           REPLACING ==:PREFIX:== BY ==WS-OUT1==.

       01  WS-IO-ERROR-DATA.
       COPY file_io_error.

       01  WS-IN1-DEPT.
       COPY dept_rec REPLACING ==:PREFIX:== BY ==WS-IN1==.

       01  WS-IN2-DEPT.
       COPY dept_rec REPLACING ==:PREFIX:== BY ==WS-IN2==.

       01  WS-CURRENT-DEPT-ID       PIC 9(004) VALUE 0.
       01  WS-OUTPUT-STATUS         PIC X(001) VALUE SPACE.
       01  WS-IN1-ORDER.
           05  WS-IN1-LAST-DEPT-ID  PIC 9(004) VALUE 0.
           05  WS-IN1-HAS-LAST      PIC X(001) VALUE "N".
       01  WS-IN2-ORDER.
           05  WS-IN2-LAST-DEPT-ID  PIC 9(004) VALUE 0.
           05  WS-IN2-HAS-LAST      PIC X(001) VALUE "N".

       PROCEDURE DIVISION.
           PERFORM INITIALIZE-PROCESS
           PERFORM MAIN-PROCESS
           PERFORM TERMINATE-PROCESS
           STOP RUN.

       INITIALIZE-PROCESS.
           ACCEPT WS-ARG-COUNT FROM ARGUMENT-NUMBER
           IF WS-ARG-COUNT NOT = 3
               DISPLAY "Usage: compare_dept_summary PREVIOUS_FILE"
                       " CURRENT_FILE OUTPUT_FILE"
               MOVE 1 TO RETURN-CODE
               STOP RUN
           END-IF
           ACCEPT WS-IN1-FILE-PATH FROM ARGUMENT-VALUE
           ACCEPT WS-IN2-FILE-PATH FROM ARGUMENT-VALUE
           ACCEPT WS-OUT1-FILE-PATH FROM ARGUMENT-VALUE
           IF WS-IN1-FILE-PATH = SPACES OR
              WS-IN2-FILE-PATH = SPACES OR
              WS-OUT1-FILE-PATH = SPACES OR
              WS-IN1-FILE-PATH = WS-OUT1-FILE-PATH OR
              WS-IN2-FILE-PATH = WS-OUT1-FILE-PATH
               DISPLAY "ERROR: Output path must differ from"
                       " input paths."
               MOVE 1 TO RETURN-CODE
               STOP RUN
           END-IF
           PERFORM OPEN-IN1-FILE
           PERFORM OPEN-IN2-FILE
           PERFORM OPEN-OUT1-FILE.

       TERMINATE-PROCESS.
           PERFORM CLOSE-IN1-FILE
           PERFORM CLOSE-IN2-FILE
           PERFORM CLOSE-OUT1-FILE
           DISPLAY "SUCCESS: Department summary comparison completed."
           DISPLAY "---------------------------"
           DISPLAY "INPUT1  READ  COUNT: " WS-IN1-COUNT
           DISPLAY "INPUT2  READ  COUNT: " WS-IN2-COUNT
           DISPLAY "OUTPUT1 WRITE COUNT: " WS-OUT1-COUNT
           DISPLAY "---------------------------".

       MAIN-PROCESS.
           PERFORM READ-IN1-FILE
           PERFORM READ-IN2-FILE
           PERFORM UNTIL WS-IN1-DEPT = HIGH-VALUES AND
                         WS-IN2-DEPT = HIGH-VALUES
               EVALUATE TRUE
                   WHEN WS-IN1-DEPT-ID(1:4) < WS-IN2-DEPT-ID(1:4)
                       MOVE WS-IN1-DEPT-ID TO WS-CURRENT-DEPT-ID
                       MOVE "D" TO WS-OUTPUT-STATUS
                       PERFORM EDIT-OUTPUT-RECORD
                       PERFORM WRITE-OUT1-FILE
                       PERFORM READ-IN1-FILE
                   WHEN WS-IN1-DEPT-ID(1:4) > WS-IN2-DEPT-ID(1:4)
                       MOVE WS-IN2-DEPT-ID TO WS-CURRENT-DEPT-ID
                       MOVE "N" TO WS-OUTPUT-STATUS
                       PERFORM EDIT-OUTPUT-RECORD
                       PERFORM WRITE-OUT1-FILE
                       PERFORM READ-IN2-FILE
                   WHEN OTHER
                       MOVE WS-IN1-DEPT-ID TO WS-CURRENT-DEPT-ID
                       IF IN1-REC = IN2-REC
                           MOVE "U" TO WS-OUTPUT-STATUS
                       ELSE
                           MOVE "C" TO WS-OUTPUT-STATUS
                       END-IF
                       PERFORM EDIT-OUTPUT-RECORD
                       PERFORM WRITE-OUT1-FILE
                       PERFORM READ-IN1-FILE
                       PERFORM READ-IN2-FILE
               END-EVALUATE
           END-PERFORM.

       EDIT-OUTPUT-RECORD.
           MOVE SPACES TO OUT1-REC
           MOVE WS-CURRENT-DEPT-ID TO OUT1-REC(1:4)
           MOVE WS-OUTPUT-STATUS TO OUT1-REC(5:1)
           IF WS-IN1-DEPT-ID(1:4) = WS-CURRENT-DEPT-ID(1:4)
               MOVE IN1-REC TO OUT1-REC(6:32)
           END-IF
           IF WS-IN2-DEPT-ID(1:4) = WS-CURRENT-DEPT-ID(1:4)
               MOVE IN2-REC TO OUT1-REC(38:32)
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
           READ IN1-FILE INTO WS-IN1-DEPT
           EVALUATE TRUE
               WHEN WS-IN1-FILE-OK
                   ADD 1 TO WS-IN1-COUNT
                   IF WS-IN1-DEPT-ID IS NOT NUMERIC OR
                      WS-IN1-DEPT-MANAGER-ID IS NOT NUMERIC OR
                      WS-IN1-DEPT-MEMBER-COUNT IS NOT NUMERIC
                       PERFORM INVALID-IN1-RECORD
                   END-IF
                   IF WS-IN1-HAS-LAST = "Y" AND
                      WS-IN1-DEPT-ID <= WS-IN1-LAST-DEPT-ID
                       PERFORM INVALID-IN1-RECORD
                   END-IF
                   MOVE WS-IN1-DEPT-ID TO WS-IN1-LAST-DEPT-ID
                   MOVE "Y" TO WS-IN1-HAS-LAST
               WHEN WS-IN1-FILE-EOF
                   MOVE HIGH-VALUES TO WS-IN1-DEPT
               WHEN OTHER
                   MOVE "IN1-FILE" TO WS-IO-ERROR-FILE
                   MOVE WS-IN1-FILE-STATUS TO WS-IO-ERROR-CODE
                   PERFORM FILE-IO-ERROR
           END-EVALUATE.

       OPEN-IN2-FILE.
           OPEN INPUT IN2-FILE
           IF NOT WS-IN2-FILE-OK
               MOVE "IN2-FILE" TO WS-IO-ERROR-FILE
               MOVE WS-IN2-FILE-STATUS TO WS-IO-ERROR-CODE
               PERFORM FILE-IO-ERROR
           END-IF.

       CLOSE-IN2-FILE.
           CLOSE IN2-FILE
           IF NOT WS-IN2-FILE-OK
               MOVE "IN2-FILE" TO WS-IO-ERROR-FILE
               MOVE WS-IN2-FILE-STATUS TO WS-IO-ERROR-CODE
               PERFORM FILE-IO-ERROR
           END-IF.

       READ-IN2-FILE.
           READ IN2-FILE INTO WS-IN2-DEPT
           EVALUATE TRUE
               WHEN WS-IN2-FILE-OK
                   ADD 1 TO WS-IN2-COUNT
                   IF WS-IN2-DEPT-ID IS NOT NUMERIC OR
                      WS-IN2-DEPT-MANAGER-ID IS NOT NUMERIC OR
                      WS-IN2-DEPT-MEMBER-COUNT IS NOT NUMERIC
                       PERFORM INVALID-IN2-RECORD
                   END-IF
                   IF WS-IN2-HAS-LAST = "Y" AND
                      WS-IN2-DEPT-ID <= WS-IN2-LAST-DEPT-ID
                       PERFORM INVALID-IN2-RECORD
                   END-IF
                   MOVE WS-IN2-DEPT-ID TO WS-IN2-LAST-DEPT-ID
                   MOVE "Y" TO WS-IN2-HAS-LAST
               WHEN WS-IN2-FILE-EOF
                   MOVE HIGH-VALUES TO WS-IN2-DEPT
               WHEN OTHER
                   MOVE "IN2-FILE" TO WS-IO-ERROR-FILE
                   MOVE WS-IN2-FILE-STATUS TO WS-IO-ERROR-CODE
                   PERFORM FILE-IO-ERROR
           END-EVALUATE.

       INVALID-IN1-RECORD.
           DISPLAY "ERROR: Invalid previous summary at record "
                   WS-IN1-COUNT "."
           MOVE 1 TO RETURN-CODE
           STOP RUN.

       INVALID-IN2-RECORD.
           DISPLAY "ERROR: Invalid current summary at record "
                   WS-IN2-COUNT "."
           MOVE 1 TO RETURN-CODE
           STOP RUN.

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
           WRITE OUT1-REC
           IF NOT WS-OUT1-FILE-OK
               MOVE "OUT1-FILE" TO WS-IO-ERROR-FILE
               MOVE WS-OUT1-FILE-STATUS TO WS-IO-ERROR-CODE
               PERFORM FILE-IO-ERROR
           END-IF
           ADD 1 TO WS-OUT1-COUNT.

       COPY file_io_error_proc.
