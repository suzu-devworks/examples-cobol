# examples-cobol

## What is this repository?

This repository is my COBOL "notebook" (or collection of examples), built from
small, focused programs. It records practical experiments and reference
implementations that revisit familiar language features, common patterns, and
interoperability-oriented workflows.

It is a public knowledge base rather than a complete solution set. At the same
time, it is a place where I can look back on COBOL development from around the
year 2000 and enjoy discovering how recent COBOL environments feel today. The
examples reflect my current understanding and are expected to evolve over time.

## What topics are covered?

- Core COBOL syntax and control flow basics
- Input/output and interactive console handling
- Data definitions with copybooks and shared records
- Batch data processing with sorting, grouping, matching, separation, and CSV
  conversion
- Indexed file (ISAM) processing and SQLite database access
- Sub-programming patterns (contained, nested, and static calls)
- Data generation examples and UUID-oriented helper flows
- HTTP client usage from COBOL programs
- [JCL-style integration scenario](./docs/application-integration-test-scenarios.md)
  with STEP-based restart
- Build organization with Makefiles across multiple example modules

## References

- [GNU COBOL official site](https://gnucobol.sourceforge.io/)
