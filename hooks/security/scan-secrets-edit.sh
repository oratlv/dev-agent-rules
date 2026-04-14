#!/usr/bin/env bash
# PreToolUse hook for Write|Edit — scans content for secret-like patterns.
# Reads tool input JSON from stdin, extracts the content being written
# (content for Write, new_string for Edit), and prompts the user for
# confirmation if anything looks like a secret.

set -euo pipefail

input="$(cat)"

# Extract the content to scan. For Write the field is "content";
# for Edit the field is "new_string". We check both.
# Uses jq for reliable multiline JSON extraction.
content=""

if command -v jq > /dev/null 2>&1; then
  content="$(printf '%s' "$input" | jq -r '.content // .new_string // ""' 2>/dev/null)" || true
else
  # Fallback: grep-based extraction (single-line only)
  content="$(printf '%s' "$input" | grep -o '"content"[[:space:]]*:[[:space:]]*"[^"]*"' | head -1 | sed 's/.*: *"//;s/"$//')" || true
  if [ -z "$content" ]; then
    content="$(printf '%s' "$input" | grep -o '"new_string"[[:space:]]*:[[:space:]]*"[^"]*"' | head -1 | sed 's/.*: *"//;s/"$//')" || true
  fi
fi

if [ -z "$content" ]; then
  exit 0
fi

# Patterns that indicate secrets in content
secret_detected=false

# AWS access key IDs (AKIA...)
if printf '%s' "$content" | grep -qE 'AKIA[0-9A-Z]{16}'; then
  secret_detected=true
fi

# AWS secret access keys (40-char base64)
if [ "$secret_detected" = false ] && printf '%s' "$content" | grep -qE '[0-9a-zA-Z/+]{40}'; then
  # Only flag if it appears near an AWS-related keyword to reduce false positives
  if printf '%s' "$content" | grep -qiE 'aws_secret|secret_access_key'; then
    secret_detected=true
  fi
fi

# Generic API key patterns: key = "...", api_key = "...", token = "...", secret = "..."
if [ "$secret_detected" = false ] && printf '%s' "$content" | grep -qiE '(api_key|api_secret|apikey|secret_key|access_token|auth_token|private_key|client_secret)[[:space:]]*[=:][[:space:]]*["'"'"'][A-Za-z0-9_.+/=-]{8,}'; then
  secret_detected=true
fi

# Private key headers (PEM)
if [ "$secret_detected" = false ] && printf '%s' "$content" | grep -qF 'BEGIN RSA PRIVATE KEY'; then
  secret_detected=true
fi

if [ "$secret_detected" = false ] && printf '%s' "$content" | grep -qF 'BEGIN PRIVATE KEY'; then
  secret_detected=true
fi

if [ "$secret_detected" = false ] && printf '%s' "$content" | grep -qF 'BEGIN EC PRIVATE KEY'; then
  secret_detected=true
fi

if [ "$secret_detected" = false ] && printf '%s' "$content" | grep -qF 'BEGIN OPENSSH PRIVATE KEY'; then
  secret_detected=true
fi

# GitHub tokens (ghp_, gho_, ghu_, ghs_, ghr_)
if [ "$secret_detected" = false ] && printf '%s' "$content" | grep -qE 'gh[pousr]_[A-Za-z0-9_]{36,}'; then
  secret_detected=true
fi

# Generic bearer tokens
if [ "$secret_detected" = false ] && printf '%s' "$content" | grep -qiE 'Bearer [A-Za-z0-9_.+/=-]{20,}'; then
  secret_detected=true
fi

# Slack tokens (xoxb-, xoxp-, xoxs-)
if [ "$secret_detected" = false ] && printf '%s' "$content" | grep -qE 'xox[bps]-[0-9A-Za-z-]{10,}'; then
  secret_detected=true
fi

# Password assignments: password = "..."
if [ "$secret_detected" = false ] && printf '%s' "$content" | grep -qiE '(password|passwd|pwd)[[:space:]]*[=:][[:space:]]*["'"'"'][^"'"'"']{4,}'; then
  secret_detected=true
fi

if [ "$secret_detected" = true ]; then
  cat <<EOF
{
  "hookSpecificOutput": {
    "hookEventName": "PreToolUse",
    "permissionDecision": "ask",
    "permissionDecisionReason": "Warning: this file may contain secrets. Confirm you want to write it."
  }
}
EOF
  exit 0
fi

# No secrets detected — allow by exiting silently.
exit 0
