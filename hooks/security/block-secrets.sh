#!/usr/bin/env bash
# PreToolUse hook for Read — blocks access to sensitive files.
# Reads tool input JSON from stdin, checks file_path against known
# sensitive file patterns, and denies access when matched.

set -euo pipefail

input="$(cat)"

file_path="$(printf '%s' "$input" | grep -o '"file_path"[[:space:]]*:[[:space:]]*"[^"]*"' | head -1 | sed 's/.*: *"//;s/"$//')"

if [ -z "$file_path" ]; then
  exit 0
fi

basename="$(basename "$file_path")"

# Check against sensitive file patterns
case "$basename" in
  .env | .env.* | *.env)          matched=true ;;
  *.pem)                          matched=true ;;
  *.key)                          matched=true ;;
  *credentials*)                  matched=true ;;
  id_rsa | id_rsa.*)              matched=true ;;
  *.secret)                       matched=true ;;
  *.private)                      matched=true ;;
  *.p12)                          matched=true ;;
  *.pfx)                          matched=true ;;
  *.jks)                          matched=true ;;
  *.keystore)                     matched=true ;;
  *)                              matched=false ;;
esac

if [ "$matched" = true ]; then
  cat <<EOF
{
  "hookSpecificOutput": {
    "hookEventName": "PreToolUse",
    "permissionDecision": "deny",
    "permissionDecisionReason": "Access to sensitive file blocked: $basename"
  }
}
EOF
  exit 0
fi

# File is not sensitive — allow by exiting silently.
exit 0
