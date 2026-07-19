       IDENTIFICATION DIVISION.
       PROGRAM-ID. SUM_OF_INTEGER.

       DATA DIVISION.
       WORKING-STORAGE SECTION.
       01  num  BINARY-LONG.
       01  i   BINARY-LONG.
       01  summary BINARY-LONG.

       PROCEDURE DIVISION.
           DISPLAY "Please enter an integer 9(9): " WITH NO ADVANCING.
           ACCEPT num FROM CONSOLE.

           PERFORM VARYING i FROM 1 BY 1 UNTIL i > num
               ADD i TO summary
           END-PERFORM.

           DISPLAY "The sum is " summary.
           DISPLAY SPACE.
           STOP RUN.
