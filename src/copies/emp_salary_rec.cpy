      * --------------------------------------
      * Employee record with the month of its salary. (length = 48)
      * --------------------------------------
       03  :PREFIX:-EMP-SALARY-REC.
       COPY emp_rec
           REPLACING ==03== BY ==05==
                     ==05== BY ==10==.
           05  :PREFIX:-EMP-SALARY-MONTH PIC 9(006).
