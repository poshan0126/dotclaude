#!/bin/bash
# Injects dynamic project context at session start.
#
# Default (minimal): branch + dirty/clean indicator. ~5-10 tokens.
# Set DOTCLAUDE_SESSION_VERBOSE=1 to also emit last commit, file count,
# staged status, stash count, and active PR info. ~30-90 tokens, plus
# a network round-trip if `gh` is installed.
#
# Drift nudge: /setupdotclaude saves a fingerprint of the project's
# manifests to .claude/.dotclaude.json (via DOTCLAUDE_FINGERPRINT=1 mode
# below). When the manifests later change, this hook appends a one-line
# nudge to re-run /setupdotclaude. Zero output when nothing drifted.

# Hash the parts of the project manifests that change Claude's config:
# package.json scripts (stable-sorted) plus other manifests wholesale.
manifest_hash() {
  {
    if command -v jq >/dev/null 2>&1 && [ -f package.json ]; then
      jq -S '.scripts // {}' package.json
    elif [ -f package.json ]; then
      cat package.json
    fi
    for f in pyproject.toml Cargo.toml go.mod Gemfile composer.json Makefile; do
      [ -f "$f" ] && cat "$f"
    done
  } 2>/dev/null | cksum | tr -d ' '
}

# Fingerprint mode: print the fingerprint JSON and exit.
# Used by /setupdotclaude: DOTCLAUDE_FINGERPRINT=1 session-start.sh > .claude/.dotclaude.json
if [ "${DOTCLAUDE_FINGERPRINT:-0}" = "1" ]; then
  printf '{"setup_date":"%s","manifest_hash":"%s"}\n' "$(date +%Y-%m-%d)" "$(manifest_hash)"
  exit 0
fi

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

# Config drift nudge (one short line, only when manifests changed since setup).
META="${DOTCLAUDE_META:-.claude/.dotclaude.json}"
if [ -f "$META" ]; then
  SAVED=$(grep -o '"manifest_hash"[: ]*"[^"]*"' "$META" 2>/dev/null | grep -o '"[^"]*"$' | tr -d '"')
  if [ -n "$SAVED" ] && [ "$(manifest_hash)" != "$SAVED" ]; then
    DRIFT="config drift: project manifests changed since setup. Re-run /setupdotclaude to re-tune"
    if [ -n "$CONTEXT" ]; then CONTEXT="$CONTEXT | $DRIFT"; else CONTEXT="$DRIFT"; fi
  fi
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
