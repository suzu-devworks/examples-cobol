       IDENTIFICATION DIVISION.
       PROGRAM-ID. read_dept_summary_db.

       ENVIRONMENT DIVISION.
       INPUT-OUTPUT SECTION.
       FILE-CONTROL.
           SELECT OUT1-FILE ASSIGN TO WS-OUT1-FILE-PATH
               ORGANIZATION IS LINE SEQUENTIAL
               FILE STATUS IS WS-OUT1-FILE-STATUS.

       DATA DIVISION.
       FILE SECTION.
       FD  OUT1-FILE.
       01  OUT1-REC                 PIC X(032).

       WORKING-STORAGE SECTION.
       01  WS-ARGS.
           05  WS-ARG-COUNT        PIC 9(002) VALUE 0.
           05  WS-DB-PATH-ARG      PIC X(1024) VALUE SPACES.
           05  WS-RUN-MONTH        PIC X(006) VALUE SPACES.
           05  WS-OUT1-FILE-PATH   PIC X(1024) VALUE SPACES.
       01  WS-COUNTERS.
           05  WS-OUT1-COUNT       PIC 9(006) VALUE 0.

       01  WS-FILE-STATUS.
       COPY file_statuses
           REPLACING ==:PREFIX:== BY ==WS-OUT1==.

       01  WS-IO-ERROR.
       COPY file_io_error.

       01  WS-DATABASE.
       COPY sqlite.
       01  WS-DATABASE-WORK.
           05  WS-COLUMN-DISPLAY   PIC 9(009) VALUE 0.
       01  WS-SQL                   PIC X(1024) VALUE SPACES.

       01  WS-OUT1-DEPT.
       COPY dept_rec REPLACING ==:PREFIX:== BY ==WS-OUT1==.

       01  WS-COLUMN-TEXT         PIC X(010) BASED.

       PROCEDURE DIVISION.
           PERFORM INITIALIZE-PROCESS
           PERFORM MAIN-PROCESS
           PERFORM TERMINATE-PROCESS
           STOP RUN.

       INITIALIZE-PROCESS.
           ACCEPT WS-ARG-COUNT FROM ARGUMENT-NUMBER
           IF WS-ARG-COUNT NOT = 3
               DISPLAY "Usage: read_dept_summary_db DB_FILE YYYYMM"
                       " OUTPUT_FILE"
               MOVE 1 TO RETURN-CODE
               STOP RUN
           END-IF
           ACCEPT WS-DB-PATH-ARG FROM ARGUMENT-VALUE
           ACCEPT WS-RUN-MONTH FROM ARGUMENT-VALUE
           ACCEPT WS-OUT1-FILE-PATH FROM ARGUMENT-VALUE
           IF WS-DB-PATH-ARG = SPACES OR
              WS-OUT1-FILE-PATH = SPACES OR
              FUNCTION LENGTH(FUNCTION TRIM(WS-RUN-MONTH)) NOT = 6 OR
              WS-RUN-MONTH IS NOT NUMERIC OR
              WS-RUN-MONTH(1:4) = "0000" OR
              WS-RUN-MONTH(5:2) < "01" OR
              WS-RUN-MONTH(5:2) > "12" OR
              WS-DB-PATH-ARG = WS-OUT1-FILE-PATH
               DISPLAY "ERROR: Invalid arguments or YYYYMM month."
               MOVE 1 TO RETURN-CODE
               STOP RUN
           END-IF

           PERFORM OPEN-DATABASE
           PERFORM CREATE-SUMMARY-TABLE
           PERFORM PREPARE-QUERY
           PERFORM OPEN-OUT1-FILE.

       TERMINATE-PROCESS.
           CALL STATIC "sqlite_finalize" USING WS-DATABASE
           IF NOT WS-SQLITE-OK
               PERFORM SQLITE-FAILURE
           END-IF
           CALL STATIC "sqlite_close" USING WS-DATABASE
           IF NOT WS-SQLITE-OK
               PERFORM SQLITE-FAILURE
           END-IF
           PERFORM CLOSE-OUT1-FILE
           DISPLAY "SUCCESS: Department summaries read from SQLite."
           DISPLAY "---------------------------"
           DISPLAY "OUTPUT1 WRITE COUNT: " WS-OUT1-COUNT
           DISPLAY "---------------------------".

       MAIN-PROCESS.
           PERFORM FETCH-NEXT-ROW
           PERFORM UNTIL WS-SQLITE-DONE
               PERFORM BUILD-DEPARTMENT-RECORD
               PERFORM WRITE-OUT1-FILE
               PERFORM FETCH-NEXT-ROW
           END-PERFORM.

       BUILD-DEPARTMENT-RECORD.
           INITIALIZE WS-OUT1-DEPT
           PERFORM GET-INTEGER-COLUMN
           IF WS-COLUMN-VALUE < 0 OR WS-COLUMN-VALUE > 9999
               PERFORM INVALID-DATABASE-ROW
           END-IF
           MOVE WS-COLUMN-VALUE TO WS-COLUMN-DISPLAY
           MOVE WS-COLUMN-DISPLAY(6:4) TO WS-OUT1-DEPT-ID

           PERFORM GET-TEXT-COLUMN
           IF WS-COLUMN-LENGTH > 10
               PERFORM INVALID-DATABASE-ROW
           END-IF
           IF WS-COLUMN-LENGTH > 0
               SET ADDRESS OF WS-COLUMN-TEXT TO WS-TEXT-POINTER
               MOVE WS-COLUMN-TEXT(1:WS-COLUMN-LENGTH)
                 TO WS-OUT1-DEPT-NAME(1:WS-COLUMN-LENGTH)
           END-IF

           PERFORM GET-INTEGER-COLUMN
           IF WS-COLUMN-VALUE < 0 OR WS-COLUMN-VALUE > 9999
               PERFORM INVALID-DATABASE-ROW
           END-IF
           MOVE WS-COLUMN-VALUE TO WS-COLUMN-DISPLAY
           MOVE WS-COLUMN-DISPLAY(6:4)
             TO WS-OUT1-DEPT-MANAGER-ID

           PERFORM GET-TEXT-COLUMN
           IF WS-COLUMN-LENGTH > 10
               PERFORM INVALID-DATABASE-ROW
           END-IF
           IF WS-COLUMN-LENGTH > 0
               SET ADDRESS OF WS-COLUMN-TEXT TO WS-TEXT-POINTER
               MOVE WS-COLUMN-TEXT(1:WS-COLUMN-LENGTH)
                 TO WS-OUT1-DEPT-MANAGER-NAME(1:WS-COLUMN-LENGTH)
           END-IF

           PERFORM GET-INTEGER-COLUMN
           IF WS-COLUMN-VALUE < 0 OR WS-COLUMN-VALUE > 9999
               PERFORM INVALID-DATABASE-ROW
           END-IF
           MOVE WS-COLUMN-VALUE TO WS-COLUMN-DISPLAY
           MOVE WS-COLUMN-DISPLAY(6:4)
             TO WS-OUT1-DEPT-MEMBER-COUNT.

       GET-INTEGER-COLUMN.
           CALL STATIC "sqlite_column_int" USING WS-DATABASE
           ADD 1 TO WS-COLUMN-INDEX.

       GET-TEXT-COLUMN.
           CALL STATIC "sqlite_column_text" USING WS-DATABASE
           ADD 1 TO WS-COLUMN-INDEX
           IF WS-COLUMN-LENGTH < 0 OR
              (WS-COLUMN-LENGTH > 0 AND WS-TEXT-POINTER = NULL)
               PERFORM INVALID-DATABASE-ROW
           END-IF.

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

       PREPARE-QUERY.
           MOVE SPACES TO WS-SQL
           STRING
               "SELECT dept_id, dept_name, manager_id, manager_name,"
                   DELIMITED BY SIZE
               " member_count FROM department_summaries"
                   DELIMITED BY SIZE
               " WHERE run_month='"
                   DELIMITED BY SIZE
               WS-RUN-MONTH DELIMITED BY SIZE
               "' ORDER BY dept_id;" DELIMITED BY SIZE
             INTO WS-SQL
           END-STRING
           CALL STATIC "sqlite_prepare" USING WS-DATABASE WS-SQL
           IF NOT WS-SQLITE-OK
               PERFORM SQLITE-FAILURE
           END-IF
           MOVE 0 TO WS-COLUMN-INDEX.

       FETCH-NEXT-ROW.
           CALL STATIC "sqlite_step" USING WS-DATABASE
           EVALUATE TRUE
               WHEN WS-SQLITE-ROW
                   MOVE 0 TO WS-COLUMN-INDEX
               WHEN WS-SQLITE-DONE
                   CONTINUE
               WHEN OTHER
                   PERFORM SQLITE-FAILURE
           END-EVALUATE.

       INVALID-DATABASE-ROW.
           DISPLAY "ERROR: Invalid department summary in SQLite."
           MOVE 1 TO RETURN-CODE
           STOP RUN.

       SQLITE-FAILURE.
           DISPLAY "ERROR: SQLite operation failed ("
                   WS-SQLITE-RESULT ")."
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
           WRITE OUT1-REC FROM WS-OUT1-DEPT
           IF NOT WS-OUT1-FILE-OK
               MOVE "OUT1-FILE" TO WS-IO-ERROR-FILE
               MOVE WS-OUT1-FILE-STATUS TO WS-IO-ERROR-CODE
               PERFORM FILE-IO-ERROR
           END-IF
           ADD 1 TO WS-OUT1-COUNT.

       COPY file_io_error_proc.
