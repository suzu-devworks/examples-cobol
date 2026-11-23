      * --------------------------------------
      * The structure of an employee record. ( length = 42 )
      * --------------------------------------
       03  :PREFIX:-EMP-REC.
           05  :PREFIX:-EMP-ID-RAW.
               10  :PREFIX:-EMP-ID         PIC 9(004).
           05  :PREFIX:-EMP-NAME           PIC X(010).
           05  :PREFIX:-EMP-DEPT-ID-RAW.
               10  :PREFIX:-EMP-DEPT-ID    PIC 9(004).
           05  :PREFIX:-EMP-DEPT-NAME      PIC X(010).
           05  :PREFIX:-EMP-JOIN-DATE-RAW.
               10  :PREFIX:-EMP-JOIN-DATE  PIC 9(008).
           05  :PREFIX:-EMP-SALARY-RAW.
               10  :PREFIX:-EMP-SALARY     PIC 9(006).
