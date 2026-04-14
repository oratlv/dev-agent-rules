# Toolkit Expansion Design

**Date:** 2026-04-14
**Status:** Approved

## Problem

`dev-agent-rules` currently ships skills and commands. It is missing two artifact types that meaningfully expand what an AI coding assistant can do: subagents (agents) and contextual rules. It also lacks security hooks and several high-value upstream skills.

## Goal

Expand the repo into a complete, portable agentic coding toolkit — skills, agents, commands, hooks, and rules — while preserving the submodule-with-symlinks architecture that keeps consumer projects always current.

## Non-goals

- Unity-specific rules or content
- Install profiles / per-project feature flags (can be added later)
- Cursor-specific routing (ROUTER.mdc / index.mdc)
- Language-specific rules (deferred to follow-up)
- Quality hooks like auto-formatting and YAML validation (deferred to follow-up)
- Session-start hooks (redundant with Claude Code's native skill auto-loading)

## Deferred items

These are valuable but cut from v1 to reduce scope and ship faster:

| Item | Reason for deferral |
|---|---|
| Language rules (`typescript.md`, `python.md`) | Need `globs` frontmatter and per-language testing to get right |
| Quality hooks (`validate-yaml.py`, `format-after-edit.sh`) | Python dependency, underspecified file targeting, already opt-in |
| `session-start.sh` hook | Redundant — Claude Code auto-loads skills from `.claude/skills/` |
| `--diff` flag for `update.sh` | `--dry-run` + `git diff` after applying covers the use case |
| 5 additional agents (`test-runner`, `data-validator`, `documentation-writer`, `git-workflow-specialist`, `monitoring-analyst`) | Niche for a personal toolkit; add when actually needed in practice |
| `uninstall.sh` | Useful eventually; document manual removal for now |

---

## Repository Structure

```
dev-agent-rules/
├── skills/           ← existing + 5 new upstream skills
├── agents/           ← NEW: 4 subagent .md files
├── commands/         ← existing (5 commands)
├── hooks/            ← NEW: 2 security hook scripts
│   └── security/
│       ├── block-secrets.sh
│       └── scan-secrets-edit.sh
├── rules/            ← NEW: 3 behavioral rules
│   ├── critical-rules.md
│   ├── git-workflow.md
│   └── investigation-protocol.md
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
├── .claude/
│   ├── skills    → ../.dev-agent-rules/skills    (symlink)
│   ├── commands  → ../.dev-agent-rules/commands   (symlink)
│   ├── agents    → ../.dev-agent-rules/agents     (symlink, NEW)
│   ├── rules     → ../.dev-agent-rules/rules      (symlink, NEW)
│   └── settings.json   ← security hooks wired in by install script
└── .cursor/
    ├── skills    → ../.dev-agent-rules/skills    (symlink)
    ├── agents    → ../.dev-agent-rules/agents     (symlink, NEW)
    └── rules     → ../.dev-agent-rules/rules      (symlink, NEW)
```

Hooks are **not** symlinked into any IDE directory. Claude Code reads hooks from `settings.json` command paths, not from a directory. The `settings.json` entries reference hook scripts directly via their submodule path (`.dev-agent-rules/hooks/...`, relative to project root). Cursor does not have a hooks system.

---

## Agents

Four subagent `.md` files in `agents/`, adapted from nitayk/ai-coding-rules (MIT). These are imported once and treated as custom content in this repo — they are not re-synced from upstream on subsequent `update.sh` runs.

| Agent | Purpose |
|---|---|
| `architect` | System design, architectural decisions, trade-off analysis |
| `code-reviewer` | Reviews completed work against plan and coding standards |
| `security-auditor` | Vulnerability scanning, secrets, auth issues |
| `verifier` | Evidence-based verification before claiming completion |

Five additional agents (`test-runner`, `data-validator`, `documentation-writer`, `git-workflow-specialist`, `monitoring-analyst`) are available in nitayk's repo and can be added when needed. See Deferred Items.

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

Security hooks only in v1. Scripts live in `hooks/security/` in the submodule. Hook configuration is merged into `.claude/settings.json` by `install.sh`. All hooks are imported once and treated as custom — they are not re-synced from upstream.

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

**Limitation:** `block-secrets.sh` only intercepts the `Read` tool. A `Bash` command like `cat .env` bypasses it entirely. This is a best-effort guardrail — it catches the common case (Claude using `Read` to access sensitive files) but is not a security boundary.

### Hook settings.json format

The target JSON shape injected into `.claude/settings.json` (hooks use the Claude Code hooks API — scripts output JSON to stdout, exit 0):

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
    ]
  }
}
```

Note on path relativity: symlinks (e.g., `.claude/skills → ../.dev-agent-rules/skills`) are relative to the symlink's parent directory. Hook commands in `settings.json` (e.g., `.dev-agent-rules/hooks/...`) are relative to the project root. These are different frames of reference — both are correct.

### Install behavior

`install.sh` merges hook config into `.claude/settings.json` using `jq`. Merge strategy: **append by script path** — if a hook entry with the same `command` path already exists in `settings.json`, it is skipped. This makes the install idempotent and safe to re-run. The merge is a deep append into the `hooks` object's arrays, not a top-level key replace — existing hooks from the user or other tools are preserved.

If `jq` is not available, the script prints the security hooks JSON block above and instructs the user to merge it into `.claude/settings.json` manually.

**Editing policy:** All hooks are safe to edit directly. No `.subtree-source` file — `update.sh` will not touch the `hooks/` directory.

---

## Rules

Markdown files in `rules/`, symlinked to `.claude/rules/` in consumer projects.

### Behavioral rules (custom, no upstream sync)

All three behavioral rules use `alwaysApply: true` frontmatter so they load in every session regardless of which files are open:

```yaml
---
description: <one-line summary>
alwaysApply: true
---
```

**`critical-rules.md`** — "100% means 100%": actual config values, not variable names; actual metrics, not estimates. Verify before claiming. No temporary files.

**`git-workflow.md`** — Commit discipline, branch naming, PR hygiene, what not to commit.

**`investigation-protocol.md`** — Read code before grepping external links. Get production values from actual sources. Tool selection guidance.

Rules are authored in this repo and not synced from any upstream. No `.subtree-source` file — `update.sh` will not touch them.

**Editing policy:** Rules are safe to edit directly. To add a new rule, drop a `.md` file in `rules/` with frontmatter (`alwaysApply: true` for universal rules, or `globs: ["*.ext"]` for language/file-specific rules).

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

---

## Update Mechanism

`update.sh` gains new sections for the two new upstream sources:

| Section | Source repo | What syncs |
|---|---|---|
| ECC skills (existing + new) | `affaan-m/everything-claude-code` | Existing ECC skills + `token-budget-advisor` |
| nitayk skills | `nitayk/ai-coding-rules` | `prd-generation`, `fix-issue`, `code-review-excellence`, `best-practices-enforcement` |

Agents, rules, and hooks are **not tracked in `update.sh`** — they are imported once (manually or via a one-time bootstrap script) and then maintained as custom content in this repo. This is enforced by simply not including them in `update.sh` lists. Running `update.sh` will never touch `agents/`, `rules/`, or `hooks/`.

**One new flag:**

- `--dry-run` — clones upstream repos but skips `rsync`. Outputs a diff of what would change using `diff -r`. Works with the single-item filter argument (e.g., `update.sh --dry-run tdd-workflow`).

---

## Install Script Changes

`install.sh` updated to:

1. Create symlinks for `agents` and `rules` in `.claude/` and `.cursor/`
2. Detect whether `jq` is available
3. Merge security hooks into `.claude/settings.json` using `jq` with idempotent deep-append-by-path logic (preserves existing hooks from user or other tools)
4. Print fallback JSON block with manual merge instructions if `jq` is unavailable

No change to the submodule mechanism — `.dev-agent-rules/` at the project root, relative symlinks throughout.

---

## CLAUDE.md Changes

New section documenting `agents/`, `hooks/`, and `rules/` with the editing policy:

- Do not edit dirs with `.subtree-source` (upstream-synced content)
- `agents/`, `hooks/`, and `rules/` are safe to edit directly — no `.subtree-source`, not touched by `update.sh`
- Adding an agent: drop a `.md` file in `agents/` using the Claude Code subagent frontmatter format
- Adding a rule: drop a `.md` file in `rules/` with `alwaysApply: true` or `globs:` frontmatter
- Adding a hook: drop a script in `hooks/` and wire it into `.claude/settings.json`

---

## Sources

- `agents/`: adapted from nitayk/ai-coding-rules (MIT)
- `hooks/security/`: adapted from nitayk/ai-coding-rules (MIT)
- `rules/`: authored in this repo
- New skills: see individual upstream sources in the New Skills table above
