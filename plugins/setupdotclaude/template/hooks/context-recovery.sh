#!/bin/bash
# Re-injects critical project rules after context compaction.
# Used as a SessionStart hook with matcher "compact".
#
# When Claude's context window fills up, compaction summarizes the conversation
# and loses specific details. This hook restores your non-negotiable project
# rules so Claude stays aligned even after compaction.
#
# Customize the RULES section below with your project-specific requirements.

# ──────────────────────────────────────────────
# Find project root
# ──────────────────────────────────────────────

find_project_root() {
  local dir="$PWD"
  while [ "$dir" != "/" ]; do
    if [ -f "$dir/package.json" ] || [ -f "$dir/pyproject.toml" ] || [ -f "$dir/Cargo.toml" ] || [ -f "$dir/go.mod" ] || [ -d "$dir/.git" ]; then
      echo "$dir"
      return
    fi
    dir=$(dirname "$dir")
  done
  echo "$PWD"
}

ROOT=$(find_project_root)

# ──────────────────────────────────────────────
# Dynamic context (same as session-start.sh)
# ──────────────────────────────────────────────

CONTEXT=""

BRANCH=$(git branch --show-current 2>/dev/null)
if [ -n "$BRANCH" ]; then
  CONTEXT="Branch: $BRANCH"
fi

LAST_COMMIT=$(git log --oneline -1 2>/dev/null)
if [ -n "$LAST_COMMIT" ]; then
  CONTEXT="$CONTEXT | Last commit: $LAST_COMMIT"
fi

CHANGES=$(git status --porcelain 2>/dev/null | wc -l | tr -d ' ')
if [ "$CHANGES" -gt 0 ] 2>/dev/null; then
  CONTEXT="$CONTEXT | Uncommitted changes: $CHANGES files"
fi

# ──────────────────────────────────────────────
# Re-inject critical project rules
# ──────────────────────────────────────────────

cat <<'RULES'
=== CONTEXT RECOVERED AFTER COMPACTION ===

CRITICAL PROJECT RULES (restored automatically. Do not ignore):

1. TESTING
   - Run the specific test file after changes, not the full suite.
   - Tests must verify behavior, not implementation details.
   - Prefer real implementations over mocks. Only mock at system boundaries.
   - One assertion per test. Arrange-Act-Assert structure.

2. CODE QUALITY
   - Don't add features beyond what was asked.
   - No dead code or commented-out blocks.
   - Functions do one thing. No magic values.
   - Named exports over default exports.

3. WORKFLOW
   - Run typecheck after making code changes.
   - Prefer fixing root causes over workarounds.
   - Don't modify generated files (*.gen.ts, *.generated.*).
   - Don't modify lock files, .env files, or hook scripts.

4. SECURITY
   - Never commit secrets, tokens, or credentials.
   - Validate all user input at system boundaries.
   - Parameterized queries only. No string interpolation in SQL.

5. GIT
   - Don't push directly to main/master.
   - No force pushes (use --force-with-lease if needed).
   - Create feature branches for all work.

RULES

# ──────────────────────────────────────────────
# Append dynamic context
# ──────────────────────────────────────────────

if [ -n "$CONTEXT" ]; then
  echo ""
  echo "Current state: $CONTEXT"
fi

# ──────────────────────────────────────────────
# Re-read CLAUDE.md if it exists (belt and suspenders)
# ──────────────────────────────────────────────

if [ -f "$ROOT/CLAUDE.md" ]; then
  echo ""
  echo "=== CLAUDE.md (re-injected) ==="
  cat "$ROOT/CLAUDE.md"
fi

echo ""
echo "=== END CONTEXT RECOVERY ==="

exit 0