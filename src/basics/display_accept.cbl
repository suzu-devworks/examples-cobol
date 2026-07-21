       IDENTIFICATION DIVISION.
       PROGRAM-ID. display_accept.

       DATA DIVISION.
       WORKING-STORAGE SECTION.
       01  INPUT-RECORD.
         03  IN-DATA-STR PIC X(30).
         03  IN-DATA-NUM-X.
           05  IN-DATA-NUM PIC 9(3).

       PROCEDURE DIVISION.
           DISPLAY "Please enter a message: " WITH NO ADVANCING.
           ACCEPT IN-DATA-STR FROM CONSOLE.
           DISPLAY "You entered: " IN-DATA-STR.
           DISPLAY SPACE.

           DISPLAY "PLEASE enter an integer: " WITH NO ADVANCING.
           ACCEPT IN-DATA-NUM-X FROM CONSOLE.
           IF IN-DATA-NUM-X IS NUMERIC

               IF IN-DATA-NUM < 100
                   DISPLAY "You entered a number less than 100: "
                       IN-DATA-NUM
               ELSE
                   DISPLAY "You entered a number greater than or equal t
      -                "o 100: " IN-DATA-NUM
               END-IF

           ELSE
               DISPLAY "You did not enter a valid integer."
           END-IF.
           DISPLAY SPACE.
           STOP RUN.
