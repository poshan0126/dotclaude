---
name: implement
description: Build a detailed todo from an approved plan.md, refine it through annotation, then implement everything without stopping.
disable-model-invocation: true
---

## Hard Constraints (every phase, no exceptions)

- **`plan.md` must exist and contain `**APPROVED**`.** If `$CLAUDE_PROJECT_DIR/.claude/agents/plan.md` does not exist or has no `**APPROVED**`, stop and tell the user to run `/plan-it` first.
- **Read every relevant file in full** — not headers, not signatures, not the first few lines. Do not infer behavior from names alone.
- **Scope**: only files inside `$CLAUDE_PROJECT_DIR`.
- **Every `**note**` must be explicitly resolved** — incorporated, rejected with a reason, or escalated as a question. No note may be silently ignored.
- **During implementation**: no unnecessary comments, no JSDoc/XML doc on internal code, no `any` or unknown types in TypeScript, no `.unwrap()` without justification in Rust. Run typecheck continuously — do not introduce new type errors.

---

## Mode Detection

Check the state of `$CLAUDE_PROJECT_DIR/.claude/agents/plan.md`:

| State | Action |
|---|---|
| Does not exist or no `**APPROVED**` | Stop — tell the user to run `/plan-it` first |
| `**APPROVED**` present, no `## Implementation Todo` section | **Todo mode** — run Phase T |
| `## Implementation Todo` exists, contains `**note**` markers | **Todo revision mode** — run Phase TR |
| `## Implementation Todo` exists, contains `**APPROVED**` | **Implementation mode** — run Phase I |
| `## Implementation Todo` exists, no notes, no second approval | Tell the user: "Todo exists but is not approved. Add `**note**` annotations to revise, or add `**APPROVED**` under the todo to begin implementation." |

---

## Todo Mode — Phase T

Entered when `plan.md` is approved but has no `## Implementation Todo` section yet.

### T1 — Read the Plan

Read `plan.md` in full. Read every file listed in the Changes section in full.

### T2 — Write the Todo

Append a `## Implementation Todo` section to `plan.md`. Do not modify anything above it.

The todo must break the plan into phases and each phase into individual, atomic tasks. A task is atomic when it touches one concern in one place and can be marked complete independently.

```markdown
## Implementation Todo

> Add `**APPROVED**` below this line when the todo is ready for implementation.

### Phase 1: <name>
- [ ] <specific task — what to do and in which file>
- [ ] <specific task>

### Phase 2: <name>
- [ ] <specific task>
- [ ] Run typecheck — verify no new errors introduced

### Phase N: Verify
- [ ] Run typecheck — full clean pass
- [ ] Run lint
- [ ] Confirm all tasks above are marked complete
```

Every phase must end with a typecheck task. The final phase is always verification.

### T3 — Stop and Present

Tell the user: *"Todo written to `.claude/agents/plan.md`. Review it — add `**note**` annotations for anything to revise, or add `**APPROVED**` under the todo header when ready to implement."*

**Stop. Do not write any code.**

---

## Todo Revision Mode — Phase TR

Entered when the todo section exists and contains `**note**` markers.

**Note format:**
```
---

**note** <description>

---
```

### TR1 — Address Every Note

For each `**note**` in the todo section:
- **Incorporated** — update the affected tasks and remove the note marker
- **Rejected** — remove the note marker and add a `**note:rejected**` entry explaining why
- **Question** — ask the user before continuing if the note cannot be resolved from the plan and codebase alone

### TR2 — Rewrite the Todo Section

Rewrite only the `## Implementation Todo` section with all notes resolved. Do not touch anything above it in `plan.md`.

### TR3 — Stop and Present

List every note and its resolution. Then tell the user: *"All notes addressed. Review the updated todo — add more `**note**` annotations to continue revising, or add `**APPROVED**` to begin implementation."*

**Stop. Do not write any code.**

---

## Implementation Mode — Phase I

Entered when the todo section exists and contains `**APPROVED**`.

### I1 — Read Everything

Read `plan.md` in full. Read every file that will be changed in full before writing a single line of code.

### I2 — Implement

Work through every task in the todo, phase by phase, in order.

**For each task:**
1. Implement the change
2. Run typecheck immediately after — fix any new errors before moving on
3. Mark the task complete in `plan.md`: `- [x]`

**Do not stop between tasks.** Do not stop between phases. Complete the entire todo without pausing unless a genuine blocker is encountered (a task is impossible as written, or a new error cannot be resolved). If blocked, describe the blocker and ask — then continue with remaining tasks while waiting.

**Code quality during implementation:**
- No unnecessary comments or section dividers
- No JSDoc or XML doc on internal/private code
- TypeScript: no `any`, no implicit `unknown` — all types must be explicit and correct
- Rust: no `.unwrap()` without a documented invariant
- C#: no empty catch blocks, no `throw ex` — use `throw` to preserve stack trace
- Honor the existing code style in every file touched — match naming, formatting, and patterns already present

**TypeScript / SPFx specifics:**
- Use `.then().catch()` — never `async`/`await`
- `.catch()` must use `LoggingService.Instance.Log` if present, otherwise the project's existing logging pattern

**C# specifics:**
- Wrap `IDisposable` in `using` / `using var`
- Batch `ExecuteQuery` calls — do not scatter them
- Prefer synchronous code unless the existing code is already async

**Rust specifics:**
- Propagate errors with `?` — not `.unwrap()` in non-test code
- No `unsafe` without justification

### I3 — Final Verify

After all tasks are marked complete:
- Run typecheck — must be clean
- Run lint
- Confirm every task in the todo is marked `- [x]`

### I4 — Report

Tell the user what was implemented, phase by phase. Flag any deviations from the plan (tasks that had to be adapted) and explain why.
