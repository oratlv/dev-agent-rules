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

`.cursor/` gets symlinks for `skills`, `agents`, and `rules` (Cursor supports all three).

---

## Agents

Nine subagent `.md` files in `agents/`, adapted from nitayk/ai-coding-rules (MIT):

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

Agent files follow the Claude Code agent format:
```
---
name: <agent-name>
description: <trigger description with examples>
model: inherit
---
<system prompt>
```

---

## Hooks

Three categories. Scripts live in `hooks/` and are symlinked into `.claude/hooks/` in consumer projects. Hook configuration is merged into `.claude/settings.json` by `install.sh`.

### Security (always-on)

**`block-secrets.sh`** — `PreToolUse[Read]` hook. Denies Claude read access to files matching sensitive patterns: `.env`, `.pem`, `.key`, `*credentials*`, `id_rsa`, etc. Returns `{"permission": "deny"}` with a user message.

**`scan-secrets-edit.sh`** — `PreToolUse[Write,Edit]` hook. Warns when a file being written contains patterns that look like secrets (API keys, tokens, private key headers). Does not block — returns a warning in `hookSpecificOutput`.

### Quality (opt-in at install time)

**`validate-yaml.py`** — `PostToolUse[Write,Edit]` hook. Runs on `.yml`/`.yaml` files after edit. If YAML is invalid, injects a warning so Claude can self-correct.

**`format-after-edit.sh`** — `PostToolUse[Write,Edit]` hook. Detects project formatter config (prettier, black, ruff) and triggers formatting after edits. No-ops if no formatter is found.

### Session

**`session-start.sh`** — `SessionStart` hook. Injects the `using-superpowers` skill content into context so Claude knows skills are available from the first message.

### Install behavior

`install.sh` uses `jq` to merge hook config into `.claude/settings.json`. Security hooks are always wired in. Quality hooks prompt the user during install. If `jq` is not available, the script prints the required JSON block and instructs the user to merge manually.

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

---

## New Skills

Five skills added from upstream, tracked in `update.sh`:

| Skill | Source | Purpose |
|---|---|---|
| `prd-generation` | ECC (affaan-m/everything-claude-code) | Structured PRD creation via conversation |
| `fix-issue` | ECC | End-to-end GitHub issue resolution |
| `agent-token-optimization` | ECC | Token cost awareness for agentic workflows |
| `code-review-excellence` | nitayk/ai-coding-rules | Effective review practices |
| `best-practices-enforcement` | nitayk/ai-coding-rules | Universal code quality validation |

---

## Update Mechanism

`update.sh` gains new sections:

| Section | Source repo | What syncs |
|---|---|---|
| ECC skills (existing) | `affaan-m/everything-claude-code` | Existing + 3 new skills |
| nitayk skills | `nitayk/ai-coding-rules` | `code-review-excellence`, `best-practices-enforcement` |
| nitayk agents (initial) | `nitayk/ai-coding-rules` | 9 agents on first pull; treated as custom after import |

Agents, rules, and hooks are **not re-synced** after initial import — they are treated as custom content maintained in this repo. The `.subtree-source` marker file is not added to these directories.

Two new flags added to `update.sh`:
- `--dry-run` — shows what would change without applying
- `--diff` — shows file diffs before applying changes

---

## Install Script Changes

`install.sh` updated to:

1. Create symlinks for `agents`, `rules`, `hooks` in `.claude/` and `.cursor/`
2. Wire hook configuration into `.claude/settings.json` via `jq`
3. Prompt user for quality hooks opt-in
4. Print fallback instructions if `jq` is unavailable

No change to the submodule mechanism — `.dev-agent-rules/` at the project root, relative symlinks throughout.

---

## CLAUDE.md Changes

New section documenting `agents/`, `hooks/`, and `rules/` with the same editing policy:
- Do not edit dirs with `.subtree-source`
- Rules and agents are safe to edit directly
- Adding agents: drop a `.md` file in `agents/` following the agent frontmatter format
- Adding rules: drop a `.md` file in `rules/` — no special marker needed

---

## Sources

- `agents/`: adapted from nitayk/ai-coding-rules (MIT)
- `hooks/security/`: adapted from nitayk/ai-coding-rules (MIT)
- `hooks/session-start.sh`: adapted from obra/superpowers (MIT)
- `rules/`: authored in this repo
- New skills: see individual upstream sources above
