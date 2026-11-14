      * --------------------------------------
      * Employee record with the month of its salary. (length = 48)
      * --------------------------------------
       01  :PREFIX:-EMP-SALARY-REC.
       COPY emp_rec
           REPLACING ==:PREFIX:== BY ==:EMP-PREFIX:==.
           03  :PREFIX:-EMP-SALARY-MONTH PIC 9(006).
