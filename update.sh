#!/usr/bin/env bash
# update.sh — Pull latest skills from upstream sources into dev-agent-rules
# Run this inside the dev-agent-rules repo to refresh skills from obra/superpowers,
# anthropics/skills, and affaan-m/everything-claude-code, then commit and push.
#
# Usage: bash update.sh [skill-name]
#   No args: update all skills
#   With arg: update only the named skill (e.g. bash update.sh tdd-workflow)

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SKILLS_DIR="$SCRIPT_DIR/skills"

OBRA_REPO="https://github.com/obra/superpowers"
ANTHROPIC_REPO="https://github.com/anthropics/skills"
ECC_REPO="https://github.com/affaan-m/everything-claude-code"

# obra/superpowers: skills live in skills/<name>/
OBRA_SKILLS=(
  brainstorming
  tdd-workflow
  systematic-debugging
  verification-before-completion
  executing-plans
  subagent-driven-development
  writing-plans
  dispatching-parallel-agents
  requesting-code-review
  receiving-code-review
  using-git-worktrees
  finishing-a-development-branch
  using-superpowers
  writing-skills
)

# affaan-m/everything-claude-code: skills live in skills/<name>/
ECC_SKILLS=(
  strategic-compact
  continuous-learning-v2
  deep-research
  prompt-optimizer
  search-first
)

# anthropics/skills: each skill lives at <name>/ in the repo root
ANTHROPIC_SKILLS=(
  docx
  pdf
  xlsx
  pptx
  mcp-builder
  skill-creator
  webapp-testing
  frontend-design
  web-artifacts-builder
)

update_skills_from_repo() {
  local repo=$1
  local src_subdir=$2   # subdirectory within the repo where skills live ("." for root)
  shift 2
  local skills=("$@")
  local tmp
  tmp=$(mktemp -d)

  echo "Cloning $repo (shallow)..."
  git clone --depth 1 "$repo" "$tmp" -q

  for skill in "${skills[@]}"; do
    local src="$tmp/$src_subdir/$skill"
    if [ ! -d "$src" ]; then
      echo "  ⚠️  Skill not found in upstream: $skill (looked at $src_subdir/$skill)"
      continue
    fi
    rsync -a --delete "$src/" "$SKILLS_DIR/$skill/"
    echo "  ✓ $skill"
  done

  rm -rf "$tmp"
}

FILTER="${1:-}"

filter_skills() {
  local -n arr=$1
  if [ -n "$FILTER" ]; then
    arr=("$FILTER")
  fi
}

filter_skills OBRA_SKILLS
filter_skills ANTHROPIC_SKILLS
filter_skills ECC_SKILLS

if [ ${#OBRA_SKILLS[@]} -gt 0 ]; then
  echo ""
  echo "=== obra/superpowers ==="
  update_skills_from_repo "$OBRA_REPO" "skills" "${OBRA_SKILLS[@]}"
fi

if [ ${#ANTHROPIC_SKILLS[@]} -gt 0 ]; then
  echo ""
  echo "=== anthropics/skills ==="
  # NOTE: Verify upstream structure. anthropics/skills has each skill at the repo root.
  update_skills_from_repo "$ANTHROPIC_REPO" "." "${ANTHROPIC_SKILLS[@]}"
fi

if [ ${#ECC_SKILLS[@]} -gt 0 ]; then
  echo ""
  echo "=== affaan-m/everything-claude-code ==="
  update_skills_from_repo "$ECC_REPO" "skills" "${ECC_SKILLS[@]}"
fi

echo ""
echo "Update complete."
echo "Review changes with: git diff --stat"
echo "Then commit and push:"
echo "  git add skills/ && git commit -m 'Update skills from upstream' && git push"
