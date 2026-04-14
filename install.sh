#!/usr/bin/env bash
# install.sh — Install dev-agent-rules into a project
# Usage: run from the project root you want to install into
#   bash /path/to/dev-agent-rules/install.sh
#   OR: curl -fsSL https://raw.githubusercontent.com/oratlv/dev-agent-rules/main/install.sh | bash

set -e

REPO="https://github.com/oratlv/dev-agent-rules.git"
SUBMODULE_PATH=".dev-agent-rules"
# Symlinks are relative to symlink parent dir; hook commands are relative to project root.
# Symlinks resolve relative to their own parent, so we need to go up one level first.
SKILLS_RELATIVE="../.dev-agent-rules/skills"
COMMANDS_RELATIVE="../.dev-agent-rules/commands"
AGENTS_RELATIVE="../.dev-agent-rules/agents"
RULES_RELATIVE="../.dev-agent-rules/rules"

# Must be run from a git repo root
if ! git rev-parse --show-toplevel > /dev/null 2>&1; then
  echo "Error: must be run from within a git repository." && exit 1
fi

PROJECT_ROOT="$(git rev-parse --show-toplevel)"
cd "$PROJECT_ROOT"

# Add submodule if not already present
if [ ! -f ".gitmodules" ] || ! grep -q "\"$SUBMODULE_PATH\"" .gitmodules 2>/dev/null; then
  echo "Adding dev-agent-rules submodule at $SUBMODULE_PATH..."
  git submodule add "$REPO" "$SUBMODULE_PATH"
else
  echo "Submodule already present, ensuring it is initialized..."
  git submodule update --init "$SUBMODULE_PATH"
fi

# Create relative symlinks (machine-independent — works on any machine)
link_skills() {
  local dest="$1"
  local target="$2"
  if [ -e "$dest" ] && [ ! -L "$dest" ]; then
    echo "  ⚠️  $dest already exists and is not a symlink. Skipping."
    return
  fi
  mkdir -p "$(dirname "$dest")"
  ln -sfn "$target" "$dest"
  echo "  ✓ $dest -> $target"
}

echo "Creating symlinks..."
link_skills ".claude/skills" "$SKILLS_RELATIVE"
link_skills ".claude/commands" "$COMMANDS_RELATIVE"
link_skills ".claude/agents" "$AGENTS_RELATIVE"
link_skills ".claude/rules" "$RULES_RELATIVE"
link_skills ".cursor/skills" "$SKILLS_RELATIVE"
link_skills ".cursor/agents" "$AGENTS_RELATIVE"
link_skills ".cursor/rules" "$RULES_RELATIVE"

# Copy example MCP config if no .mcp.json exists yet
if [ ! -f ".mcp.json" ]; then
  cp "$SUBMODULE_PATH/mcp/example.mcp.json" ".mcp.json"
  echo "  ✓ .mcp.json created from example (edit to keep only what you need)"
else
  echo "  ⚠️  .mcp.json already exists. See $SUBMODULE_PATH/mcp/example.mcp.json for reference."
fi

# --- Security hooks ---
# Hook commands use paths relative to project root (not symlinks).
SETTINGS_FILE=".claude/settings.json"
HOOK_BLOCK_SECRETS=".dev-agent-rules/hooks/security/block-secrets.sh"
HOOK_SCAN_SECRETS=".dev-agent-rules/hooks/security/scan-secrets-edit.sh"

# The JSON to merge into .claude/settings.json
HOOKS_JSON=$(cat <<'ENDJSON'
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
ENDJSON
)

echo ""
echo "Configuring security hooks in $SETTINGS_FILE..."

if command -v jq > /dev/null 2>&1; then
  # Ensure settings file exists
  if [ ! -f "$SETTINGS_FILE" ]; then
    echo '{}' > "$SETTINGS_FILE"
  fi

  # Read existing settings
  EXISTING=$(cat "$SETTINGS_FILE")

  # Build the merged result using jq:
  #   - For each hook entry, check if the command path already exists in the array
  #   - Only append if it does not exist (idempotent)
  MERGED=$(echo "$EXISTING" | jq --arg cmd1 "$HOOK_BLOCK_SECRETS" --arg cmd2 "$HOOK_SCAN_SECRETS" '
    # Ensure .hooks.PreToolUse exists as an array
    .hooks //= {} | .hooks.PreToolUse //= [] |

    # Add block-secrets hook if not already present
    (if (.hooks.PreToolUse | map(select(.hooks[]?.command == $cmd1)) | length) == 0
     then .hooks.PreToolUse += [{
       "matcher": "Read",
       "hooks": [{"type": "command", "command": $cmd1}]
     }]
     else . end) |

    # Add scan-secrets-edit hook if not already present
    (if (.hooks.PreToolUse | map(select(.hooks[]?.command == $cmd2)) | length) == 0
     then .hooks.PreToolUse += [{
       "matcher": "Write|Edit",
       "hooks": [{"type": "command", "command": $cmd2}]
     }]
     else . end)
  ')

  echo "$MERGED" > "$SETTINGS_FILE"
  echo "  ✓ Security hooks configured in $SETTINGS_FILE"
else
  # jq is not available — print manual instructions
  echo "  ⚠️  jq is not installed. Cannot auto-merge security hooks."
  echo ""
  echo "  Please manually add the following to $SETTINGS_FILE:"
  echo ""
  echo "$HOOKS_JSON" | sed 's/^/    /'
  echo ""
  echo "  If the file already has a \"hooks\" object, merge the PreToolUse entries"
  echo "  into the existing array rather than replacing it."
fi

echo ""
echo "Done. To commit:"
echo "  git add .gitmodules $SUBMODULE_PATH .claude/ .cursor/ .mcp.json"
echo "  git commit -m 'Add dev-agent-rules skills module'"
echo ""
echo "To update skills in the future:"
echo "  git submodule update --remote $SUBMODULE_PATH"
echo "  git add $SUBMODULE_PATH && git commit -m 'Update dev-agent-rules'"
