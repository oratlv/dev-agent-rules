# Sources

Skills in this repo are sourced from two upstream projects. Do not edit skill files
that carry a `.subtree-source` marker — they will be overwritten by `update.sh`.
Add your own skills in `skills/` without a `.subtree-source` file.

---

## obra/superpowers
**Repo:** https://github.com/obra/superpowers
**License:** MIT
**Skills (14):** brainstorming, tdd-workflow, systematic-debugging, verification-before-completion,
executing-plans, subagent-driven-development, writing-plans, dispatching-parallel-agents,
requesting-code-review, receiving-code-review, using-git-worktrees, finishing-a-development-branch,
using-superpowers, writing-skills

## anthropics/skills
**Repo:** https://github.com/anthropics/skills
**License:** Apache 2.0
**Skills (9):** docx, pdf, xlsx, pptx, mcp-builder, skill-creator, webapp-testing,
frontend-design, web-artifacts-builder

---

To pull the latest from upstream:
```bash
bash update.sh             # update all skills
bash update.sh tdd-workflow  # update one skill
```
