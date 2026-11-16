       IDENTIFICATION DIVISION.
       PROGRAM-ID. sqlite_close.

       DATA DIVISION.
       LINKAGE SECTION.
       01  LK-SQLITE.
       COPY sqlite.

       PROCEDURE DIVISION USING LK-SQLITE.
           CALL STATIC "sqlite3_close"
               USING BY VALUE WS-DB-HANDLE
               RETURNING WS-SQLITE-RESULT
           IF WS-SQLITE-RESULT = 0
               SET WS-DB-HANDLE TO NULL
           END-IF
           CALL STATIC "sqlite_set_status" USING LK-SQLITE
           GOBACK.
       END PROGRAM sqlite_close.
