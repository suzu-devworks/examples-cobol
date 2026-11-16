      * --------------------------------------
      * The structure of quick sort configuration.
      * --------------------------------------
       03  :PREFIX:-QUICK-SORT.
           05  :PREFIX:-SORT-CONFIG.
               10  :PREFIX:-KEY-START      PIC 9(3).
               10  :PREFIX:-KEY-LEN        PIC 9(3).
           05  :PREFIX:-REC-CNT            PIC 9(5).
           05  :PREFIX:-MEM-TABLE.
               10  :PREFIX:-REC OCCURS 10000 TIMES.
                   15  :PREFIX:-REC-DATA   PIC X(100).
