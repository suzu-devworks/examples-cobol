       IDENTIFICATION DIVISION.
       PROGRAM-ID. http_client.

       DATA DIVISION.
       WORKING-STORAGE SECTION.
      * Define API URL and send/receive buffer
       01  API-URL         PIC X(100) VALUE
           Z"https://jsonplaceholder.typicode.com/todos/1".
       01  RESPONSE-BUF    PIC X(1000).

       01  CURL-HANDLE     USAGE POINTER.
       01  API-RC          PIC S9(9) COMP-5.
       01  CURLOPT-URL     PIC S9(9) COMP-5 VALUE 10002.

       PROCEDURE DIVISION.
           DISPLAY "--- Start REST API call ---"

      * 1. Initialize libcurl (CALL curl_easy_init in C language)
           CALL "curl_easy_init" RETURNING CURL-HANDLE.

           IF CURL-HANDLE = NULL
               DISPLAY "Initialization failed"
               STOP RUN
           END-IF.

      * 2. Set URL (CALL curl_easy_setopt)
           CALL "curl_easy_setopt" USING BY VALUE CURL-HANDLE
                                         BY VALUE CURLOPT-URL
                                         BY REFERENCE API-URL
                                   RETURNING API-RC.

      * 3. Execute HTTP request (CALL curl_easy_perform)
           CALL "curl_easy_perform" USING BY VALUE CURL-HANDLE
                                    RETURNING API-RC.

           IF API-RC = 0
               DISPLAY "API call succeeded!"
               *> Originally, the JSON returned to RESPONSE-BUF is entered here.
           ELSE
               DISPLAY "Error occurred, code: " API-RC
           END-IF.

      * 4. Clean up
           CALL "curl_easy_cleanup" USING BY VALUE CURL-HANDLE.

           STOP RUN.
