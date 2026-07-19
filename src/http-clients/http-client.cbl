       IDENTIFICATION DIVISION.
       PROGRAM-ID. HTTP-CLIENT.

       DATA DIVISION.
       WORKING-STORAGE SECTION.
      * APIのURLや送受信バッファを定義
       01  API-URL         PIC X(100) VALUE
           Z"https://jsonplaceholder.typicode.com/todos/1".
       01  RESPONSE-BUF    PIC X(1000).

       01  CURL-HANDLE     USAGE POINTER.
       01  API-RC          PIC S9(9) COMP-5.
       01  CURLOPT-URL     PIC S9(9) COMP-5 VALUE 10002.

       PROCEDURE DIVISION.
           DISPLAY "--- REST API呼び出し開始 ---"

      * 1. libcurlの初期化 (C言語の curl_easy_init をCALL)
           CALL "curl_easy_init" RETURNING CURL-HANDLE.

           IF CURL-HANDLE = NULL
               DISPLAY "初期化失敗"
               STOP RUN
           END-IF.

      * 2. URLを設定 (curl_easy_setopt をCALL)
           CALL "curl_easy_setopt" USING BY VALUE CURL-HANDLE
                                         BY VALUE CURLOPT-URL
                                         BY REFERENCE API-URL
                                   RETURNING API-RC.

      * 3. HTTPリクエストを実行 (curl_easy_perform をCALL)
           CALL "curl_easy_perform" USING BY VALUE CURL-HANDLE
                                    RETURNING API-RC.

           IF API-RC = 0
               DISPLAY "APIの呼び出しに成功しました！"
               *> 本来はここで RESPONSE-BUF に返ってきたJSONが入る
           ELSE
               DISPLAY "エラー発生、コード: " API-RC
           END-IF.

      * 4. クリーンアップ
           CALL "curl_easy_cleanup" USING BY VALUE CURL-HANDLE.

           STOP RUN.
