---
name: refactor
description: Safely refactor code with test coverage as a safety net. Use `--diff` to simplify just the current working diff before committing.
argument-hint: "[file, function, or pattern | --diff]"
disable-model-invocation: true
---

Refactor `$ARGUMENTS` safely. If `$ARGUMENTS` contains `--diff`, use Diff mode below instead.

## Process

### 1. Understand the current state
- Read the code and its tests
- Identify what the code does, its callers, and its dependencies
- If there are no tests, WRITE TESTS FIRST. You need a safety net before changing anything

### 2. Plan the refactoring
- State what you're changing and why (clearer naming, reduced duplication, better structure)
- List the specific transformations (extract function, inline variable, move module, etc.)
- Check: does this change any external behavior? If yes, this isn't a refactor. Reconsider.

### 3. Make changes in small, testable steps
- One transformation at a time
- Run tests after EACH step. Not at the end
- If a test breaks, undo the last step and make a smaller change

### 4. Verify
- All existing tests pass
- Lint and typecheck pass
- The public API hasn't changed (unless that was the explicit goal)
- The code is objectively simpler. Fewer lines, fewer branches, clearer names

## Diff mode (`--diff`): simplify what you just wrote

The pre-commit polish pass. Target = the current working diff (`git diff` + `git diff --cached`; if clean, the last commit). Goal: make the diff smaller and clearer with identical behavior.

1. Read the diff. For each hunk ask: would a reviewer write this more simply?
   - Inline abstractions used once that the diff itself introduced
   - Remove dead parameters, unused returns, speculative generality ("might need it later")
   - Delete comments that restate the code, and defensive checks duplicating guarantees the codebase already makes
   - Align naming with the surrounding file's conventions
2. Touch ONLY lines in the diff (plus mechanical consequences like an import). Never expand into surrounding code — that's regular refactor mode.
3. Show the proposed simplifications, confirm, apply in small steps, run the tests for the touched files after each.
4. Report: lines before → after. If nothing to simplify, say "diff is already minimal" and stop — don't invent work.

## Rules
- If you can't run the tests, don't refactor
- Never mix refactoring with behavior changes in the same commit
- If the refactoring is large (10+ files), break it into multiple commits
