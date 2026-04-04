# dev-agent-rules: Claude Instructions

## What this repo is
A personal AI skills and commands module installed as a git submodule in other projects.
Skills in `skills/` are symlinked into `.claude/skills/` and `.cursor/skills/` of consumer repos.
Commands in `commands/` are symlinked into `.claude/commands/` of consumer repos.

This repo uses its own skills and commands — `.claude/skills` and `.claude/commands` are symlinked to the local `skills/` and `commands/` directories.

## Repo structure

```
skills/          ← all skills (upstream + custom)
commands/        ← all slash commands (upstream + custom)
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

**Safe to edit:** anything without `.subtree-source` and not in `ECC_COMMANDS` — including this file, `install.sh`, `update.sh`, `SOURCES.md`, custom skills, and custom commands.

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
