       IDENTIFICATION DIVISION.
       PROGRAM-ID. quick_sort.

       DATA DIVISION.
       WORKING-STORAGE SECTION.
       01  WS-SORT-STACK.
           05  WS-STACK-MAX           PIC 9(4) VALUE 1000.
           05  WS-STACK-PTR           PIC 9(4) VALUE 0.
           05  WS-STACK-ITEM OCCURS 1000 TIMES.
               10  WS-STK-LOW         PIC 9(5).
               10  WS-STK-HIGH        PIC 9(5).

       01  WS-SORT-VARS.
           05  WS-L                   PIC 9(5).
           05  WS-H                   PIC 9(5).
           05  WS-I                   PIC 9(5).
           05  WS-J                   PIC 9(5).
           05  WS-PIVOT               PIC X(50).
           05  WS-MID                 PIC 9(5).

       01  WS-WK-REC.
           05  WS-WK-DATA             PIC X(100).

       LINKAGE SECTION.
       COPY "quick_sort.cpy" REPLACING ==:PREFIX:== BY ==LK==.

       PROCEDURE DIVISION USING LK-SORT-CONFIG LK-REC-CNT LK-MEM-TABLE.
           PERFORM QUICK-SORT-START
           GOBACK.

       QUICK-SORT-START.
           IF LK-REC-CNT < 2
               EXIT PARAGRAPH
           END-IF

           MOVE 0 TO WS-STACK-PTR

           *> Put the first range (from 1st item to all items) on the stack
           MOVE 1 TO WS-L
           MOVE LK-REC-CNT TO WS-H

           ADD 1 TO WS-STACK-PTR
           MOVE WS-L TO WS-STK-LOW(WS-STACK-PTR)
           MOVE WS-H TO WS-STK-HIGH(WS-STACK-PTR)

           PERFORM UNTIL WS-STACK-PTR = 0
               *> Get the next processing range from the stack
               MOVE WS-STK-LOW(WS-STACK-PTR)  TO WS-L
               MOVE WS-STK-HIGH(WS-STACK-PTR) TO WS-H
               SUBTRACT 1 FROM WS-STACK-PTR

               IF WS-L < WS-H
                   PERFORM PARTITION-PROCESS

                   IF WS-I < WS-H AND WS-STACK-PTR < WS-STACK-MAX
                       ADD 1 TO WS-STACK-PTR
                       MOVE WS-I TO WS-STK-LOW(WS-STACK-PTR)
                       MOVE WS-H TO WS-STK-HIGH(WS-STACK-PTR)
                   END-IF

                   IF WS-L < WS-J AND WS-STACK-PTR < WS-STACK-MAX
                       ADD 1 TO WS-STACK-PTR
                       MOVE WS-L TO WS-STK-LOW(WS-STACK-PTR)
                       MOVE WS-J TO WS-STK-HIGH(WS-STACK-PTR)
                   END-IF
               END-IF

           END-PERFORM.

       PARTITION-PROCESS.
           MOVE WS-L TO WS-I
           MOVE WS-H TO WS-J
           COMPUTE WS-MID = (WS-L + WS-H) / 2

           *> Dynamically cut out the pivot key and assign it (match the length)
           INITIALIZE WS-PIVOT
           MOVE LK-REC-DATA(WS-MID)(LK-KEY-START:LK-KEY-LEN)
               TO WS-PIVOT(1:LK-KEY-LEN)

           PERFORM UNTIL WS-I > WS-J
               *> Search for a key greater than or equal to the pivot from the left.
               PERFORM UNTIL
                   LK-REC-DATA(WS-I)(LK-KEY-START:LK-KEY-LEN) >=
                   WS-PIVOT(1:LK-KEY-LEN) OR WS-I >= WS-H
                       ADD 1 TO WS-I
               END-PERFORM

               *> Search for a key less than or equal to the pivot from the right.
               PERFORM UNTIL
                   LK-REC-DATA(WS-J)(LK-KEY-START:LK-KEY-LEN) <=
                   WS-PIVOT(1:LK-KEY-LEN) OR WS-J <= WS-L
                       SUBTRACT 1 FROM WS-J
               END-PERFORM

               IF WS-I < WS-J
                   *> swap the two records
                   MOVE LK-REC(WS-I) TO WS-WK-REC
                   MOVE LK-REC(WS-J) TO LK-REC(WS-I)
                   MOVE WS-WK-REC    TO LK-REC(WS-J)
                   ADD 1 TO WS-I
                   SUBTRACT 1 FROM WS-J
               ELSE
                   IF WS-I = WS-J
                       ADD 1 TO WS-I
                       SUBTRACT 1 FROM WS-J
                   END-IF
               END-IF
           END-PERFORM.

       END PROGRAM quick_sort.
