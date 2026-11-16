       IDENTIFICATION DIVISION.
       PROGRAM-ID. sqlite_step.

       DATA DIVISION.
       LINKAGE SECTION.
       01  LK-SQLITE.
       COPY sqlite.

       PROCEDURE DIVISION USING LK-SQLITE.
           CALL STATIC "sqlite3_step"
               USING BY VALUE WS-STMT-HANDLE
               RETURNING WS-SQLITE-RESULT
           CALL STATIC "sqlite_set_status" USING LK-SQLITE
           GOBACK.

       ENTRY "sqlite_column_int" USING LK-SQLITE.
           CALL STATIC "sqlite3_column_int"
               USING BY VALUE WS-STMT-HANDLE
                     BY VALUE WS-COLUMN-INDEX
               RETURNING WS-COLUMN-VALUE
           GOBACK.

       ENTRY "sqlite_column_text" USING LK-SQLITE.
           CALL STATIC "sqlite3_column_text"
               USING BY VALUE WS-STMT-HANDLE
                     BY VALUE WS-COLUMN-INDEX
               RETURNING WS-TEXT-POINTER
           CALL STATIC "sqlite3_column_bytes"
               USING BY VALUE WS-STMT-HANDLE
                     BY VALUE WS-COLUMN-INDEX
               RETURNING WS-COLUMN-LENGTH
           GOBACK.

       ENTRY "sqlite_finalize" USING LK-SQLITE.
           CALL STATIC "sqlite3_finalize"
               USING BY VALUE WS-STMT-HANDLE
               RETURNING WS-SQLITE-RESULT
           SET WS-STMT-HANDLE TO NULL
           CALL STATIC "sqlite_set_status" USING LK-SQLITE
           GOBACK.
       END PROGRAM sqlite_step.
