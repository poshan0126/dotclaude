---
name: plan-it
description: Read research.md and write a detailed implementation plan to plan.md. Annotation cycle with user until APPROVED. Requires research to have been run first.
argument-hint: "[what to build, change, or fix]"
disable-model-invocation: true
---

Plan the following: **$ARGUMENTS**

## Hard Constraints (every phase, no exceptions)

- **`research.md` is required.** If `$CLAUDE_PROJECT_DIR/.claude/agents/research.md` does not exist, stop immediately and tell the user to run `/research` first.
- **No code changes.** The only file you may write is `$CLAUDE_PROJECT_DIR/.claude/agents/plan.md`.
- **Read every relevant file in full** — not headers, not signatures, not the first few lines. Do not infer behavior from names alone.
- **Scope**: only files inside `$CLAUDE_PROJECT_DIR`.
- **Every `**note**` must be explicitly resolved** — incorporated, rejected with a reason, or escalated as a question. No note may be silently ignored.

---

## Mode Detection

Before doing anything else, check the state of `$CLAUDE_PROJECT_DIR/.claude/agents/plan.md`:

| State | Action |
|---|---|
| Does not exist | **Initial mode** — run Phases 1–5 |
| Exists, contains `**APPROVED**` | Stop — tell the user the plan is approved and to run `/implement` |
| Exists, contains `**note**` markers | **Revision mode** — run Phase R |
| Exists, no notes, no approval | Tell the user: "plan.md exists but has no notes and is not approved. Add `**APPROVED**` to proceed to implementation, or add `**note**` annotations for revision." |

---

## Initial Mode — Phases 1–5

### Phase 1 — Load Research

Read `$CLAUDE_PROJECT_DIR/.claude/agents/research.md` in full. Everything in the plan must be grounded in what the research established.

If the research scope does not cover the area this plan needs to change, flag it and ask the user whether to proceed with partial context or run `/research` on the missing area first.

### Phase 2 — Clarify Scope

Parse the argument:
- What is the goal?
- What is explicitly in scope?
- What is explicitly out of scope?

If the argument is ambiguous, ask before proceeding. Do not plan on assumptions.

### Phase 3 — Investigate Current State

Read every file relevant to the planned change in full. The research was broad — this reading is targeted to the specific change.

**Stack-specific things to consider:**

*TypeScript / SPFx*
- Where does this touch the webpart/extension lifecycle?
- Which PnPjs calls are involved — are they already batched?
- How does existing error handling work in the affected files?

*C# / CSOM*
- Which `ClientContext` operations are affected — will batching change?
- Is there existing async code in this area, or is it synchronous?
- What exception handling patterns are already in place?

*Rust*
- Will the change affect the `Result` type of any public functions?
- Are there ownership or lifetime constraints the change must work within?
- Does this touch any `async` code paths?

### Phase 4 — Write plan.md

Write to `$CLAUDE_PROJECT_DIR/.claude/agents/plan.md`:

```markdown
# Plan: <short title>

## Goal
<what we are building or changing, and why — grounded in research.md findings>

## Approach
<the chosen strategy and why this approach over alternatives>

## Changes

### `path/to/file.ext`
**Type**: modify / new file / delete
**What changes**: <what needs to change in this file and why — specific enough to locate, not yet line-level>

## Order of Changes
1. `file` — reason
2. `file` — depends on #1

## New Files
| File | Purpose |
|---|---|
| `path/to/new/file` | what it will contain |

*(Remove section if no new files)*

## Out of Scope
<what this plan explicitly does NOT change>

## Risks
<what could regress, edge cases, anything non-trivial>

## Open Questions
<anything unresolved — must be answered before approving>
```

### Phase 5 — Stop and Present

Summarize to the user:
- Number of files changing
- Approach in one sentence
- Any open questions

Then tell the user: *"Plan written to `.claude/agents/plan.md`. Review it — add `**note**` annotations for anything to revise, or add `**APPROVED**` when ready to move to implementation."*

**Stop. Do not proceed.**

---

## Revision Mode — Phase R

Entered when `plan.md` exists and contains `**note**` markers.

**Note format written by the user:**
```
---

**note** <description of the issue or requested change>

---
```

### R1 — Read Everything

Read `research.md` and the current `plan.md` in full. Read any project files referenced in the notes or needed to address them.

### R2 — Address Every Note

For each `**note**` marker in `plan.md`, explicitly resolve it:
- **Incorporated** — update the relevant section of the plan and remove the note marker
- **Rejected** — remove the note marker and add a `**note:rejected**` entry explaining why the change would be wrong or out of scope
- **Question** — if the note cannot be resolved without more information, ask the user before continuing

No note may remain unaddressed when writing the updated plan.

### R3 — Rewrite plan.md

Write the updated `plan.md` with all notes resolved. The plan must remain complete — do not leave gaps where notes were removed.

### R4 — Stop and Present

List every note and how it was resolved (incorporated / rejected / answered). Then tell the user: *"All notes addressed. Review the updated `.claude/agents/plan.md` — add more `**note**` annotations to continue revising, or add `**APPROVED**` when ready."*

**Stop. Do not proceed.**
