---
name: research
description: Deeply read and understand a project, feature, or system and write a validated research report
argument-hint: "[describe what to research — full project, a specific feature/system, or a bug hunt]"
disable-model-invocation: true
---

Research the following: **$ARGUMENTS**

## Hard Constraints (every phase, no exceptions)

- **Read every relevant file in full** — not headers, not signatures, not the first 20 lines. Read the actual implementation. Do not infer behavior from names alone.
- **Never modify any code or project files.** The only file you may write is `$CLAUDE_PROJECT_DIR/.claude/agents/research.md`.
- **Scope**: only files inside `$CLAUDE_PROJECT_DIR`.
- **The research.md output is a review surface** — write it so the user can read it and verify you understood the system correctly before any planning begins. Not a data dump. Structured, referenced, readable.

---

## Phase 1 — Determine Mode and Scope

Parse the argument and determine which mode applies:

| Mode | Signals in argument |
|---|---|
| **General** | "full project", "this folder", "everything", "how this works", no specific subject |
| **Feature** | names a specific system, flow, module, or feature |
| **Bug Hunt** | mentions bugs, issues, incorrect behavior, or asks to find problems |

If the mode or scope is ambiguous, ask before proceeding.

---

## Phase 2 — Discover

Identify all files relevant to the scope. Do not read them yet — build the list first.

**For General mode:**
- List all source files by directory
- Identify entry points (program start, webpart init, main modules, controllers)
- Identify config, manifest, and dependency files

**For Feature / Bug Hunt mode:**
- Start from the named system or entry point
- Trace all files touched by this flow: callers, callees, shared utilities, config, types
- Grep for the key identifiers to ensure no related files are missed
- Build a complete file list before reading any of them

---

## Phase 3 — Read Deeply

Read every file in the list from Phase 2 **in full**. For each file, understand:
- What it does and why it exists
- How it fits into the broader system
- What patterns and conventions it uses
- What it depends on and what depends on it

**Stack-specific things to look for while reading:**

*TypeScript / SPFx*
- Webpart and extension lifecycle methods (`onInit`, `render`, `onDispose`)
- How PnPjs is set up and used — `sp.setup()` location, batch operations
- `.then().catch()` chains — are errors handled or swallowed?
- How SharePoint context (`this.context`) flows through the code

*C# / CSOM*
- `ClientContext` creation, use, and disposal — is it wrapped in `using`?
- Where `ExecuteQuery` / `ExecuteQueryAsync` is called — are calls batched or scattered?
- Exception handling — is context added, or are errors swallowed?
- `async`/`await` usage — is it introduced unnecessarily, or is it pre-existing?

*Rust*
- Error propagation — `?`, `.unwrap()`, `.expect()` — where and why
- Ownership and borrowing patterns — any obvious clones or lifetime workarounds?
- `async` runtime in use, if any — how tasks are spawned and awaited
- `unsafe` blocks — are they present, and are they justified?

---

## Phase 4 — Analyze

**General mode:**
- Map the architecture: how layers / modules relate
- Identify the main data flows through the system
- Note patterns and conventions used consistently across the codebase
- Flag anything inconsistent, surprising, or worth noting

**Feature mode:**
- Trace the complete flow end-to-end with file:line references at each step
- Identify all inputs, outputs, side effects, and error paths
- Note edge cases and how (or whether) they are handled
- Flag anything that looks fragile, overly complex, or undocumented

**Bug Hunt mode:**
- Trace every code path in scope — not just the happy path
- For each path, check against the bug patterns relevant to the stack (see Phase 3)
- A path is done when you have read every branch, every error handler, and every caller
- Do not stop until no unexamined paths remain in scope
- For each bug found, record: location, evidence, how it manifests, severity

---

## Phase 5 — Write research.md

Write to `$CLAUDE_PROJECT_DIR/.claude/agents/research.md` using the template for the detected mode. Use `file:line` references throughout. Include code snippets as evidence where relevant — especially for bugs and non-obvious patterns.

---

### Template: General

```markdown
# Research: Full Project

## Overview
<what this project is, what it does, who uses it>

## Architecture
<how it is structured — layers, modules, key boundaries>

## Entry Points
<where execution begins — file:line for each>

## Key Files
| File | Purpose |
|---|---|
| `path/to/file` | what it does |

## Data Flow
<how the main data moves through the system, with file:line>

## Patterns & Conventions
<naming, error handling, async style, logging — what the codebase actually does>

## Dependencies
<external packages/libraries and what they're used for>

## Surprises / Points of Interest
<anything inconsistent, non-obvious, or worth flagging>

## Open Questions
<anything that could not be determined from reading alone>
```

---

### Template: Feature

```markdown
# Research: [Feature / System Name]

## Overview
<what this feature does and why it exists>

## Files Involved
| File | Role in this feature |
|---|---|
| `path/to/file` | what it contributes |

## Flow Walkthrough
<step-by-step trace of the full flow, with file:line at each step>

1. `file:line` — <what happens here>
2. `file:line` — <what happens here>
...

## Error Paths
<how errors are handled at each step — or where they aren't>

## Edge Cases
<inputs or states that take a different path — are they handled?>

## Patterns & Conventions
<what this feature does consistently — or inconsistently>

## Dependencies
<what this feature relies on internally and externally>

## Open Questions
<anything unclear that needs follow-up before planning>
```

---

### Template: Bug Hunt

```markdown
# Research: Bug Hunt — [System / Flow Name]

## Scope
<what was examined and what was out of scope>

## Code Paths Traced
- [ ] `file:line` — <path description> — <clean / bug found>
- [ ] `file:line` — <path description> — <clean / bug found>

## Bugs Found

### Bug N: <short title>
- **Location**: `file:line`
- **Evidence**: <code snippet or description>
- **How it manifests**: <what goes wrong and when>
- **Severity**: <critical / high / medium / low>

## Clean Paths
<paths examined with no issues found>

## Open Questions
<paths that could not be fully traced, or behavior that requires runtime verification>
```
