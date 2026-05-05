#!/bin/bash
# Blocks dangerous shell commands: push to main, force push, destructive operations.
# Used as a PreToolUse hook for Bash operations.
# Exit 2 = block the action. Exit 0 = allow.

# Requires jq for JSON parsing. Fail closed if missing
if ! command -v jq >/dev/null 2>&1; then
  echo "{\"hookSpecificOutput\":{\"hookEventName\":\"PreToolUse\",\"permissionDecision\":\"deny\",\"permissionDecisionReason\":\"jq is required for command protection hooks but is not installed.\"}}"
  exit 2
fi

INPUT=$(cat)
COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // empty')

if [ -z "$COMMAND" ]; then
  exit 0
fi

deny() {
  echo "{\"hookSpecificOutput\":{\"hookEventName\":\"PreToolUse\",\"permissionDecision\":\"deny\",\"permissionDecisionReason\":\"$1\"}}"
  exit 2
}

# ──────────────────────────────────────────────
# Git protections
# ──────────────────────────────────────────────

# Check if the command contains git push (handles chaining with &&, ;, |, subshells)
if echo "$COMMAND" | grep -qE '(^|[;&|()]+[[:space:]]*)git[[:space:]]+push'; then

  # Block push to main or master
  if echo "$COMMAND" | grep -qE 'git[[:space:]]+push.*(origin[[:space:]]+|:)(main|master)\b'; then
    deny "Blocked: cannot push directly to main/master. Use a feature branch and create a PR."
  fi

  # Block bare "git push" when on main/master
  if echo "$COMMAND" | grep -qE 'git[[:space:]]+push[[:space:]]*($|[;&|])'; then
    CURRENT_BRANCH=$(git branch --show-current 2>/dev/null)
    if [ "$CURRENT_BRANCH" = "main" ] || [ "$CURRENT_BRANCH" = "master" ]; then
      deny "Blocked: you are on $CURRENT_BRANCH. Use a feature branch and create a PR."
    fi
  fi

  # Block force push (allow --force-with-lease)
  if echo "$COMMAND" | grep -qE 'git[[:space:]]+push.*(-[a-zA-Z]*f|--force)([[:space:]]|$)' && ! echo "$COMMAND" | grep -q '\-\-force-with-lease'; then
    deny "Blocked: force push is not allowed. Use --force-with-lease if you need to overwrite remote."
  fi
fi

# ──────────────────────────────────────────────
# Destructive filesystem operations
# ──────────────────────────────────────────────

# Block rm -rf on root, home, or broad paths
if echo "$COMMAND" | grep -qE 'rm[[:space:]]+-[a-zA-Z]*r[a-zA-Z]*f[[:space:]]+(\/|~|\$HOME|\.\.\/\.\.)'; then
  deny "Blocked: recursive force-delete on root/home/parent paths. Specify a safe target directory."
fi

# Block rm -rf / or rm -rf /* or rm -rf ~
if echo "$COMMAND" | grep -qE 'rm[[:space:]]+-[a-zA-Z]*r.*[[:space:]]+(\/[[:space:]]|\/\*|\/$|~\/?\*?[[:space:]]|~\/?\*?$)'; then
  deny "Blocked: recursive delete targeting root or home directory."
fi

# ──────────────────────────────────────────────
# Dangerous database operations
# ──────────────────────────────────────────────

# Block DROP TABLE/DATABASE without safeguards
if echo "$COMMAND" | grep -qiE 'DROP[[:space:]]+(TABLE|DATABASE|SCHEMA)[[:space:]]'; then
  deny "Blocked: DROP TABLE/DATABASE/SCHEMA detected. This is destructive and irreversible. Run manually if intended."
fi

# Block DELETE FROM without WHERE
if echo "$COMMAND" | grep -qiE 'DELETE[[:space:]]+FROM[[:space:]]+[a-zA-Z_]+[[:space:]]*($|;)' && ! echo "$COMMAND" | grep -qiE 'WHERE'; then
  deny "Blocked: DELETE FROM without WHERE clause would delete all rows. Add a WHERE clause."
fi

# Block TRUNCATE TABLE
if echo "$COMMAND" | grep -qiE 'TRUNCATE[[:space:]]+TABLE'; then
  deny "Blocked: TRUNCATE TABLE detected. This is destructive and irreversible. Run manually if intended."
fi

# ──────────────────────────────────────────────
# Dangerous system commands
# ──────────────────────────────────────────────

# Block chmod 777
if echo "$COMMAND" | grep -qE 'chmod[[:space:]]+777'; then
  deny "Blocked: chmod 777 gives everyone read/write/execute. Use more restrictive permissions (e.g., 755 or 644)."
fi

# Block piping curl/wget to shell execution
if echo "$COMMAND" | grep -qE '(curl|wget)[[:space:]].*\|[[:space:]]*(bash|sh|zsh|sudo)'; then
  deny "Blocked: piping downloaded content directly to a shell is dangerous. Download first, inspect, then execute."
fi

# Block disk/partition destructive commands
if echo "$COMMAND" | grep -qE '(mkfs|dd[[:space:]]+if=|>[[:space:]]*/dev/)'; then
  deny "Blocked: destructive disk operation detected. This can cause irreversible data loss."
fi

# ──────────────────────────────────────────────
# Destructive git operations
# ──────────────────────────────────────────────

# Block git reset --hard (loses uncommitted work permanently)
if echo "$COMMAND" | grep -qE 'git[[:space:]]+reset[[:space:]]+--hard'; then
  deny "Blocked: git reset --hard discards uncommitted changes permanently. Use git stash or git reset --soft instead."
fi

# Block git clean -f (permanently deletes untracked files)
if echo "$COMMAND" | grep -qE 'git[[:space:]]+clean[[:space:]]+-[a-zA-Z]*f'; then
  deny "Blocked: git clean -f permanently deletes untracked files. Review with git clean -n first, then run manually if intended."
fi

# ──────────────────────────────────────────────
# Accidental package publishing
# ──────────────────────────────────────────────

if echo "$COMMAND" | grep -qE '(npm|yarn|pnpm|bun)[[:space:]]+publish'; then
  deny "Blocked: publishing npm packages should be done manually or via CI, not through Claude Code."
fi

if echo "$COMMAND" | grep -qE 'cargo[[:space:]]+publish'; then
  deny "Blocked: publishing crates should be done manually or via CI, not through Claude Code."
fi

if echo "$COMMAND" | grep -qE 'gem[[:space:]]+push'; then
  deny "Blocked: publishing gems should be done manually or via CI, not through Claude Code."
fi

if echo "$COMMAND" | grep -qE 'twine[[:space:]]+upload'; then
  deny "Blocked: publishing Python packages should be done manually or via CI, not through Claude Code."
fi

exit 0
