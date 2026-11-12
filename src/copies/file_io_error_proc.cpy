       FILE-IO-ERROR.
           DISPLAY "ERROR: File I/O failed for "
                   FUNCTION TRIM(WS-IO-ERROR-FILE)
                   " (status " WS-IO-ERROR-CODE ")."
           MOVE 2 TO RETURN-CODE
           STOP RUN.
