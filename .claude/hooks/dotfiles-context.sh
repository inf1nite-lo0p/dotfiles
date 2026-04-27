#!/usr/bin/env bash
# Injects user dotfile context into Claude Code via SessionStart hook.
# Stdout must be a single JSON object with hookSpecificOutput.additionalContext.

set -e

section() {
  local title="$1"
  local cmd="$2"
  local out
  out=$(eval "$cmd" 2>/dev/null) || true
  if [ -n "$out" ]; then
    printf '\n## %s\n```\n%s\n```\n' "$title" "$out"
  fi
}

CONTEXT=""
CONTEXT+=$'# User dotfiles snapshot\n'
CONTEXT+=$'These are the user\'s personal shell/git aliases and functions on this machine. Prefer these aliases when running commands the user would naturally use them for (e.g. `git s` instead of `git status -s`).\n'

CONTEXT+=$(section "Git aliases (~/.gitconfig)" "git config --global --get-regexp '^alias\\.' | sed 's/^alias\\.//'")
CONTEXT+=$(section "Shell aliases (~/.aliases)" "grep -E '^\\s*alias ' ~/.aliases 2>/dev/null")
CONTEXT+=$(section "Shell functions defined in ~/.functions (names only — read the file for bodies)" "grep -E '^\\s*(function\\s+\\w+|\\w+\\s*\\(\\))' ~/.functions 2>/dev/null | sed -E 's/\\s*\\{?\\s*$//'")

# Emit JSON safely using jq (handles all escaping).
jq -n --arg ctx "$CONTEXT" '{
  hookSpecificOutput: {
    hookEventName: "SessionStart",
    additionalContext: $ctx
  }
}'
