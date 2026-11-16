       IDENTIFICATION DIVISION.
       PROGRAM-ID. write_dept_summary_db.

       ENVIRONMENT DIVISION.
       INPUT-OUTPUT SECTION.
       FILE-CONTROL.
           SELECT IN1-FILE ASSIGN TO WS-IN1-FILE-PATH
               ORGANIZATION IS LINE SEQUENTIAL
               FILE STATUS IS WS-IN1-FILE-STATUS.

       DATA DIVISION.
       FILE SECTION.
       FD  IN1-FILE.
       01  IN1-REC                 PIC X(032).

       WORKING-STORAGE SECTION.
       01  WS-ARGS.
           05  WS-ARG-COUNT        PIC 9(002) VALUE 0.
           05  WS-DB-PATH-ARG      PIC X(1024) VALUE SPACES.
           05  WS-RUN-MONTH        PIC X(006) VALUE SPACES.
           05  WS-IN1-FILE-PATH    PIC X(1024) VALUE SPACES.

       01  WS-COUNTERS.
           05  WS-IN1-COUNT        PIC 9(006) VALUE 0.

       01  WS-FILE-STATUS.
       COPY file_statuses
           REPLACING ==:PREFIX:== BY ==WS-IN1==.

       01  WS-IO-ERROR.
       COPY file_io_error.

       01  WS-DATABASE.
       COPY sqlite.
       01  WS-DATABASE-WORK.
           05  WS-SQL-POS           PIC 9(004) COMP-5 VALUE 1.
           05  WS-NAME-POS          PIC 9(002) COMP-5 VALUE 0.
           05  WS-NAME-LENGTH       PIC 9(002) COMP-5 VALUE 0.
           05  WS-NAME-TO-QUOTE     PIC X(010) VALUE SPACES.
           05  WS-TRANSACTION-OPEN  PIC X(001) VALUE "N".
           05  WS-FAILURE-TYPE      PIC X(004) VALUE SPACES.
           05  WS-SQLITE-ERROR-CODE PIC S9(9) COMP-5 VALUE 0.
           05  WS-ROLLBACK-STATUS   PIC X VALUE "N".
               88 WS-ROLLBACK-OK    VALUE "Y".
       01  WS-SQL                   PIC X(2048) VALUE SPACES.

       01  WS-IN1-DEPT.
       COPY dept_rec REPLACING ==:PREFIX:== BY ==WS-IN1==.

       01  WS-IN1-ORDER.
           05  WS-IN1-LAST-DEPT-ID  PIC 9(004) VALUE 0.
           05  WS-IN1-HAS-LAST      PIC X(001) VALUE "N".

       PROCEDURE DIVISION.
           PERFORM INITIALIZE-PROCESS
           PERFORM MAIN-PROCESS
           PERFORM TERMINATE-PROCESS
           STOP RUN.

       INITIALIZE-PROCESS.
           ACCEPT WS-ARG-COUNT FROM ARGUMENT-NUMBER
           IF WS-ARG-COUNT NOT = 3
               DISPLAY "Usage: write_dept_summary_db DB_FILE YYYYMM"
                       " INPUT_FILE"
               MOVE 1 TO RETURN-CODE
               STOP RUN
           END-IF
           ACCEPT WS-DB-PATH-ARG FROM ARGUMENT-VALUE
           ACCEPT WS-RUN-MONTH FROM ARGUMENT-VALUE
           ACCEPT WS-IN1-FILE-PATH FROM ARGUMENT-VALUE
           IF WS-DB-PATH-ARG = SPACES OR
              WS-IN1-FILE-PATH = SPACES OR
              FUNCTION LENGTH(FUNCTION TRIM(WS-RUN-MONTH)) NOT = 6 OR
              WS-RUN-MONTH IS NOT NUMERIC OR
              WS-RUN-MONTH(1:4) = "0000" OR
              WS-RUN-MONTH(5:2) < "01" OR
              WS-RUN-MONTH(5:2) > "12" OR
              WS-DB-PATH-ARG = WS-IN1-FILE-PATH
               DISPLAY "ERROR: Invalid arguments or YYYYMM month."
               MOVE 1 TO RETURN-CODE
               STOP RUN
           END-IF
           PERFORM OPEN-IN1-FILE
           PERFORM OPEN-DATABASE
           PERFORM CREATE-SUMMARY-TABLE
           MOVE "BEGIN IMMEDIATE;" TO WS-SQL
           PERFORM EXECUTE-SQL
           MOVE "Y" TO WS-TRANSACTION-OPEN
           MOVE SPACES TO WS-SQL
           STRING "DELETE FROM department_summaries WHERE run_month='"
                      DELIMITED BY SIZE
                  WS-RUN-MONTH DELIMITED BY SIZE
                  "';" DELIMITED BY SIZE
             INTO WS-SQL
           END-STRING
           PERFORM EXECUTE-SQL.

       TERMINATE-PROCESS.
           MOVE "COMMIT;" TO WS-SQL
           PERFORM EXECUTE-SQL
           MOVE "N" TO WS-TRANSACTION-OPEN
           PERFORM CLOSE-IN1-FILE
           CALL STATIC "sqlite_close" USING WS-DATABASE
           IF NOT WS-SQLITE-OK
               PERFORM SQLITE-FAILURE
           END-IF
           DISPLAY "SUCCESS: Department summaries saved to SQLite."
           DISPLAY "-------------------------"
           DISPLAY "INPUT1 READ COUNT: " WS-IN1-COUNT
           DISPLAY "-------------------------".

       MAIN-PROCESS.
           PERFORM READ-IN1-FILE
           PERFORM UNTIL WS-IN1-FILE-EOF
               MOVE IN1-REC TO WS-IN1-DEPT
               PERFORM VALIDATE-INPUT-RECORD
               PERFORM INSERT-SUMMARY
               PERFORM READ-IN1-FILE
           END-PERFORM.

       VALIDATE-INPUT-RECORD.
           IF WS-IN1-DEPT-ID IS NOT NUMERIC OR
              WS-IN1-DEPT-MANAGER-ID IS NOT NUMERIC OR
              WS-IN1-DEPT-MEMBER-COUNT IS NOT NUMERIC
               DISPLAY "ERROR: Invalid department summary at record "
                       WS-IN1-COUNT "."
               MOVE "DATA" TO WS-FAILURE-TYPE
               PERFORM ROLLBACK-AND-FAIL
           END-IF
           IF WS-IN1-HAS-LAST = "Y" AND
              WS-IN1-DEPT-ID <= WS-IN1-LAST-DEPT-ID
               DISPLAY "ERROR: Summary input must be ordered by"
                       " unique department ID."
               MOVE "DATA" TO WS-FAILURE-TYPE
               PERFORM ROLLBACK-AND-FAIL
           END-IF
           MOVE WS-IN1-DEPT-ID TO WS-IN1-LAST-DEPT-ID
           MOVE "Y" TO WS-IN1-HAS-LAST.

       INSERT-SUMMARY.
           MOVE SPACES TO WS-SQL
           MOVE 1 TO WS-SQL-POS
           STRING
               "INSERT INTO department_summaries"
               " (run_month, dept_id, dept_name, manager_id,"
                   DELIMITED BY SIZE
               " manager_name, member_count) VALUES ('"
                   DELIMITED BY SIZE
               WS-RUN-MONTH DELIMITED BY SIZE
               "'," DELIMITED BY SIZE
               WS-IN1-DEPT-ID DELIMITED BY SIZE
               "," DELIMITED BY SIZE
               INTO WS-SQL WITH POINTER WS-SQL-POS
           END-STRING
           MOVE WS-IN1-DEPT-NAME TO WS-NAME-TO-QUOTE
           PERFORM APPEND-QUOTED-NAME
           STRING "," DELIMITED BY SIZE
               WS-IN1-DEPT-MANAGER-ID DELIMITED BY SIZE
               "," DELIMITED BY SIZE
               INTO WS-SQL WITH POINTER WS-SQL-POS
           END-STRING
           MOVE WS-IN1-DEPT-MANAGER-NAME TO WS-NAME-TO-QUOTE
           PERFORM APPEND-QUOTED-NAME
           STRING "," DELIMITED BY SIZE
               WS-IN1-DEPT-MEMBER-COUNT DELIMITED BY SIZE
               ") ON CONFLICT(run_month, dept_id) DO UPDATE SET "
                   DELIMITED BY SIZE
               "dept_name=excluded.dept_name,"
                   DELIMITED BY SIZE
               "manager_id=excluded.manager_id,"
                   DELIMITED BY SIZE
               "manager_name=excluded.manager_name,"
                   DELIMITED BY SIZE
               "member_count=excluded.member_count;" DELIMITED BY SIZE
               INTO WS-SQL WITH POINTER WS-SQL-POS
           END-STRING
           PERFORM EXECUTE-SQL.

       APPEND-QUOTED-NAME.
           COMPUTE WS-NAME-LENGTH =
               FUNCTION LENGTH(FUNCTION TRIM(WS-NAME-TO-QUOTE))
           STRING "'" INTO WS-SQL WITH POINTER WS-SQL-POS
           END-STRING
           PERFORM VARYING WS-NAME-POS FROM 1 BY 1
               UNTIL WS-NAME-POS > WS-NAME-LENGTH
               IF WS-NAME-TO-QUOTE(WS-NAME-POS:1) = "'"
                   STRING "''" INTO WS-SQL WITH POINTER WS-SQL-POS
                   END-STRING
               ELSE
                   STRING WS-NAME-TO-QUOTE(WS-NAME-POS:1)
                       INTO WS-SQL WITH POINTER WS-SQL-POS
                   END-STRING
               END-IF
           END-PERFORM
           STRING "'" INTO WS-SQL WITH POINTER WS-SQL-POS
           END-STRING.

       OPEN-DATABASE.
           MOVE FUNCTION TRIM(WS-DB-PATH-ARG) TO WS-DB-PATH
           CALL STATIC "sqlite_open" USING WS-DATABASE
           IF NOT WS-SQLITE-OK
               DISPLAY "ERROR: SQLite open failed ("
                       WS-SQLITE-RESULT ")."
               MOVE 1 TO RETURN-CODE
               STOP RUN
           END-IF.

       CREATE-SUMMARY-TABLE.
           CALL STATIC "create_dept_summary_table" USING WS-DATABASE
           IF NOT WS-SQLITE-OK
               PERFORM SQLITE-FAILURE
           END-IF.

       EXECUTE-SQL.
           CALL STATIC "sqlite_exec" USING WS-DATABASE WS-SQL
           IF NOT WS-SQLITE-OK
               IF WS-TRANSACTION-OPEN = "Y"
                   MOVE "SQL" TO WS-FAILURE-TYPE
                   PERFORM ROLLBACK-AND-FAIL
               ELSE
                   PERFORM SQLITE-FAILURE
               END-IF
           END-IF.

       ROLLBACK-AND-FAIL.
           IF WS-FAILURE-TYPE = "SQL"
               MOVE WS-SQLITE-RESULT TO WS-SQLITE-ERROR-CODE
           END-IF
           MOVE "ROLLBACK;" TO WS-SQL
           CALL STATIC "sqlite_exec" USING WS-DATABASE WS-SQL
           IF WS-SQLITE-OK
               SET WS-ROLLBACK-OK TO TRUE
           ELSE
               DISPLAY "ERROR: SQLite rollback failed ("
                       WS-SQLITE-RESULT ")."
           END-IF
           PERFORM CLOSE-IN1-FILE
           CALL STATIC "sqlite_close" USING WS-DATABASE
           IF NOT WS-SQLITE-OK
               DISPLAY "ERROR: SQLite close failed ("
                       WS-SQLITE-RESULT ")."
           END-IF
           IF WS-FAILURE-TYPE = "SQL"
               DISPLAY "ERROR: SQLite statement failed ("
                       WS-SQLITE-ERROR-CODE ")."
           END-IF
           IF WS-ROLLBACK-OK
               DISPLAY "ERROR: Department summary update rolled back."
           ELSE
               DISPLAY "ERROR: Department summary update failed."
           END-IF
           MOVE 1 TO RETURN-CODE
           STOP RUN.

       SQLITE-FAILURE.
           DISPLAY "ERROR: SQLite operation failed ("
                   WS-SQLITE-RESULT ")."
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

       COPY file_io_error_proc.
