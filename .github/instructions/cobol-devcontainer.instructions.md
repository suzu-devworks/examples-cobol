---
applyTo: '**'
---

# COBOL Dev Container build warning

When building with `cobc` in the COBOL Dev Container, the
`'_FORTIFY_SOURCE' redefined` warning has been observed as nonfatal. Do not
change build settings or call attention to that warning alone. Investigate
build failures, other warnings, and changes in the warning's behavior normally.
