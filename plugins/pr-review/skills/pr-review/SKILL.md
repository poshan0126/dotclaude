---
name: pr-review
description: Review code changes or a pull request. Delegates to specialist agents for code quality, security, performance, and documentation, in parallel.
argument-hint: "[PR number | staged | file path | omit to auto-detect]"
disable-model-invocation: true
---

Review code changes by delegating to specialist agents in parallel and synthesizing a unified report. Works with PRs, staged changes, or specific files.

## Verbosity

Check `$ARGUMENTS` for the word `verbose`. Strip it from the argument string before parsing the rest.

- **Default**: terse output. Each finding is one line (`file:line: issue (fix: hint)`). Synthesis report stays compact.
- **`verbose`**: full breakdown. Each finding gets the multi-field block (Severity, Confidence, etc.). Synthesis report uses the full template.

When dispatching reviewers in Step 3, include the word `verbose` in each `Task` call's prompt only if the user asked for it. Otherwise omit; the reviewers default to terse.

## Step 1: Determine Scope

Parse `$ARGUMENTS` to determine what to review:

- **PR number** (e.g., `123` or `#123`): fetch with `gh pr view $ARGUMENTS`. This is the full PR review path (includes PR quality checks in Step 2).
- **No argument**: try `gh pr view` to detect a PR for the current branch. If a PR exists, use it. If not, fall back to `git diff --cached` (staged), then `git diff` (unstaged).
- **`staged`**: review `git diff --cached`. If nothing staged, fall back to `git diff`.
- **File path**: review that specific file's current state.

If there are no changes to review, say so and stop.

## Step 2: PR Quality Check (PR path only)

Skip this step if reviewing staged changes or a file. Jump to Step 3.

When reviewing a PR, fetch and check:
- PR title, description/body, author, base branch, head branch
- `gh pr diff $NUMBER` for the full diff
- `gh pr checks $NUMBER` for CI status
- `gh api repos/{owner}/{repo}/pulls/$NUMBER/comments` for review comments

Review the PR itself before the code:
- **Title**: descriptive and under 72 chars?
- **Description**: explains the *why*? Includes a test plan? Flag if empty or template-only.
- **Size**: count changed files and lines. Flag if >500 lines changed (suggest splitting).
- **Base branch**: targeting the right branch?
- **CI status**: passing, failing, or pending? If failing, note which checks. Fix CI first.
- **Unresolved comments**: list open review threads with file:line and comment text.

## Step 3: Code Review (fan out to specialists in parallel)

Decide which reviewers apply by reading the diff content, not just file paths:

| Reviewer | When to include |
|---|---|
| `code-reviewer` | Always. Universal correctness pass. |
| `security-reviewer` | Auth, input handling, queries, tokens, session management, file path construction, SQL or HTML or template strings. |
| `performance-reviewer` | Endpoints, DB queries, loops over collections, caching, connection management. Skip for pure-docs, config-only, or static-asset diffs. |
| `doc-reviewer` | `.md` changes, significant docstring or JSDoc changes, API docs. |

**Dispatch all applicable reviewers in PARALLEL.** Send one message that contains one `Task` tool call per applicable reviewer (use `subagent_type` matching the reviewer name). Do NOT invoke them sequentially. Parallel dispatch cuts wall-clock time from N times the slowest review to roughly the slowest single review, with no extra token cost.

If only one reviewer applies (a pure-docs diff, for example), a single `Task` call is fine. Skip the parallel pattern when there's nothing to parallelize.

While the reviewers run, you can read the PR description, recent CI logs, or open comments to enrich the synthesis in Step 4. Don't wait idly.

## Step 4: Synthesize Report

Use the terse template by default. Use the verbose template only if the user passed `verbose`.

### Default (terse)

For PR reviews:

```
## PR Review: #[number]: [title]

[base] -> [head]. [N files, +X/-Y lines]. CI: [pass | fail: <checks>]. PR quality: [ok | issues: <list>].

### Findings ([N])
- [agent] file:line: issue (fix: hint)
- [agent] file:line: issue (fix: hint)

### Verdict
[Ready to merge | Needs changes: <one-line blocker>]
```

For non-PR reviews (staged or file):

```
## Review ([scope])

[N findings from <agents>]:
- [agent] file:line: issue (fix: hint)
- [agent] file:line: issue (fix: hint)
```

If no findings, output a single line: "No issues found across [agents]."

### Verbose (when the user passed `verbose`)

For PR reviews:

```
## PR Review: #[number]: [title]

**Author**: [author] | **Base**: [base] -> **Head**: [head] | **Changed**: [N files, +X/-Y lines]

### PR Quality
- Title: [ok / needs improvement]
- Description: [ok / missing test plan / empty]
- Size: [ok / large, consider splitting]
- CI: [passing / failing, list failures]
- Unresolved comments: [none / list]

### Code Review
#### Critical / High
- [Agent] File:Line: issue

#### Medium
- [Agent] File:Line: issue

#### Low
- [Agent] File:Line: issue

### Verdict
[Ready to merge / Needs changes, summarize blockers]
```

For non-PR reviews (staged or file):

```
## Review Summary

**Scope**: [staged changes / file path]
**Agents run**: [list]

### Critical / High
- [Agent] File:Line: issue

### Medium / Low
- [Agent] File:Line: issue

### Passed
- [areas with no issues]
```

Either way: deduplicate findings that overlap between agents. Attribute each finding to the agent that found it.
