#!/usr/bin/env bash
# update.sh — Pull latest skills and commands from upstream sources into dev-agent-rules
# Run this inside the dev-agent-rules repo to refresh from obra/superpowers,
# anthropics/skills, affaan-m/everything-claude-code, and nitayk/ai-coding-rules,
# then commit and push.
#
# Usage: bash update.sh [--dry-run] [skill-or-command-name]
#   No args: update all skills and commands
#   With arg: update only the named item (e.g. bash update.sh tdd-workflow)
#   --dry-run: clone upstream repos but only show diffs, don't copy files

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SKILLS_DIR="$SCRIPT_DIR/skills"
COMMANDS_DIR="$SCRIPT_DIR/commands"

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
  token-budget-advisor
  prd-generation
  fix-issue
  code-review-excellence
  best-practices-enforcement
)

# affaan-m/everything-claude-code: commands live in commands/<name>.md
ECC_COMMANDS=(
  code-review
  build-fix
  plan
  prp-commit
  prp-pr
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
    if [ "$DRY_RUN" = true ]; then
      echo "  [dry-run] $skill:"
      diff -r "$SKILLS_DIR/$skill/" "$src/" 2>/dev/null || true
    else
      rsync -a --delete "$src/" "$SKILLS_DIR/$skill/"
      echo "  ✓ $skill"
    fi
  done

  rm -rf "$tmp"
}

# Parse flags
DRY_RUN=false
FILTER=""
for arg in "$@"; do
  case "$arg" in
    --dry-run) DRY_RUN=true ;;
    *) FILTER="$arg" ;;
  esac
done

filter_list() {
  if [ -n "$FILTER" ]; then
    eval "$1=(\"\$FILTER\")"
  fi
}

filter_list OBRA_SKILLS
filter_list ANTHROPIC_SKILLS
filter_list ECC_SKILLS
filter_list ECC_COMMANDS
if [ ${#OBRA_SKILLS[@]} -gt 0 ]; then
  echo ""
  echo "=== obra/superpowers (skills) ==="
  update_skills_from_repo "$OBRA_REPO" "skills" "${OBRA_SKILLS[@]}"
fi

if [ ${#ANTHROPIC_SKILLS[@]} -gt 0 ]; then
  echo ""
  echo "=== anthropics/skills ==="
  update_skills_from_repo "$ANTHROPIC_REPO" "." "${ANTHROPIC_SKILLS[@]}"
fi


if [ ${#ECC_SKILLS[@]} -gt 0 ] || [ ${#ECC_COMMANDS[@]} -gt 0 ]; then
  echo ""
  echo "=== affaan-m/everything-claude-code ==="
  # Clone once, update both skills and commands
  tmp=$(mktemp -d)
  git clone --depth 1 "$ECC_REPO" "$tmp" -q

  if [ ${#ECC_SKILLS[@]} -gt 0 ]; then
    echo "  Skills:"
    for skill in "${ECC_SKILLS[@]}"; do
      src="$tmp/skills/$skill"
      if [ ! -d "$src" ]; then
        echo "    ⚠️  Skill not found: $skill"
        continue
      fi
      if [ "$DRY_RUN" = true ]; then
        echo "    [dry-run] $skill:"
        diff -r "$SKILLS_DIR/$skill/" "$src/" 2>/dev/null || true
      else
        rsync -a --delete "$src/" "$SKILLS_DIR/$skill/"
        echo "    ✓ $skill"
      fi
    done
  fi

  if [ ${#ECC_COMMANDS[@]} -gt 0 ]; then
    echo "  Commands:"
    mkdir -p "$COMMANDS_DIR"
    for cmd in "${ECC_COMMANDS[@]}"; do
      src="$tmp/commands/$cmd.md"
      if [ ! -f "$src" ]; then
        echo "    ⚠️  Command not found: $cmd.md"
        continue
      fi
      if [ "$DRY_RUN" = true ]; then
        echo "    [dry-run] $cmd:"
        diff "$COMMANDS_DIR/$cmd.md" "$src" 2>/dev/null || true
      else
        cp "$src" "$COMMANDS_DIR/$cmd.md"
        echo "    ✓ $cmd"
      fi
    done
  fi

  rm -rf "$tmp"
fi

echo ""
if [ "$DRY_RUN" = true ]; then
  echo "Dry run complete. No files were modified."
else
  echo "Update complete."
  echo "Review changes with: git diff --stat"
  echo "Then commit and push:"
  echo "  git add skills/ commands/ && git commit -m 'Update skills and commands from upstream' && git push"
fi
