#!/bin/bash
# Scans file content for accidental secrets before writing.
# Used as a PreToolUse hook for Edit|Write operations.
# Exit 2 = block. Exit 0 = allow.

# Requires jq for JSON parsing. Allow if missing (don't block the user)
if ! command -v jq >/dev/null 2>&1; then
  exit 0
fi

INPUT=$(cat)
TOOL_NAME=$(echo "$INPUT" | jq -r '.tool_name // empty')

# Extract the content being written
if [ "$TOOL_NAME" = "Write" ]; then
  CONTENT=$(echo "$INPUT" | jq -r '.tool_input.content // empty')
elif [ "$TOOL_NAME" = "Edit" ]; then
  CONTENT=$(echo "$INPUT" | jq -r '.tool_input.new_string // empty')
else
  exit 0
fi

if [ -z "$CONTENT" ]; then
  exit 0
fi

# --- High-confidence secret patterns ---

MATCHES=""

# AWS Access Key IDs
if echo "$CONTENT" | grep -qE 'AKIA[0-9A-Z]{16}'; then
  MATCHES="$MATCHES AWS access key (AKIA...);"
fi

# AWS Secret Access Keys (40 chars base64 after a key assignment)
if echo "$CONTENT" | grep -qiE '(aws_secret_access_key|secret_key)[[:space:]]*[=:][[:space:]]*["\x27]?[A-Za-z0-9/+=]{40}'; then
  MATCHES="$MATCHES AWS secret key;"
fi

# GitHub tokens (PAT, OAuth, App)
if echo "$CONTENT" | grep -qE '(ghp_|gho_|ghs_|ghr_|github_pat_)[a-zA-Z0-9_]{20,}'; then
  MATCHES="$MATCHES GitHub token;"
fi

# OpenAI / Stripe / Anthropic style keys (sk-...)
if echo "$CONTENT" | grep -qE 'sk-[a-zA-Z0-9]{20,}'; then
  MATCHES="$MATCHES API key (sk-...);"
fi

# Slack tokens
if echo "$CONTENT" | grep -qE 'xox[bpras]-[0-9a-zA-Z-]{10,}'; then
  MATCHES="$MATCHES Slack token;"
fi

# Private key blocks
if echo "$CONTENT" | grep -qE -- '-----BEGIN[[:space:]]+(RSA |EC |DSA |OPENSSH )?PRIVATE KEY-----'; then
  MATCHES="$MATCHES private key block;"
fi

# Connection strings with embedded credentials
if echo "$CONTENT" | grep -qE '(mongodb|postgres|mysql|redis|amqp|smtp)(\+[a-z]+)?://[^:[:space:]]+:[^@[:space:]]+@'; then
  MATCHES="$MATCHES connection string with credentials;"
fi

# Generic password/secret/token assignments with literal string values
# Matches: password = "actual_value", SECRET_KEY: 'actual_value', api_token="actual_value"
# Excludes: env var references like process.env.*, os.environ.*, ${...}, getenv(...)
if echo "$CONTENT" | grep -qiE '(password|secret|token|api_key|apikey|api_secret)[[:space:]]*[=:][[:space:]]*["\x27][^"\x27]{8,}["\x27]' && \
   ! echo "$CONTENT" | grep -qiE '(password|secret|token|api_key|apikey|api_secret)[[:space:]]*[=:][[:space:]]*["\x27]?(process\.env|os\.environ|getenv|\$\{|ENV\[|env\()'; then
  MATCHES="$MATCHES hardcoded credential;"
fi

if [ -n "$MATCHES" ]; then
  # Use "ask" not "deny". Warn the user but let them override (could be test fixtures)
  REASON="Possible secret detected in content:$MATCHES Review carefully before allowing."
  echo "{\"hookSpecificOutput\":{\"hookEventName\":\"PreToolUse\",\"permissionDecision\":\"ask\",\"permissionDecisionReason\":\"$REASON\"}}"
  exit 2
fi

exit 0
