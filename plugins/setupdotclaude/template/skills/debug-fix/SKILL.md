---
name: debug-fix
description: Find and fix a bug. Default is careful (reproduce, investigate, test). Add `--fast` for emergency production mode (hotfix branch, minimal change, ship a PR fast).
argument-hint: "[issue, error, or description] [optional: --fast]"
disable-model-invocation: true
allowed-tools:
  - Bash(git *)
  - Bash(gh *)
  - Bash(npm run test *)
  - Bash(npm run build)
  - Read
  - Glob
  - Grep
  - Edit
  - Write
---

Find and fix the following issue:

**Problem**: $ARGUMENTS

## Mode

Check $ARGUMENTS for `--fast`. Strip it before parsing the problem description.

- **Default**: careful debug-fix. Use when you have time to do this right.
- **--fast**: emergency hotfix. Use when production is broken and shipping speed matters more than thoroughness. Triggers a `hotfix/*` branch from production, minimal-change discipline, critical-tests-only verification, and ships a `[HOTFIX]` PR. Before committing to fast mode, briefly confirm with the user that this is genuinely emergency-grade. If not, suggest dropping `--fast`.

## Step 1: Understand

- Issue number: `gh issue view $ARGUMENTS` (or the project's issue tracker).
- Error or stack trace: parse it for file, line, error type, and call chain.
- Description: identify expected vs actual.
- URL or screenshot: examine the referenced resource.

If unclear, ask clarifying questions before proceeding.

## Step 2: Hotfix branch (--fast only)

In `--fast` mode only:

- Detect the production branch: `git symbolic-ref refs/remotes/origin/HEAD` or `git remote show origin`.
- Stash uncommitted work if needed.
- Create and switch to `hotfix/<short-description>` branched from production.
- **ASK** the user to confirm the branch name first.

In default mode, skip this. Branch creation happens in Step 7.

## Step 3: Reproduce (default only)

In `--fast` mode, skip this step. Trust the report and move to Step 5.

- Find the simplest way to trigger the issue (a test, curl, script).
- Confirm you can reproduce reliably.
- If you can't reproduce:
  - **Environment-specific?** Check env vars, OS, runtime version, database state.
  - **Intermittent?** Likely a race condition. Look for shared mutable state, timing dependencies, async ordering assumptions.
  - **Already fixed?** `git log` for recent commits mentioning the issue.

## Step 4: Investigate (default only)

In `--fast` mode, skip this and go to Step 5. Trust the report and minimize investigation depth.

Don't skip ahead to guessing:

1. Locate the symptom. Which file and line produces the wrong output?
2. Read the code path backwards. What called this? What data was passed?
3. Check git history: `git log --oneline -20 -- <file>`, `git log --all --grep="<keyword>"`.
4. Narrow scope with `git bisect` or targeted grep.
5. Form a hypothesis: "X is wrong because Y."
6. Verify the hypothesis with a targeted log or assertion.
7. If wrong, trace a different path. Don't keep guessing the same hypothesis.

## Step 5: Fix

- Make the smallest correct change.
- Don't patch symptoms. Trace back to where bad data originates and fix it there.
- Don't refactor surrounding code while fixing.
- Don't add defensive checks that mask the problem.

In `--fast` mode specifically:
- If the fix needs more than ~50 lines changed, warn the user. This may not actually be a hotfix.
- Do NOT add features, change formatting, clean up unrelated issues, or add non-essential comments.

## Step 6: Verify

**Default**:
- Write a test that reproduces the bug and now passes.
- Run related tests for regressions.
- Run lint and typecheck.
- Temporarily revert your fix and confirm the new test fails (proves the test catches the bug).

**--fast**:
- Run only tests directly relevant to the changed code, not the full suite.
- Run the build.
- If you can reproduce the original error, verify it's fixed.
- **ASK** the user if they want extra verification before shipping.

## Step 7: Wrap up or ship

**Default**:
- Create a branch if not already on one.
- Stage only the fix and test files.
- Commit: `fix: <what was wrong and why> (#number)`.

**--fast**:
- Stage only the fix files (never secrets, locks, or build output).
- Draft commit: `hotfix: <short description>`. **ASK** the user to confirm.
- Push: `git push -u origin hotfix/<description>`.
- Create a PR targeting production:
  - Title: `[HOTFIX] <description>`.
  - Body: what broke, what caused it, what this fixes.
  - Try to add the `hotfix` label: `gh pr create ... --label hotfix`. Fall back to no label on failure.
- Show the PR URL.

## Rules

- NEVER skip confirmation steps in `--fast` mode (branch name, commit message, push).
- NEVER force-push.
- NEVER commit secrets or unrelated changes.
- If the user says "skip" at any step, skip and move on.
- In `--fast` mode specifically: if the fix turns out to be complex, tell the user and suggest dropping `--fast` to use the careful path.
