# Coding Conventions

This document defines the minimum coding rules for COBOL programs in this repository.

## Scope

- These conventions apply to all COBOL source files and COPYBOOKs in this repository.

## File Format and Encoding

- Source files must use fixed-format COBOL.
- File encoding must be UTF-8.
- Line endings must be LF.

## Naming Conventions

- Program names must use only lowercase letters, digits, and underscores (`_`).
- Variable names must use only uppercase letters, digits, and hyphens (`-`).

Program names intentionally avoid hyphens because GnuCOBOL transpiles
COBOL to C, and hyphens can cause issues in C-generated identifiers.

## File Extensions

- COBOL source files must use the `.cbl` extension.
- Shared COBOL libraries must use the `.cbl` extension.
- COPYBOOK files must use the `.cpy` extension.
