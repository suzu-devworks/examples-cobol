       IDENTIFICATION DIVISION.
       PROGRAM-ID. generate_uuid.

       DATA DIVISION.
       WORKING-STORAGE SECTION.
       01  WS-UUID          PIC X(36).

       PROCEDURE DIVISION.
           CALL "gen_uuid" USING BY REFERENCE WS-UUID
           DISPLAY "UUID: " WS-UUID
           STOP RUN.
