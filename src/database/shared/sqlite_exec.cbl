       IDENTIFICATION DIVISION.
       PROGRAM-ID. sqlite_exec.

       DATA DIVISION.
       LINKAGE SECTION.
       01  LK-SQLITE.
       COPY sqlite.
       01  LK-SQL                  PIC X ANY LENGTH.

       PROCEDURE DIVISION USING LK-SQLITE LK-SQL.
           IF FUNCTION LENGTH(FUNCTION TRIM(LK-SQL TRAILING))
                   >= LENGTH OF LK-SQL OR
              FUNCTION LENGTH(FUNCTION TRIM(LK-SQL TRAILING)) > 65534
               MOVE 18 TO WS-SQLITE-RESULT
               CALL STATIC "sqlite_set_status" USING LK-SQLITE
               GOBACK
           END-IF
           COMPUTE WS-SQL-LENGTH =
               FUNCTION LENGTH(FUNCTION TRIM(LK-SQL TRAILING)) + 1
           MOVE X"00" TO LK-SQL(WS-SQL-LENGTH:1)
           CALL STATIC "sqlite3_exec"
               USING BY VALUE WS-DB-HANDLE
                     BY REFERENCE LK-SQL
                     BY VALUE WS-NULL-POINTER
                     BY VALUE WS-NULL-POINTER
                     BY VALUE WS-NULL-POINTER
               RETURNING WS-SQLITE-RESULT
           CALL STATIC "sqlite_set_status" USING LK-SQLITE
           GOBACK.
       END PROGRAM sqlite_exec.
