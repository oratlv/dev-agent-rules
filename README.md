# dev-agent-rules

A complete AI-assisted development workflow — skills, agents, rules, hooks, and commands — managed as a single git submodule across all your projects.

Works with **Claude Code** and **Cursor**.

## What's inside

| Component | Count | What it does |
|-----------|-------|-------------|
| **Skills** | 33 | Multi-step workflows: brainstorming, TDD, debugging, code review, plans |
| **Agents** | 4 | Context-isolated specialists: architect, code-reviewer, security-auditor, verifier |
| **Commands** | 5 | Quick actions: `/code-review`, `/prp-commit`, `/prp-pr`, `/plan`, `/build-fix` |
| **Rules** | 3 | Always-on behavioral guidance: verification, git discipline, investigation |
| **Hooks** | 2 | Security guardrails: block sensitive file reads, detect secrets in writes |

## How it works

Install once as a submodule. Symlinks expose everything to your IDE. One `git submodule update` pulls changes across all projects.

```
my-project/
├── .dev-agent-rules/          ← submodule (this repo)
├── .claude/
│   ├── skills   → symlink     ← Claude Code picks these up automatically
│   ├── agents   → symlink
│   ├── commands → symlink
│   ├── rules    → symlink
│   └── settings.json          ← security hooks wired in
└── .cursor/
    ├── skills   → symlink     ← Cursor picks these up automatically
    ├── agents   → symlink
    └── rules    → symlink
```

## Quick start

**Install into a project** (run from project root):

```bash
bash /path/to/dev-agent-rules/install.sh
git add .gitmodules .dev-agent-rules .claude .cursor .mcp.json
git commit -m "Add dev-agent-rules toolkit"
```

Or directly from GitHub:

```bash
curl -fsSL https://raw.githubusercontent.com/oratlv/dev-agent-rules/main/install.sh | bash
```

**Clone a project that already has it:**

```bash
git clone --recurse-submodules <repo-url>
# Everything is ready — no install step needed.
```

## The workflow

Skills are organized around a development lifecycle. You don't need to use all of them — pick what fits.

```
Idea → /brainstorming → /writing-plans → /subagent-driven-development → /finishing-a-development-branch
         Design            Plan              Build + Review                    Ship
```

### Planning & Design

| Skill | What it does |
|-------|-------------|
| `brainstorming` | Collaborative design — questions, approaches, spec writing |
| `prd-generation` | Structured PRD creation through conversation |
| `writing-plans` | Break specs into implementation plans |
| `task-breakdown` | Break PRDs into sized, ordered sub-tasks |

### Building

| Skill | What it does |
|-------|-------------|
| `tdd-workflow` | Red-Green-Refactor cycle |
| `executing-plans` | Execute a plan with checkpoints |
| `subagent-driven-development` | Dispatch subagents per task with two-stage review |
| `dispatching-parallel-agents` | Run independent tasks concurrently |
| `using-git-worktrees` | Isolated workspaces for feature branches |
| `fix-issue` | End-to-end GitHub issue resolution |
| `setup-local-dev` | Persistent dev server with pm2 |

### Quality & Review

| Skill | What it does |
|-------|-------------|
| `systematic-debugging` | Root cause investigation before fixing |
| `requesting-code-review` | Dispatch reviewer before merging |
| `receiving-code-review` | Evaluate feedback with technical rigor |
| `code-review-excellence` | Structured code review methodology |
| `best-practices-enforcement` | Validate against SOLID, DRY, security patterns |
| `verification-before-completion` | Evidence before claiming "done" |
| `code-cleanup` | Remove AI slop, dead code, anti-patterns |
| `finishing-a-development-branch` | Merge, PR, or cleanup decision |

### Documents & Media

| Skill | What it does |
|-------|-------------|
| `pdf` | Read, create, merge, split PDFs |
| `docx` | Create and edit Word documents |
| `xlsx` | Spreadsheets with formulas and formatting |
| `pptx` | PowerPoint creation and editing |

### Frontend

| Skill | What it does |
|-------|-------------|
| `frontend-design` | Production-grade UI — no generic AI aesthetics |
| `web-artifacts-builder` | Multi-component React artifacts (Tailwind + shadcn/ui) |
| `webapp-testing` | Playwright-based browser testing |

### Meta & Tooling

| Skill | What it does |
|-------|-------------|
| `mcp-builder` | Build MCP servers (Python FastMCP or Node SDK) |
| `skill-creator` | Create, test, and evaluate new skills |
| `writing-skills` | Author skills following the SKILL.md spec |
| `using-superpowers` | Introduction to the skills system |
| `strategic-compact` | Context compaction at logical intervals |
| `token-budget-advisor` | Token cost awareness for agentic workflows |
| `deep-research` | Multi-source research with citations |
| `search-first` | Search for existing solutions before writing code |
| `prompt-optimizer` | Iterative prompt refinement |
| `continuous-learning-v2` | Instinct-based learning across sessions |
| `session-memory` | Persistent context across sessions |
| `repository-organization` | Restructure messy repos into clean layouts |

## Agents

Subagent definitions dispatched by Claude Code for specialized, context-isolated work.

| Agent | Purpose |
|-------|---------|
| `architect` | System design, architectural decisions, trade-off analysis |
| `code-reviewer` | Review implementations against plans and coding standards |
| `security-auditor` | Vulnerability scanning, credential exposure, auth issues |
| `verifier` | Evidence-based verification — run tests, check edge cases |

## Rules

Always-on behavioral rules loaded in every Claude Code session.

| Rule | Enforces |
|------|----------|
| `critical-rules` | Verify don't assume. 100% means 100%. No garbage files. |
| `git-workflow` | Conventional commits, branch naming, what never to commit |
| `investigation-protocol` | Read code before grepping. Actual values, not variable names. |

## Security hooks

Wired into `.claude/settings.json` automatically by `install.sh`.

| Hook | Trigger | What it does |
|------|---------|-------------|
| `block-secrets.sh` | Before file read | Blocks `.env`, `.pem`, credentials, private keys |
| `scan-secrets-edit.sh` | Before file write | Detects API keys, tokens, secrets in content |

Note: these intercept Claude's `Read`/`Write`/`Edit` tools. A `Bash(cat .env)` bypasses them — this is a guardrail, not a security boundary.

## Updating

**Pull latest from upstream sources:**

```bash
cd /path/to/dev-agent-rules
bash update.sh                    # update all
bash update.sh tdd-workflow       # update one skill
bash update.sh --dry-run          # preview changes without applying
git add skills/ commands/ && git commit -m "Update from upstream" && git push
```

**Update the submodule in a consumer project:**

```bash
cd my-project
git submodule update --remote .dev-agent-rules
git add .dev-agent-rules && git commit -m "Update dev-agent-rules"
```

## Extending

### Add a skill

Drop a folder in `skills/` with a `SKILL.md` file. See the `writing-skills` skill for guidance.

### Add an agent

Drop a `.md` file in `agents/` with Claude Code subagent frontmatter:

```yaml
---
name: my-agent
description: When to use this agent and example triggers.
model: inherit
---
```

### Add a rule

Drop a `.md` file in `rules/` with frontmatter:

```yaml
---
description: What this rule enforces.
alwaysApply: true
---
```

### What not to edit

Files in skill directories with a `.subtree-source` file are synced from upstream and will be overwritten by `update.sh`. Commands listed in `ECC_COMMANDS` in `update.sh` are also upstream-synced.

Everything else — agents, hooks, rules, custom skills, custom commands — is safe to edit.

## Sources

Curated from the best community projects:

- **[obra/superpowers](https://github.com/obra/superpowers)** (MIT) — The autonomous dev workflow. 14 skills.
- **[anthropics/skills](https://github.com/anthropics/skills)** (Apache 2.0) — Official Claude skills. 9 skills.
- **[affaan-m/everything-claude-code](https://github.com/affaan-m/everything-claude-code)** (MIT) — Community skills and commands. 6 skills, 5 commands.
- **[nitayk/ai-coding-rules](https://github.com/nitayk/ai-coding-rules)** (MIT) — Agents, hooks, and workflow skills. 4 skills, 4 agents, 2 hooks.

Full attribution in [SOURCES.md](SOURCES.md).

## License

MIT. Upstream components retain their original licenses (MIT / Apache 2.0).
