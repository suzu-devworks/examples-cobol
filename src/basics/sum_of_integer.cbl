       IDENTIFICATION DIVISION.
       PROGRAM-ID. sum_of_integer.

       DATA DIVISION.
       WORKING-STORAGE SECTION.
       01  num  BINARY-LONG.
       01  i   BINARY-LONG.
       01  summary BINARY-LONG.
       01  display-summary PIC ZZZ,ZZZ,ZZ9 VALUE SPACE.

       PROCEDURE DIVISION.
           DISPLAY "Please enter an integer 9(9): " WITH NO ADVANCING
           ACCEPT num FROM CONSOLE

           PERFORM VARYING i FROM 1 BY 1 UNTIL i > num
               ADD i TO summary
           END-PERFORM

           MOVE summary TO display-summary
           DISPLAY "The sum is " display-summary "."
           DISPLAY SPACE
           STOP RUN.
