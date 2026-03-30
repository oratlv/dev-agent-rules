# MCP Configurations

Example MCP server configurations for Claude Code.

## Usage

Copy the servers you want into your project's `.claude/settings.json` under `mcpServers`,
or into your global Claude Code settings (`~/.claude/settings.json`).

```bash
# Copy the whole file as a starting point:
cp mcp/claude-settings.json .claude/settings.json
# Then edit to keep only what you need and set your tokens.
```

## Servers

| Server | Package | Purpose | Needs token? |
|--------|---------|---------|-------------|
| `github` | `@modelcontextprotocol/server-github` | Issues, PRs, code search across repos | Yes — `GITHUB_TOKEN` |
| `context7` | `@upstash/context7-mcp` | Fetch up-to-date library documentation | No |
| `sequential-thinking` | `@modelcontextprotocol/server-sequential-thinking` | Structured multi-step reasoning | No |
| `fetch` | `mcp-server-fetch` (uvx) | Fetch arbitrary URLs | No |
| `playwright` | `@executeautomation/playwright-mcp-server` | Browser automation and web testing | No |

## GitHub token

Create a token at https://github.com/settings/tokens with `repo` and `read:org` scopes.

For a personal account with multiple identities, create one token per account and configure
separate MCP entries if needed (e.g. `github-personal`, `github-work`).

## Prerequisites

- `npx` — comes with Node.js
- `uvx` — comes with `uv` (`brew install uv` on macOS); needed only for `fetch`
