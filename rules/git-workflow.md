---
description: Git discipline — staging, commits, branches, PRs, and what never to commit
alwaysApply: true
---

# Git Workflow

## Staging

- Review changes with `git diff` before staging.
- Stage related changes together. Unrelated changes get separate commits.
- Never `git add .` without reviewing what you are adding.

## Commit Messages

Use conventional commits with scope when relevant:

```
feat(auth): add JWT token refresh
fix(api): handle null user response
refactor: extract validation helpers
```

- Subject line: imperative mood, under 72 characters.
- Add a body explaining "why" when the reason is not obvious.
- Never: "changes", "fix stuff", "wip", "asdf", "update".

## Branch Names

Use descriptive prefixes:

```
feat/user-authentication
fix/payment-timeout
refactor/database-layer
```

Never: `dev`, `test`, `temp`, `my-branch`.

## Pull Requests

- Keep PRs focused: one feature or fix per PR.
- Aim for 200-500 lines. If it exceeds 800, consider splitting.
- Include: summary, what changed and why, how to test.
- Link related issues.

## Never Commit

- Secrets: `.env`, credentials, API keys, tokens.
- Build output: `target/`, `dist/`, `node_modules/`, `__pycache__/`.
- IDE config: `.idea/`, `.vscode/`, `*.swp`.
- Large binaries (use Git LFS if needed).

## Force Push

- Never force push to `main` or `master`.
- On feature branches, prefer `--force-with-lease` over `--force`.
- Never rewrite commits others have already pulled.
