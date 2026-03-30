# MCP Configurations

Claude Code loads MCPs from `.mcp.json` in the project root (project-scope) and from
installed plugins (global-scope). This directory contains examples.

---

## How MCPs are loaded in Claude Code

| Source | Scope | How to configure |
|--------|-------|-----------------|
| Claude Code plugins | Global (all projects) | Install via Claude Code marketplace |
| `.mcp.json` in project root | Project-only | Add to the file, commit it |

**Already available as plugins** (no `.mcp.json` entry needed):
- `context7` — library documentation lookup
- `playwright` — browser automation

---

## Project `.mcp.json`

Copy `example.mcp.json` to your project root as `.mcp.json` and keep only what you need:

```bash
cp mcp/example.mcp.json .mcp.json
```

| Server | Auth | Purpose |
|--------|------|---------|
| `github` | GitHub Copilot (no token needed) | Issues, PRs, code search |
| `fetch` | None | Fetch arbitrary URLs |
| `sequentialthinking` | None | Structured multi-step reasoning |
| `puppeteer` | None | Browser automation (alternative to playwright) |

---

## Prerequisites

- `npx` — comes with Node.js
- `uvx` — comes with `uv` (`brew install uv` on macOS); needed for `fetch`
- GitHub Copilot — required for the `github` server via `api.githubcopilot.com/mcp/`
