       IDENTIFICATION DIVISION.
       PROGRAM-ID. create_dept_summary_table.

       DATA DIVISION.
       WORKING-STORAGE SECTION.
       01  WS-SQL                  PIC X(512).

       LINKAGE SECTION.
       01  LK-SQLITE.
       COPY sqlite.

       PROCEDURE DIVISION USING LK-SQLITE.
           MOVE SPACES TO WS-SQL
           STRING
               "CREATE TABLE IF NOT EXISTS department_summaries ("
                   DELIMITED BY SIZE
               "run_month TEXT NOT NULL," DELIMITED BY SIZE
               "dept_id INTEGER NOT NULL," DELIMITED BY SIZE
               "dept_name TEXT NOT NULL," DELIMITED BY SIZE
               "manager_id INTEGER NOT NULL," DELIMITED BY SIZE
               "manager_name TEXT NOT NULL," DELIMITED BY SIZE
               "member_count INTEGER NOT NULL,"
               "PRIMARY KEY (run_month, dept_id));"
                   DELIMITED BY SIZE
             INTO WS-SQL
           END-STRING
           CALL STATIC "sqlite_exec" USING LK-SQLITE WS-SQL
           GOBACK.
       END PROGRAM create_dept_summary_table.
