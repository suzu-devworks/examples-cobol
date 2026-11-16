---
name: cobol-programming
description: >-
  Use this skill whenever implementing, changing, or reviewing COBOL programs in this repository,
  especially gnuCOBOL batch jobs that read, write, sort, group, match, separate, or transform records.
  Follow the repository's conventions and build workflow, and verify behavior with representative inputs
  and outputs.
---

# COBOL Programming

Use this skill for COBOL work in this repository. Treat the patterns below as practical guidance, not as a
substitute for the request, [repository coding conventions](../../../docs/coding-conventions.md), or behavior
established by relevant examples. Existing examples are learning records; verify their behavior before reusing it.

## Workflow and Placement

1. Establish the program's purpose, inputs and outputs, arguments, and success and failure conditions.
2. Honor a requested file location. Otherwise, choose an existing category under `src/` by the program's main
   purpose, using the table below. If no category fits, consider the build structure before proposing a new one;
   ask when multiple placements are reasonable.
3. Find similar programs and relevant COPYBOOKs. Confirm that their behavior fits the requirements instead of
   treating an example as the specification.
4. Choose the program structure and data definitions. Check record lengths, key positions, and input ordering
   across programs that exchange records.
5. Consider normal and empty inputs, boundary and invalid values, and missing or duplicate matches. Decide
   whether invalid records stop processing or may be skipped, and how that choice affects the exit status.
6. Build the affected module and verify output contents, record counts, and applicable exit statuses with
   small fixed inputs. Check linking when C libraries are used.
7. Review changed or added code against related code for style consistency, paragraph division, and reuse.
   Fix issues, then repeat the build, verification, and review until they reveal no problems.

| Location | Purpose |
| --- | --- |
| [`src/generating/`](../../../src/generating/) | Generate data. |
| [`src/sorting/`](../../../src/sorting/) | Sort records. |
| [`src/grouping/`](../../../src/grouping/) | Group or aggregate by key. |
| [`src/matching/`](../../../src/matching/) | Match or join multiple inputs by key. |
| [`src/separating/`](../../../src/separating/) | Route records by condition or key. |
| [`src/transforming/`](../../../src/transforming/) | Transform records, data, or file formats. |
| [`src/shared/`](../../../src/shared/) | Shared libraries and subroutines. |
| [`src/copies/`](../../../src/copies/) | Shared COPYBOOKs. |

## Define names and records

- Name paragraphs descriptively in uppercase with hyphens, such as `INITIALIZE-PROCESS` and `READ-IN1-FILE`.
  Keep program names and variable names consistent with the repository coding conventions.
- Use level-01 groups instead of level-77 items for working storage. Group related data by purpose, such as
  `WS-ARGS`, `WS-COUNTERS`, and `WS-IN1-REC`; a useful order is arguments, input definitions, output
  definitions, then other working storage.
- Document key positions, field lengths, and required input ordering for sorting, grouping, and matching. Use
  one-based positions when describing positions to users.
- Reuse COPYBOOKs for shared record layouts and constants. Use `COPY ... REPLACING` with placeholders such as
  `==:PREFIX:==` when names or prefixes need to differ.
- Define a level-01 group at the COPYBOOK use site and begin working-storage COPYBOOK contents at level 03.
  Set record length and padding at the use site, not inside a shared COPYBOOK.
- Share repeated file-status and error-information definitions where appropriate, replacing prefixes so each
  file retains its own status.

## Structure processing

Consider this entry-point sequence:

```cobol
       PROCEDURE DIVISION.
           PERFORM INITIALIZE-PROCESS
           PERFORM MAIN-PROCESS
           PERFORM TERMINATE-PROCESS
           STOP RUN.
```

- Define paragraphs in initialization, termination, then main-processing order. Keep related initialization
  and termination paragraphs near their parent paragraphs.
- Keep file-specific I/O paragraphs at the end, ordered `OPEN`, `CLOSE`, `READ`, and `WRITE` for each file as applicable.
- In initialization, validate arguments, prepare the environment, open files, and display a start message with
  the program ID when appropriate. In termination, close files, clean up, and display an end message.
- Track and report input and output record counts at termination when processing files.
- Keep paragraphs focused and reasonably short. Extract deeply nested processing when it improves clarity,
  while retaining enough context at call sites to explain loops.

## Handle arguments and files

- Specify argument order, required and optional values, defaults, ranges, and usage. Validate argument count and
  values before processing.
- Select file organization based on the required format. Many text-file examples use
  `ORGANIZATION IS LINE SEQUENTIAL`, with lines corresponding to fixed-length COBOL records.
- Use a separate `FILE STATUS` for each file. Check it immediately after `OPEN`, `READ`, `WRITE`, and `CLOSE`.
  Name success and EOF states with level-88 conditions; on error, report the file and status and pass them to
  common error handling.
- Check `FILE STATUS` immediately after each `READ`, then choose one EOF control-flow convention rather than
  maintaining duplicate EOF state:
  - Use the file-status EOF condition, or one flag set from it, when EOF must remain distinct from input data,
    especially when malformed records must be reported.
  - Use a sentinel when it is outside the valid key domain and the algorithm can use it directly as an ordered
    boundary. For example, ascending matching can set an exhausted input key to `HIGH-VALUES`, which sorts after
    every valid key and avoids a separate EOF branch or flag; descending matching needs the opposite sentinel.
    If malformed input equal to the sentinel must be reported rather than treated as EOF, use file status or a
    flag instead.
- When EOF is detected from `FILE STATUS`, overwrite a stale input record with `HIGH-VALUES`.
- For `SELECT OPTIONAL` with `OPEN EXTEND`, recognize the success status for a newly created file as well as ordinary success.

## Report failures and verify

- Report failures clearly.
- Do not display a success message after failure.
- Decide whether skipped invalid records change the final status.
- Follow the repository convention that success is zero and failure is nonzero; do not assume a more specific
  exit-code mapping.

### Verification checklist

- [ ] Build the affected module with its category Makefile. The root `make` delegates to category Makefiles;
      `make -C src/<category>` builds a selected category.
- [ ] Inspect the Makefile and module settings to find the actual output location. Shared rules are in
      `src/_build-rules/cobol.common.mk`.
- [ ] Run small fixed inputs and verify output contents, record counts, and applicable exit statuses.
- [ ] Include empty, boundary, invalid, and failure cases when relevant. Check missing or duplicate matches
      when the program performs matching.
- [ ] Check linking when C libraries are used.
- [ ] Investigate nonfatal warnings and their effects. Do not change build rules or toolchain settings just to
      suppress a harmless warning.
- [ ] Review the changed or added code against related examples and conventions. Check coding-style consistency,
      paragraph division, and opportunities to reuse existing code.
- [ ] Fix issues, then repeat the build, verification, and review. Finish only when they reveal no problems.
