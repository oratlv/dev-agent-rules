# dev-agent-rules

Personal AI agent toolkit — a single source of truth for Claude Code and Cursor across all personal projects.

**28 skills**, **4 agents**, **3 rules**, and **security hooks** from [obra/superpowers](https://github.com/obra/superpowers), [anthropics/skills](https://github.com/anthropics/skills), [affaan-m/everything-claude-code](https://github.com/affaan-m/everything-claude-code), and [nitayk/ai-coding-rules](https://github.com/nitayk/ai-coding-rules).

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
- `.claude/skills → ../.dev-agent-rules/skills`
- `.claude/commands → ../.dev-agent-rules/commands`
- `.claude/agents → ../.dev-agent-rules/agents`
- `.claude/rules → ../.dev-agent-rules/rules`
- `.cursor/skills → ../.dev-agent-rules/skills`
- `.cursor/agents → ../.dev-agent-rules/agents`
- `.cursor/rules → ../.dev-agent-rules/rules`

Then commit:
```bash
git add .gitmodules .dev-agent-rules .claude .cursor .mcp.json
git commit -m "Add dev-agent-rules toolkit"
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

### affaan-m/everything-claude-code (MIT)
| Skill | Purpose |
|-------|---------|
| `strategic-compact` | Context-preserving conversation compaction |
| `continuous-learning-v2` | Evolving knowledge base across sessions |
| `deep-research` | Multi-source research and synthesis |
| `prompt-optimizer` | Iterative prompt refinement |
| `search-first` | Search before implementing |
| `token-budget-advisor` | Informed choice about response depth |

### nitayk/ai-coding-rules (MIT)
| Skill | Purpose |
|-------|---------|
| `prd-generation` | Generate PRDs through structured conversation |
| `fix-issue` | Fetch a GitHub issue and implement a fix with tests |
| `code-review-excellence` | Structured code review methodology |
| `best-practices-enforcement` | Validate code against SOLID, DRY, security patterns |

---

## Agents

Subagent definitions in `agents/` — dispatched by Claude Code for specialized tasks.

| Agent | Purpose |
|-------|---------|
| `architect` | System design, scalability, and technical decisions |
| `code-reviewer` | Review implementations against plans and standards |
| `security-auditor` | Scan for vulnerabilities, credential exposure, CVEs |
| `verifier` | Validate completed work, run tests, check edge cases |

---

## Hooks

Security hooks in `hooks/security/` are wired into `.claude/settings.json` by `install.sh`.

| Hook | Trigger | Purpose |
|------|---------|---------|
| `block-secrets.sh` | PreToolUse (Read) | Block access to sensitive files (.env, credentials) |
| `scan-secrets-edit.sh` | PreToolUse (Write/Edit) | Detect secret-like patterns in content being written |

---

## Rules

Behavioral rules in `rules/` are applied to every conversation (`alwaysApply: true`).

| Rule | Purpose |
|------|---------|
| `critical-rules` | Verify don't assume, complete all work, no garbage files |
| `git-workflow` | Staging, commits, branches, PRs, and what never to commit |
| `investigation-protocol` | Read before grep, actual values not variable names |

---

## Add your own skills

Drop a folder in `skills/` without a `.subtree-source` file — it won't be touched by `update.sh`.

See the `writing-skills` skill for guidance on authoring.

---

## License

Upstream skills retain their original licenses (MIT / Apache 2.0). See [SOURCES.md](SOURCES.md).
