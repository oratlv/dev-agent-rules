# dev-agent-rules: Claude Instructions

## What this repo is
A personal AI agent toolkit installed as a git submodule in other projects.
Skills, commands, agents, and rules are symlinked into `.claude/` and `.cursor/` of consumer repos.

This repo uses its own resources — `.claude/skills`, `.claude/commands`, `.claude/agents`, and `.claude/rules` are symlinked to the local directories.

## Repo structure

```
skills/          ← all skills (upstream + custom)
commands/        ← all slash commands (upstream + custom)
agents/          ← subagent definitions (architect, code-reviewer, etc.)
hooks/           ← security hook scripts (PreToolUse)
rules/           ← behavioral rules (alwaysApply)
install.sh       ← installs into a target project (submodule + symlinks)
update.sh        ← pulls latest skills and commands from upstream sources
SOURCES.md       ← upstream attribution
mcp/             ← example MCP configurations
```

## Editing rules

**Do NOT edit files inside skill directories that contain a `.subtree-source` file.**
These are synced from upstream (obra/superpowers, anthropics/skills) and will be overwritten by `update.sh`.

**Do NOT edit command files listed in `ECC_COMMANDS` in `update.sh`.**
These are synced from affaan-m/everything-claude-code and will be overwritten by `update.sh`.

**Safe to edit:** anything without `.subtree-source` and not in `ECC_COMMANDS` — including this file, `install.sh`, `update.sh`, `SOURCES.md`, custom skills, custom commands, agents, hooks, and rules.

## Adding a custom skill

Drop a new folder in `skills/` with a `SKILL.md` file. Do not add a `.subtree-source` file.
See the `writing-skills` skill for authoring guidance.

```
skills/
  my-new-skill/
    SKILL.md     ← required
    references/  ← optional heavy docs
    scripts/     ← optional scripts
```

## Adding a custom command

Drop a new `.md` file in `commands/`. Do not add it to `ECC_COMMANDS` in `update.sh`.

```
commands/
  my-command.md   ← invoked as /my-command
```

## Adding an agent

Drop a `.md` file in `agents/` with Claude Code subagent frontmatter.

```
agents/
  my-agent.md     ← dispatched by name from other agents/skills
```

Required frontmatter:
```yaml
---
name: my-agent
description: |
  When to use this agent and example prompts.
model: inherit
---
```

## Hooks

Security hook scripts live in `hooks/security/`. These are wired into `.claude/settings.json` by `install.sh` as PreToolUse hooks.

- `block-secrets.sh` — blocks Read access to sensitive files (.env, credentials, etc.)
- `scan-secrets-edit.sh` — scans Write/Edit content for secret-like patterns

Safe to edit. Not touched by `update.sh`.

## Adding a rule

Drop a `.md` file in `rules/` with `alwaysApply: true` frontmatter. Rules are automatically loaded by Claude Code for every conversation.

```
rules/
  my-rule.md      ← always applied
```

Required frontmatter:
```yaml
---
description: Short description of what this rule enforces
alwaysApply: true
---
```

## Updating upstream skills and commands

```bash
bash update.sh               # update all upstream skills and commands
bash update.sh tdd-workflow  # update one skill
bash update.sh code-review   # update one command
git add skills/ commands/ && git commit -m "Update skills and commands from upstream" && git push
```

## Installing into a new project

Run from the target project's root:
```bash
bash /path/to/dev-agent-rules/install.sh
```

## Git workflow

Always work on a feature branch — never commit directly to `main`.

```bash
git checkout -b feat/my-change
# ... make changes ...
/prp-commit      # stage + commit
/prp-pr          # push + open PR
```

## Communication
- BLUF: lead with the answer.
- Make minimal, focused changes — only what is necessary.
- Verify before claiming completion.
