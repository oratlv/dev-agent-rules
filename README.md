# dev-agent-rules

Personal AI agent skills module — a single source of truth for Claude Code and Cursor across all personal projects.

**23 skills** from [obra/superpowers](https://github.com/obra/superpowers) and [anthropics/skills](https://github.com/anthropics/skills).

---

## Install into a project

Run from the **project root** you want to install into:

```bash
bash /path/to/dev-agent-rules/install.sh
```

Or directly from GitHub:

```bash
curl -fsSL https://raw.githubusercontent.com/oratlv/dev-agent-rules/main/install.sh | bash
```

This adds `dev-agent-rules` as a git submodule at `.dev-agent-rules/` and creates relative symlinks:
- `.claude/skills → .dev-agent-rules/skills`
- `.cursor/skills → .dev-agent-rules/skills`

Then commit:
```bash
git add .gitmodules .dev-agent-rules .claude/skills .cursor/skills
git commit -m "Add dev-agent-rules skills module"
```

---

## Clone a project that already has it

```bash
git clone --recurse-submodules git@github.com:oratlv/my-project.git
# Skills are immediately available — no install step needed
```

---

## Update skills

**Update the module itself** (pulls latest from upstream obra/anthropics sources):
```bash
cd /path/to/dev-agent-rules
bash update.sh        # all skills
bash update.sh pdf    # one skill
git add skills/ && git commit -m "Update skills from upstream" && git push
```

**Update the submodule in a project** (after the module has been updated):
```bash
cd my-project
git submodule update --remote .dev-agent-rules
git add .dev-agent-rules && git commit -m "Update dev-agent-rules"
```

---

## Available skills

### obra/superpowers (MIT)
| Skill | Purpose |
|-------|---------|
| `brainstorming` | Collaborative design before implementation |
| `tdd-workflow` | Red-Green-Refactor cycle |
| `systematic-debugging` | Root cause investigation before fixing |
| `verification-before-completion` | Evidence before claiming work is done |
| `writing-plans` | Create implementation plans from specs |
| `executing-plans` | Load and execute a written plan |
| `subagent-driven-development` | Dispatch fresh subagents per task with two-stage review |
| `dispatching-parallel-agents` | Delegate independent tasks to concurrent agents |
| `requesting-code-review` | Dispatch code-reviewer before merging |
| `receiving-code-review` | Evaluate and respond to review feedback |
| `using-git-worktrees` | Isolated git worktrees for feature work |
| `finishing-a-development-branch` | Wrap up: verify, merge/PR/keep/discard |
| `using-superpowers` | Discover and invoke skills correctly |
| `writing-skills` | Author new skills using TDD |

### anthropics/skills (Apache 2.0)
| Skill | Purpose |
|-------|---------|
| `pdf` | Read, create, merge, split PDF files |
| `docx` | Create, read, edit Word documents |
| `xlsx` | Create, read, edit spreadsheets |
| `pptx` | Create, read, edit PowerPoint presentations |
| `mcp-builder` | Build MCP servers (Python FastMCP or Node SDK) |
| `skill-creator` | Create, test, and evaluate new skills |
| `webapp-testing` | Playwright-based web app testing |
| `frontend-design` | Production-grade frontend UI (no generic "AI slop") |
| `web-artifacts-builder` | Multi-component React artifacts (Tailwind + shadcn/ui) |

---

## Add your own skills

Drop a folder in `skills/` without a `.subtree-source` file — it won't be touched by `update.sh`.

See the `writing-skills` skill for guidance on authoring.

---

## License

Upstream skills retain their original licenses (MIT / Apache 2.0). See [SOURCES.md](SOURCES.md).
