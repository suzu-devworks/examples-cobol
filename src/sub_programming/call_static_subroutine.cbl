       IDENTIFICATION DIVISION.
       PROGRAM-ID. call_static_subroutine.

       PROCEDURE DIVISION.
           DISPLAY "RUNNING MAIN PROGRAM"
           CALL "subroutine"
           STOP RUN.
       END PROGRAM call_static_subroutine.
