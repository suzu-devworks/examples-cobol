       IDENTIFICATION DIVISION.
       PROGRAM-ID. gen_uuid.

       DATA DIVISION.
       WORKING-STORAGE SECTION.
      * C language uuid_t (16 bytes)
       01  WS-BINARY-UUID  PIC X(16).
      * C language tray (37 bytes including NULL terminator)
       01  WS-UUID-C-STR   PIC X(37).

       LINKAGE SECTION.
       01  LK-UUID-OUT     PIC X(36).

       PROCEDURE DIVISION USING LK-UUID-OUT.
           CALL "uuid_generate" USING BY REFERENCE WS-BINARY-UUID
           CALL "uuid_unparse"  USING BY REFERENCE WS-BINARY-UUID
                                                   WS-UUID-C-STR

           MOVE WS-UUID-C-STR(1:36) TO LK-UUID-OUT

           GOBACK.

       END PROGRAM gen_uuid.
