#!/usr/bin/env bash
# install.sh — Install dev-agent-rules into a project
# Usage: run from the project root you want to install into
#   bash /path/to/dev-agent-rules/install.sh
#   OR: curl -fsSL https://raw.githubusercontent.com/oratlv/dev-agent-rules/main/install.sh | bash

set -e

REPO="https://github.com/oratlv/dev-agent-rules.git"
SUBMODULE_PATH=".dev-agent-rules"
# Relative path from the symlink's parent dir (.claude/ or .cursor/) to the skills dir.
# Symlinks resolve relative to their own parent, so we need to go up one level first.
SKILLS_RELATIVE="../.dev-agent-rules/skills"

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
link_skills ".cursor/skills" "$SKILLS_RELATIVE"

echo ""
echo "Done. To commit:"
echo "  git add .gitmodules $SUBMODULE_PATH .claude/skills .cursor/skills"
echo "  git commit -m 'Add dev-agent-rules skills module'"
echo ""
echo "To update skills in the future:"
echo "  git submodule update --remote $SUBMODULE_PATH"
echo "  git add $SUBMODULE_PATH && git commit -m 'Update dev-agent-rules'"
