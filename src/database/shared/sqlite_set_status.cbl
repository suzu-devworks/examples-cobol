       IDENTIFICATION DIVISION.
       PROGRAM-ID. sqlite_set_status.

       DATA DIVISION.
       LINKAGE SECTION.
       01  LK-SQLITE.
       COPY sqlite.

       PROCEDURE DIVISION USING LK-SQLITE.
           EVALUATE WS-SQLITE-RESULT
               WHEN 0
                   SET WS-SQLITE-OK TO TRUE
               WHEN 100
                   SET WS-SQLITE-ROW TO TRUE
               WHEN 101
                   SET WS-SQLITE-DONE TO TRUE
               WHEN OTHER
                   SET WS-SQLITE-ERROR TO TRUE
           END-EVALUATE
           GOBACK.
       END PROGRAM sqlite_set_status.
