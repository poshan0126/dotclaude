---
name: fix-issue
description: Take a GitHub issue from number to tested fix — read the issue and comments, reproduce, locate the cause, fix with a regression test, and prep a PR that closes it.
argument-hint: "[issue number or URL]"
disable-model-invocation: true
allowed-tools:
  - Bash(gh issue view *)
  - Bash(gh issue list *)
  - Bash(git status)
  - Bash(git diff *)
  - Bash(git log *)
  - Bash(git checkout *)
  - Bash(git branch *)
---

Work a GitHub issue end to end. `$ARGUMENTS` is the issue number or URL; if omitted, run `gh issue list --assignee @me --state open` and ask which one.

## Step 1: Understand the issue

- `gh issue view $NUMBER --comments` — read the body AND the discussion; the real spec is often in comment 7.
- Extract: expected behavior, actual behavior, reproduction steps, acceptance criteria, and any decisions already made in the thread.
- If the issue is ambiguous on something that changes the fix (which behavior is correct? which platform?), ask the user — do NOT guess and do NOT ask in the issue thread without being told to.

## Step 2: Classify and branch

- **Bug** → follow `/debug-fix` discipline: reproduce it first (failing test or manual repro), then investigate. No fix before reproduction.
- **Small feature / chore** → follow `/tdd` discipline if a test runner exists: failing test, minimum code, refactor.
- Propose a branch named `fix/issue-$NUMBER-<slug>` (or `feat/...`), matching any existing convention visible in `git branch -a`. Confirm before creating.

## Step 3: Locate and fix

- Find the code path from the symptoms: grep for the error message, the feature's entry point, or names from the issue.
- Make the smallest change that satisfies the acceptance criteria. Resist adjacent refactoring — note it for a follow-up instead.
- Every bug fix ships with a regression test that fails on the old code. If you can't write one, say why in the PR body.

## Step 4: Verify against the issue

- Re-run the reproduction from Step 1 — confirm the reported behavior is gone.
- Run the tests for the touched area, then lint/typecheck.
- Walk the acceptance criteria one by one; quote each with its status.

## Step 5: Ship it

- Hand off to `/ship` (or follow its discipline): commit message and PR body must include `Fixes #$NUMBER` so the merge auto-closes the issue.
- PR body: one-line cause, one-line fix, the regression test, and anything from the issue thread that influenced the approach.
- After the PR exists, offer to comment the PR link on the issue (`gh issue comment` — requires confirmation; it's outward-facing).

## Rules

- Never start coding before Step 1 is complete — the thread often contains a decision that invalidates the obvious fix.
- One issue per branch per PR. If the issue is really three issues, say so and fix the one that was asked.
- If reproduction is impossible (can't access the environment, missing credentials), report exactly what's missing instead of fixing blind.
