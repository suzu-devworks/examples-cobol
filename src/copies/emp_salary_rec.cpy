      * --------------------------------------
      * Employee record with the month of its salary. (length = 48)
      * --------------------------------------
       COPY emp_rec
           REPLACING TRAILING ==-EMP-REC== BY ==-EMP-SALARY-REC==.
           05  :PREFIX:-EMP-SALARY-MONTH PIC 9(006).
