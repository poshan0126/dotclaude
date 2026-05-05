#!/bin/bash
# Injects dynamic project context at session start.
#
# Default (minimal): branch + dirty/clean indicator. ~5-10 tokens.
# Set DOTCLAUDE_SESSION_VERBOSE=1 to also emit last commit, file count,
# staged status, stash count, and active PR info. ~30-90 tokens, plus
# a network round-trip if `gh` is installed.

# Bail early if not in a git repo (nothing useful to inject).
git rev-parse --git-dir >/dev/null 2>&1 || exit 0

VERBOSE="${DOTCLAUDE_SESSION_VERBOSE:-0}"
CONTEXT=""

# Branch (essential, cheap).
BRANCH=$(git branch --show-current 2>/dev/null)
if [ -n "$BRANCH" ]; then
  CONTEXT="Branch: $BRANCH"
else
  SHORT_SHA=$(git rev-parse --short HEAD 2>/dev/null)
  [ -n "$SHORT_SHA" ] && CONTEXT="HEAD: detached at $SHORT_SHA"
fi

# Dirty indicator (binary, ~free, very useful).
if ! git diff-index --quiet HEAD -- 2>/dev/null; then
  CONTEXT="$CONTEXT | dirty"
fi

# Verbose extras (opt-in via DOTCLAUDE_SESSION_VERBOSE=1).
if [ "$VERBOSE" = "1" ]; then
  LAST_COMMIT=$(git log --oneline -1 2>/dev/null)
  [ -n "$LAST_COMMIT" ] && CONTEXT="$CONTEXT | Last: $LAST_COMMIT"

  CHANGES=$(git status --porcelain 2>/dev/null | wc -l | tr -d ' ')
  [ "$CHANGES" -gt 0 ] 2>/dev/null && CONTEXT="$CONTEXT | $CHANGES files changed"

  if ! git diff --cached --quiet 2>/dev/null; then
    CONTEXT="$CONTEXT | staged"
  fi

  STASH_COUNT=$(git stash list 2>/dev/null | wc -l | tr -d ' ')
  [ "$STASH_COUNT" -gt 0 ] 2>/dev/null && CONTEXT="$CONTEXT | $STASH_COUNT stash(es)"

  if command -v gh >/dev/null 2>&1; then
    PR_INFO=$(gh pr view --json number,title,state --jq '"PR #\(.number): \(.title) (\(.state))"' 2>/dev/null)
    [ -n "$PR_INFO" ] && CONTEXT="$CONTEXT | $PR_INFO"
  fi
fi

[ -n "$CONTEXT" ] && echo "$CONTEXT"
exit 0
