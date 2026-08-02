# AGENTS

## Objectives

- Existing implementations are retained as a record of the learning process.
- Improvements may be made if better approaches are identified.

## Project Structure

- Application source code, libraries, and tests are located under the `/src` directory.
- Copy clauses are shared in `/src/copies`.
- Common libraries are shared in `/src/shared`.
- Folders are organized by category and may contain multiple executable modules.

## Architecture

- Since gnuCOBOL transpiles to C programs, C language rules and conventions take precedence.

## Design Principles

- Source code, comments, and documentation must all be written in English.
- Maintain existing conventions.
- Prioritize simple implementations.
- Prioritize the use of modern language features if they improve readability or maintainability.

## Workflow

- Keep diffs minimal to ensure they are reviewable.
- For complex, ambiguous, or high-impact tasks, align on the approach before making significant changes.
- Do not add or update dependencies without prior confirmation.
- Always seek approval before making breaking changes.
- Verify changes after editing.

## Boundaries

- Do not create pull requests or perform operations on the remote repository unless instructed to do so.

## References

- Read [docs/coding-conventions.md](./docs/coding-conventions.md) before changing source code.

Please refer to relevant instructions or skill information regarding language-specific rules, documentation, tests,
 or repository-specific workflows.
