---
description: Core behavioral rules — verify don't assume, complete all work, no garbage files
alwaysApply: true
---

# Critical Rules

## Verify, Don't Assume

Existing knowledge is guidance, not ground truth.

- Read existing docs and code, then VERIFY what you find.
- Never claim "verified" unless you actually checked.
- Be explicit about what you investigated vs. what you assumed.
- When uncertain, say so. Do not fabricate confidence.

## 100% Means 100%

No rounding, no "mostly done", no "probably works".

- Read ACTUAL values, not variable names.
- Check ACTUAL behavior, not theoretical behavior.
- Complete ALL identified tasks, not just the easy ones.
- If you say "all tests pass", you ran them. If you say "no references", you searched.

## No Garbage Files

Only create files with permanent value.

- Source code, tests, config, documentation: allowed.
- Temporary scripts, scratch files, playground code: forbidden.
- `test.txt`, `output.log`, `temp.py`, `scratch.js`: forbidden.
- Commented-out code blocks: remove them, don't leave them.
- If you create a temporary file for any reason, delete it before you finish.
