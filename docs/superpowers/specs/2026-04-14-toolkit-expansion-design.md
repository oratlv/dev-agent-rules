# Toolkit Expansion Design

**Date:** 2026-04-14
**Status:** Approved

## Problem

`dev-agent-rules` currently ships skills and commands. It is missing three artifact types that meaningfully expand what an AI coding assistant can do: subagents (agents), automated hooks, and contextual rules. It also lacks several high-value upstream skills and has no language-specific guidance.

## Goal

Expand the repo into a complete, portable agentic coding toolkit — skills, agents, commands, hooks, and rules — while preserving the submodule-with-symlinks architecture that keeps consumer projects always current.

## Non-goals

- Unity-specific rules or content
- Install profiles / per-project feature flags (can be added later)
- Cursor-specific routing (ROUTER.mdc / index.mdc)
- Language rules beyond TypeScript and Python

---

## Repository Structure

```
dev-agent-rules/
├── skills/           ← existing + ~5 new upstream skills
├── agents/           ← NEW: 9 subagent .md files
├── commands/         ← existing (5 commands)
├── hooks/            ← NEW: security, quality, session-start scripts
│   ├── security/
│   │   ├── block-secrets.sh
│   │   └── scan-secrets-edit.sh
│   ├── quality/
│   │   ├── validate-yaml.py
│   │   └── format-after-edit.sh
│   └── session-start.sh
├── rules/            ← NEW: behavioral + language rules
│   ├── critical-rules.md
│   ├── git-workflow.md
│   ├── investigation-protocol.md
│   ├── typescript.md
│   └── python.md
├── mcp/              ← existing
├── install.sh        ← updated
├── update.sh         ← updated
├── CLAUDE.md         ← updated
└── SOURCES.md        ← updated
```

**Consumer project after install:**

```
my-project/
├── .dev-agent-rules/       ← submodule (pinned to a commit)
└── .claude/
    ├── skills    → ../.dev-agent-rules/skills    (symlink)
    ├── commands  → ../.dev-agent-rules/commands   (symlink)
    ├── agents    → ../.dev-agent-rules/agents     (symlink, NEW)
    ├── rules     → ../.dev-agent-rules/rules      (symlink, NEW)
    ├── hooks     → ../.dev-agent-rules/hooks      (symlink, NEW)
    └── settings.json   ← hooks wired in by install script
```

`.cursor/` gets symlinks for `skills`, `agents`, and `rules`. Hooks are not symlinked into `.cursor/` — Cursor does not have a hooks system equivalent to Claude Code's.

---

## Agents

Nine subagent `.md` files in `agents/`, adapted from nitayk/ai-coding-rules (MIT). These are imported once and treated as custom content in this repo — they are not re-synced from upstream on subsequent `update.sh` runs.

| Agent | Purpose |
|---|---|
| `architect` | System design, architectural decisions, trade-off analysis |
| `code-reviewer` | Reviews completed work against plan and coding standards |
| `security-auditor` | Vulnerability scanning, secrets, auth issues |
| `test-runner` | Test strategy, coverage analysis, test quality |
| `verifier` | Evidence-based verification before claiming completion |
| `data-validator` | Schema validation, data integrity, migration safety |
| `documentation-writer` | Writes and updates docs, READMEs, API docs |
| `git-workflow-specialist` | Commit strategy, branching, PR descriptions |
| `monitoring-analyst` | Observability, logging, alerting recommendations |

Agents complement existing skills: skills instruct Claude how to behave; agents are context-isolated specialists Claude delegates work to. Two agents overlap conceptually with existing skills (`requesting-code-review` → `code-reviewer`, `verification-before-completion` → `verifier`) but serve different roles — the skills define workflows, the agents execute specialist reviews.

Agent files follow the Claude Code subagent format:
```
---
name: <agent-name>
description: <trigger description with examples>
model: inherit
---
<system prompt>
```

**Editing policy:** Agents are safe to edit directly. To add a new agent, drop a `.md` file in `agents/` using the format above.

---

## Hooks

Three categories of hooks. Scripts live in `hooks/` and are symlinked into `.claude/hooks/` in consumer projects. Hook configuration is merged into `.claude/settings.json` by `install.sh`. All hooks are imported once and treated as custom — they are not re-synced from upstream.

### Security (always-on)

**`block-secrets.sh`** — `PreToolUse` hook, matcher: `Read`. Receives the file path via stdin as JSON and denies access to files matching sensitive patterns: `.env`, `.pem`, `.key`, `*credentials*`, `id_rsa`, etc. Exits 0 with the following output to block the tool use:

```json
{
  "hookSpecificOutput": {
    "hookEventName": "PreToolUse",
    "permissionDecision": "deny",
    "permissionDecisionReason": "Access to sensitive file blocked: .env"
  }
}
```

**`scan-secrets-edit.sh`** — `PreToolUse` hook, matchers: `Write`, `Edit`. Scans the content being written for patterns that look like secrets (API keys, tokens, private key headers). Prompts the user to confirm rather than blocking outright. Exits 0 with:

```json
{
  "hookSpecificOutput": {
    "hookEventName": "PreToolUse",
    "permissionDecision": "ask",
    "permissionDecisionReason": "Warning: this file may contain secrets. Confirm you want to write it."
  }
}
```

No output (exits 0 with no JSON) when no secrets patterns are found.

### Quality (opt-in at install time)

**`validate-yaml.py`** — `PostToolUse` hook, matchers: `Write`, `Edit`. Runs only on `.yml`/`.yaml` files after edit. If YAML is invalid, blocks Claude from continuing and provides the parse error so it can self-correct. Exits 0 with:

```json
{
  "decision": "block",
  "reason": "YAML syntax error: <parse error detail>. Fix the file before proceeding.",
  "hookSpecificOutput": {
    "hookEventName": "PostToolUse",
    "additionalContext": "<full yaml.safe_load traceback>"
  }
}
```

No-ops on non-YAML files (exits 0 with no output).

**`format-after-edit.sh`** — `PostToolUse` hook, matchers: `Write`, `Edit`. Detects project formatter config (prettier, black, ruff) and runs formatting after edits. No-ops if no formatter config is found. Exits 0 with no JSON output — formatting runs silently in the background.

### Session

**`session-start.sh`** — `SessionStart` hook. Injects the `using-superpowers` skill content into context using the `hookSpecificOutput.additionalContext` JSON field. This fires per-project (the hook is installed into each project's `.claude/settings.json`). If the `using-superpowers` skill file is not found, the hook exits cleanly with no output.

Output format:
```json
{
  "hookSpecificOutput": {
    "hookEventName": "SessionStart",
    "additionalContext": "<content of using-superpowers/SKILL.md>"
  }
}
```

### Hook settings.json format

The target JSON shape injected into `.claude/settings.json` (hooks use the Claude Code hooks API format — scripts output JSON to stdout, exit 0):

```json
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Read",
        "hooks": [{ "type": "command", "command": ".dev-agent-rules/hooks/security/block-secrets.sh" }]
      },
      {
        "matcher": "Write|Edit",
        "hooks": [{ "type": "command", "command": ".dev-agent-rules/hooks/security/scan-secrets-edit.sh" }]
      }
    ],
    "PostToolUse": [
      {
        "matcher": "Write|Edit",
        "hooks": [{ "type": "command", "command": ".dev-agent-rules/hooks/quality/validate-yaml.py" }]
      },
      {
        "matcher": "Write|Edit",
        "hooks": [{ "type": "command", "command": ".dev-agent-rules/hooks/quality/format-after-edit.sh" }]
      }
    ],
    "SessionStart": [
      {
        "hooks": [{ "type": "command", "command": ".dev-agent-rules/hooks/session-start.sh" }]
      }
    ]
  }
}
```

Quality hooks (`validate-yaml.py`, `format-after-edit.sh`) are only included when the user opts in during install.

### Install behavior

`install.sh` merges hook config into `.claude/settings.json` using `jq`. Merge strategy: **append by script path** — if a hook entry with the same `command` path already exists in `settings.json`, it is skipped. This makes the install idempotent and safe to re-run.

If `jq` is not available, the script prints the full security hooks JSON block (quality hooks if opted in) and instructs the user to merge it into `.claude/settings.json` manually.

**Editing policy:** All hooks are safe to edit directly. No `.subtree-source` file — `update.sh` will not touch the `hooks/` directory.

---

## Rules

Markdown files in `rules/`, symlinked to `.claude/rules/` in consumer projects. Claude Code loads them contextually when relevant files are open.

### Behavioral rules (custom, no upstream sync)

**`critical-rules.md`** — "100% means 100%": actual config values, not variable names; actual metrics, not estimates. Verify before claiming. No temporary files.

**`git-workflow.md`** — Commit discipline, branch naming, PR hygiene, what not to commit.

**`investigation-protocol.md`** — Read code before grepping external links. Get production values from actual sources. Tool selection guidance.

### Language rules (custom, no upstream sync)

**`typescript.md`** — Triggered on `*.ts`, `*.tsx`. Covers: strict typing, async/await conventions, avoiding `any`, test patterns (vitest/jest), import organization.

**`python.md`** — Triggered on `*.py`. Covers: type hints, dataclasses over dicts, async conventions, test patterns (pytest), dependency injection, avoiding bare `except`.

Rules are authored in this repo and not synced from any upstream. No `.subtree-source` file — `update.sh` will not touch them.

**Editing policy:** Rules are safe to edit directly. To add a new rule, drop a `.md` file in `rules/` — no special marker needed.

---

## New Skills

Five skills added from upstream, tracked in `update.sh`. Verified directory names against source repos:

| Skill | Source | Verified path | Purpose |
|---|---|---|---|
| `prd-generation` | nitayk/ai-coding-rules | `skills/prd-generation/` | Structured PRD creation via conversation |
| `fix-issue` | nitayk/ai-coding-rules | `skills/fix-issue/` | End-to-end GitHub issue resolution |
| `token-budget-advisor` | ECC | `skills/token-budget-advisor/` | Token cost awareness for agentic workflows |
| `code-review-excellence` | nitayk/ai-coding-rules | `skills/code-review-excellence/` | Effective review practices |
| `best-practices-enforcement` | nitayk/ai-coding-rules | `skills/best-practices-enforcement/` | Universal code quality validation |

Note: `agent-token-optimization` does not exist in ECC. The correct skill name is `token-budget-advisor`.

---

## Update Mechanism

`update.sh` gains new sections for the two new upstream sources:

| Section | Source repo | What syncs |
|---|---|---|
| ECC skills (existing + new) | `affaan-m/everything-claude-code` | Existing ECC skills + `token-budget-advisor` |
| nitayk skills | `nitayk/ai-coding-rules` | `prd-generation`, `fix-issue`, `code-review-excellence`, `best-practices-enforcement` |

Agents, rules, and hooks are **not tracked in `update.sh`** — they are imported once (manually or via a one-time bootstrap script) and then maintained as custom content in this repo. This is enforced by simply not including them in `update.sh` lists. Running `update.sh` will never touch `agents/`, `rules/`, or `hooks/`.

**Two new flags:**

- `--dry-run` — clones upstream repos but skips `rsync`. Outputs a diff of what would change using `diff -r`. Works with the single-item filter argument (e.g., `update.sh --dry-run tdd-workflow`).
- `--diff` — clones upstream repos and shows a unified diff (`diff -u`) for each file that would change before applying. Prompts for confirmation before running `rsync`. Works with filter argument.

Both flags are incompatible with each other; `--dry-run` takes precedence if both are passed.

---

## Install Script Changes

`install.sh` updated to:

1. Create symlinks for `agents`, `rules`, `hooks` in `.claude/` (and `agents`, `rules` in `.cursor/`)
2. Detect whether `jq` is available
3. Prompt user whether to install quality hooks
4. Merge security hooks (always) + quality hooks (if opted in) into `.claude/settings.json` using `jq` with idempotent append-by-path logic
5. Print fallback JSON block with manual merge instructions if `jq` is unavailable; the fallback always prints security hooks, and quality hooks if opted in

No change to the submodule mechanism — `.dev-agent-rules/` at the project root, relative symlinks throughout.

---

## CLAUDE.md Changes

New section documenting `agents/`, `hooks/`, and `rules/` with the editing policy:

- Do not edit dirs with `.subtree-source` (upstream-synced content)
- `agents/`, `hooks/`, and `rules/` are safe to edit directly — no `.subtree-source`, not touched by `update.sh`
- Adding an agent: drop a `.md` file in `agents/` using the Claude Code subagent frontmatter format
- Adding a rule: drop a `.md` file in `rules/`
- Adding a hook: drop a script in `hooks/` and wire it into `hooks.json` or re-run the relevant section of `install.sh`

---

## Sources

- `agents/`: adapted from nitayk/ai-coding-rules (MIT)
- `hooks/security/`: adapted from nitayk/ai-coding-rules (MIT)
- `hooks/quality/`: adapted from nitayk/ai-coding-rules (MIT)
- `hooks/session-start.sh`: adapted from obra/superpowers (MIT)
- `rules/`: authored in this repo
- New skills: see individual upstream sources in the New Skills table above
