      * --------------------------------------
      * The structure of quick sort configuration.
      * --------------------------------------
       01  :PREFIX:-SORT-CONFIG.
           05  :PREFIX:-KEY-START          PIC 9(3).
           05  :PREFIX:-KEY-LEN            PIC 9(3).
       01  :PREFIX:-REC-CNT                PIC 9(5).
       01  :PREFIX:-MEM-TABLE.
           05  :PREFIX:-REC OCCURS 10000 TIMES.
               10  :PREFIX:-REC-DATA       PIC X(100).
