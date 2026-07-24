       IDENTIFICATION DIVISION.
       FUNCTION-ID. user_defined_function.
       DATA DIVISION.
       LINKAGE SECTION.
       01  LS-RESULT              PIC 9(4).
       PROCEDURE DIVISION RETURNING LS-RESULT.
           DISPLAY "RUNNING user defined function"
           MOVE 42 TO LS-RESULT
           GOBACK.
       END FUNCTION user_defined_function.
