       IDENTIFICATION DIVISION.
       PROGRAM-ID. call_static_function.

       ENVIRONMENT DIVISION.
       CONFIGURATION SECTION.
       REPOSITORY.
           FUNCTION FUNC AS "user_defined_function".

       DATA DIVISION.
       WORKING-STORAGE SECTION.
       01  FUNC-RET        PIC 9(4).

       PROCEDURE DIVISION.
           DISPLAY "RUNNING MAIN PROGRAM"
           COMPUTE FUNC-RET = FUNCTION FUNC
           DISPLAY "FUNCTION RETURN VALUE: " FUNC-RET
           STOP RUN.
       END PROGRAM call_static_function.
