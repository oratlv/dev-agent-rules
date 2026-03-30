# dev-agent-rules: Claude Instructions

## What this repo is
A personal AI skills module installed as a git submodule in other projects.
Skills in `skills/` are symlinked into `.claude/skills/` and `.cursor/skills/` of consumer repos.

## Repo structure

```
skills/          ← all 23 skills (upstream + custom)
install.sh       ← installs into a target project (submodule + symlinks)
update.sh        ← pulls latest from obra/superpowers and anthropics/skills
SOURCES.md       ← upstream attribution
mcp/             ← example MCP configurations
```

## Editing rules

**Do NOT edit files inside skill directories that contain a `.subtree-source` file.**
These are synced from upstream (obra/superpowers, anthropics/skills) and will be overwritten by `update.sh`.

**Safe to edit:** anything without `.subtree-source` — including this file, `install.sh`, `update.sh`, `SOURCES.md`, and any custom skills you add.

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

## Updating upstream skills

```bash
bash update.sh             # update all upstream skills
bash update.sh tdd-workflow  # update one skill
git add skills/ && git commit -m "Update skills from upstream" && git push
```

## Installing into a new project

Run from the target project's root:
```bash
bash /path/to/dev-agent-rules/install.sh
```

## Communication
- BLUF: lead with the answer.
- Make minimal, focused changes — only what is necessary.
- Verify before claiming completion.
