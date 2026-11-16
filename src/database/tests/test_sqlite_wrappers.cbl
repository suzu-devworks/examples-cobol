       IDENTIFICATION DIVISION.
       PROGRAM-ID. test_sqlite_wrappers.

       DATA DIVISION.
       WORKING-STORAGE SECTION.
       01  WS-DATABASE.
       COPY sqlite.
       01  WS-SQL                  PIC X(64).
       01  WS-SMALL-SQL            PIC X(4).
       01  WS-LARGE-SQL            PIC X(65536).
       01  WS-CASE                 PIC X(40).
       01  WS-COLUMN-TEXT          PIC X(10) BASED.

       PROCEDURE DIVISION.
           MOVE "oversized database path" TO WS-CASE
           MOVE ALL "A" TO WS-DB-PATH
           CALL STATIC "sqlite_open" USING WS-DATABASE
           IF NOT WS-SQLITE-ERROR OR WS-SQLITE-RESULT NOT = 18
               PERFORM TEST-FAILED
           END-IF

           MOVE "open in-memory database" TO WS-CASE
           MOVE ":memory:" TO WS-DB-PATH
           CALL STATIC "sqlite_open" USING WS-DATABASE
           IF NOT WS-SQLITE-OK OR WS-SQLITE-RESULT NOT = 0 OR
              WS-DB-HANDLE = NULL
               PERFORM TEST-FAILED
           END-IF

           MOVE "valid SQL" TO WS-CASE
           MOVE "SELECT 1;" TO WS-SQL
           CALL STATIC "sqlite_exec" USING WS-DATABASE WS-SQL
           IF NOT WS-SQLITE-OK OR WS-SQLITE-RESULT NOT = 0
               PERFORM TEST-FAILED
           END-IF

           MOVE "invalid SQL" TO WS-CASE
           MOVE "INVALID SQL" TO WS-SQL
           CALL STATIC "sqlite_exec" USING WS-DATABASE WS-SQL
           IF NOT WS-SQLITE-ERROR OR WS-SQLITE-RESULT = 0
               PERFORM TEST-FAILED
           END-IF

           MOVE "SQL fits before terminator" TO WS-CASE
           MOVE ";--" TO WS-SMALL-SQL
           CALL STATIC "sqlite_exec" USING WS-DATABASE WS-SMALL-SQL
           IF NOT WS-SQLITE-OK OR WS-SQLITE-RESULT NOT = 0 OR
              WS-SMALL-SQL(4:1) NOT = X"00"
               PERFORM TEST-FAILED
           END-IF

           MOVE "full SQL buffer" TO WS-CASE
           MOVE ALL "A" TO WS-SMALL-SQL
           CALL STATIC "sqlite_exec" USING WS-DATABASE WS-SMALL-SQL
           IF NOT WS-SQLITE-ERROR OR WS-SQLITE-RESULT NOT = 18 OR
              WS-SMALL-SQL NOT = "AAAA"
               PERFORM TEST-FAILED
           END-IF

           MOVE "large SQL buffer" TO WS-CASE
           MOVE ALL "A" TO WS-LARGE-SQL
           CALL STATIC "sqlite_exec" USING WS-DATABASE WS-LARGE-SQL
           IF NOT WS-SQLITE-ERROR OR WS-SQLITE-RESULT NOT = 18
               PERFORM TEST-FAILED
           END-IF

           MOVE "invalid statement" TO WS-CASE
           MOVE "INVALID SQL" TO WS-SQL
           CALL STATIC "sqlite_prepare" USING WS-DATABASE WS-SQL
           IF NOT WS-SQLITE-ERROR OR WS-SQLITE-RESULT = 0 OR
              WS-STMT-HANDLE NOT = NULL
               PERFORM TEST-FAILED
           END-IF

           MOVE "full statement buffer" TO WS-CASE
           MOVE ALL "A" TO WS-SMALL-SQL
           CALL STATIC "sqlite_prepare" USING WS-DATABASE WS-SMALL-SQL
           IF NOT WS-SQLITE-ERROR OR WS-SQLITE-RESULT NOT = 18 OR
              WS-SMALL-SQL NOT = "AAAA"
               PERFORM TEST-FAILED
           END-IF

           MOVE "oversized statement" TO WS-CASE
           MOVE ALL "A" TO WS-LARGE-SQL
           MOVE SPACE TO WS-LARGE-SQL(65536:1)
           CALL STATIC "sqlite_prepare" USING WS-DATABASE WS-LARGE-SQL
           IF NOT WS-SQLITE-ERROR OR WS-SQLITE-RESULT NOT = 18
               PERFORM TEST-FAILED
           END-IF

           MOVE "maximum statement length" TO WS-CASE
           MOVE SPACES TO WS-LARGE-SQL
           MOVE "SELECT 1;--" TO WS-LARGE-SQL
           MOVE ALL "A" TO WS-LARGE-SQL(12:65523)
           CALL STATIC "sqlite_prepare" USING WS-DATABASE WS-LARGE-SQL
           IF NOT WS-SQLITE-OK OR WS-SQLITE-RESULT NOT = 0 OR
              WS-STMT-HANDLE = NULL OR
              WS-LARGE-SQL(65535:1) NOT = X"00"
               PERFORM TEST-FAILED
           END-IF
           CALL STATIC "sqlite_finalize" USING WS-DATABASE
           IF NOT WS-SQLITE-OK OR WS-SQLITE-RESULT NOT = 0 OR
              WS-STMT-HANDLE NOT = NULL
               PERFORM TEST-FAILED
           END-IF

           MOVE "prepare statement" TO WS-CASE
           MOVE "SELECT 42,'Hello','';" TO WS-SQL
           CALL STATIC "sqlite_prepare" USING WS-DATABASE WS-SQL
           IF NOT WS-SQLITE-OK OR WS-SQLITE-RESULT NOT = 0 OR
              WS-STMT-HANDLE = NULL
               PERFORM TEST-FAILED
           END-IF

           MOVE "step to row" TO WS-CASE
           CALL STATIC "sqlite_step" USING WS-DATABASE
           IF NOT WS-SQLITE-ROW OR WS-SQLITE-RESULT NOT = 100
               PERFORM TEST-FAILED
           END-IF

           MOVE "read integer column" TO WS-CASE
           MOVE 0 TO WS-COLUMN-INDEX
           CALL STATIC "sqlite_column_int" USING WS-DATABASE
           IF NOT WS-SQLITE-ROW OR WS-SQLITE-RESULT NOT = 100 OR
              WS-COLUMN-VALUE NOT = 42
               PERFORM TEST-FAILED
           END-IF

           MOVE "read text column" TO WS-CASE
           MOVE 1 TO WS-COLUMN-INDEX
           CALL STATIC "sqlite_column_text" USING WS-DATABASE
           IF NOT WS-SQLITE-ROW OR WS-SQLITE-RESULT NOT = 100 OR
              WS-COLUMN-LENGTH NOT = 5 OR WS-TEXT-POINTER = NULL
               PERFORM TEST-FAILED
           END-IF
           SET ADDRESS OF WS-COLUMN-TEXT TO WS-TEXT-POINTER
           IF WS-COLUMN-TEXT(1:5) NOT = "Hello"
               PERFORM TEST-FAILED
           END-IF

           MOVE "read empty text column" TO WS-CASE
           MOVE 2 TO WS-COLUMN-INDEX
           CALL STATIC "sqlite_column_text" USING WS-DATABASE
           IF WS-COLUMN-LENGTH NOT = 0 OR WS-TEXT-POINTER = NULL
               PERFORM TEST-FAILED
           END-IF

           MOVE "step to end" TO WS-CASE
           CALL STATIC "sqlite_step" USING WS-DATABASE
           IF NOT WS-SQLITE-DONE OR WS-SQLITE-RESULT NOT = 101
               PERFORM TEST-FAILED
           END-IF

           MOVE "close with active statement" TO WS-CASE
           CALL STATIC "sqlite_close" USING WS-DATABASE
           IF NOT WS-SQLITE-ERROR OR WS-SQLITE-RESULT NOT = 5 OR
              WS-DB-HANDLE = NULL
               PERFORM TEST-FAILED
           END-IF

           MOVE "finalize statement" TO WS-CASE
           CALL STATIC "sqlite_finalize" USING WS-DATABASE
           IF NOT WS-SQLITE-OK OR WS-SQLITE-RESULT NOT = 0 OR
              WS-STMT-HANDLE NOT = NULL
               PERFORM TEST-FAILED
           END-IF

           MOVE "prepare failing step" TO WS-CASE
           MOVE "SELECT abs(-9223372036854775808);" TO WS-SQL
           CALL STATIC "sqlite_prepare" USING WS-DATABASE WS-SQL
           IF NOT WS-SQLITE-OK OR WS-STMT-HANDLE = NULL
               PERFORM TEST-FAILED
           END-IF

           MOVE "step error" TO WS-CASE
           CALL STATIC "sqlite_step" USING WS-DATABASE
           IF NOT WS-SQLITE-ERROR OR WS-SQLITE-RESULT = 0
               PERFORM TEST-FAILED
           END-IF

           MOVE "finalize after step error" TO WS-CASE
           CALL STATIC "sqlite_finalize" USING WS-DATABASE
           IF NOT WS-SQLITE-ERROR OR WS-SQLITE-RESULT = 0 OR
              WS-STMT-HANDLE NOT = NULL
               PERFORM TEST-FAILED
           END-IF

           MOVE "close database" TO WS-CASE
           CALL STATIC "sqlite_close" USING WS-DATABASE
           IF NOT WS-SQLITE-OK OR WS-SQLITE-RESULT NOT = 0 OR
              WS-DB-HANDLE NOT = NULL
               PERFORM TEST-FAILED
           END-IF

           DISPLAY "SUCCESS: SQLite wrapper tests passed."
           MOVE 0 TO RETURN-CODE
           STOP RUN.

       TEST-FAILED.
           DISPLAY "ERROR: SQLite wrapper test failed: "
                   FUNCTION TRIM(WS-CASE)
                   " (result " WS-SQLITE-RESULT ")."
           MOVE 1 TO RETURN-CODE
           STOP RUN.
