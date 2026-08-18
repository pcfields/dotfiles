---
description: Write one behavioral test at a named seam on a cheap model, following the tdd skill's red discipline. Implementation stays in build.
agent: build
model: opencode/kimi-k2.7-code
subtask: true
---

Write one test for this behavior, using the `tdd` skill's rules:

$ARGUMENTS

Steps:

1. Identify the seam being tested (from the plan file if one is referenced
   above, or ask if it's genuinely unclear).
2. Write one minimal test for one behavior at that seam. Real code, no
   mocks unless unavoidable. Clear name that states the behavior.
3. Run it and confirm it fails for the expected reason — feature missing,
   not a typo or setup error. Show the failure output.
4. Report the test file, the test name, and the RED output. Do not write
   the implementation — that happens in the main `build` session.
