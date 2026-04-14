---
description: How to investigate code — read before grep, actual values not variable names
alwaysApply: true
---

# Investigation Protocol

## Read Before You Grep

When investigating code, understand structure before searching for strings.

1. **Map the structure first.** Find entry points, callers, dependencies, and call chains.
2. **Read the actual code.** Skim is not reading. Read 100% of the relevant files.
3. **Then grep for connections.** Search for identifiers that link subsystems: topic names, endpoint URLs, config keys, service names.

## Get Actual Values

Variable names are not values. Estimates are not measurements.

- Read config files for actual settings, not the variable names that reference them.
- When reporting numbers, get them from an actual source.
- "The timeout is `REQUEST_TIMEOUT`" is useless. "The timeout is 30s (from `config/app.yml:42`)" is useful.

## Investigate Before Changing

Before modifying code you did not write:

1. Find all callers of the function or module.
2. Understand why it was written this way (check git blame, comments, tests).
3. Identify what could break.
4. Only then make the change.

## Report What You Know vs. What You Assumed

Be explicit:

- "I confirmed X by reading `path/to/file`" -- good.
- "X is probably true based on the naming" -- acceptable, but say so.
- "X is true" (without checking) -- never do this.
