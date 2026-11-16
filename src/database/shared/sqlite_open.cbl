       IDENTIFICATION DIVISION.
       PROGRAM-ID. sqlite_open.

       DATA DIVISION.
       LINKAGE SECTION.
       01  LK-SQLITE.
       COPY sqlite.

       PROCEDURE DIVISION USING LK-SQLITE.
           COMPUTE WS-DB-PATH-LENGTH =
               FUNCTION LENGTH(FUNCTION TRIM(WS-DB-PATH TRAILING)) + 1
           IF WS-DB-PATH-LENGTH > LENGTH OF WS-DB-PATH
               MOVE 18 TO WS-SQLITE-RESULT
               CALL STATIC "sqlite_set_status" USING LK-SQLITE
               GOBACK
           END-IF
           MOVE X"00" TO WS-DB-PATH(WS-DB-PATH-LENGTH:1)
           CALL STATIC "sqlite3_open"
               USING BY VALUE ADDRESS OF WS-DB-PATH
                     BY VALUE ADDRESS OF WS-DB-HANDLE
               RETURNING WS-SQLITE-RESULT
           CALL STATIC "sqlite_set_status" USING LK-SQLITE
           GOBACK.
       END PROGRAM sqlite_open.
