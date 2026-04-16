# Agents

Agents are specialized Claude instances that run in **isolated context**. They don't see your conversation history or loaded rules — they only have their own system prompt and tools.

Claude delegates to agents automatically based on the task description, or you can invoke them with `@agent-name`.

## Review Philosophy — Confidence Gating

All four reviewers (`code-reviewer`, `security-reviewer`, `performance-reviewer`, `doc-reviewer`) use **confidence gating**: they report only findings they can defend with a concrete failure scenario and a fix. The threshold is Confidence ≥ 8 by default; 6–7 collapses into a single "Worth a second look" list; anything below is dropped silently.

**What this means for you:**
- A short report is the norm. "No findings at this bar" is a valid, desirable outcome.
- No style nitpicks — the linter's job.
- Every high-confidence finding names the input/state that triggers it, the observable failure, and the fix.
- Each agent carries a **calibrated exclusion list** (e.g. `console.log` in tests, missing JSDoc on internal helpers) to keep signal high.
- Each agent runs **stack-aware conditional checks** — auto-detects Supabase, Stripe, JWT, Next.js, Prisma, React, etc. from `package.json` / imports / config files, and layers on stack-specific rules when relevant.

To widen the net temporarily (hardening week, exploratory review): `@security-reviewer Report Confidence >= 6 on this PR.`

## Available Agents

### frontend-designer
Not a reviewer — it writes code. Creates distinctive, production-grade UI. Finds or creates design tokens first, picks a design principle, then builds components. Has Write/Edit tools so it actually generates files. Anti-AI-slop aesthetics built in.

### security-reviewer
Senior security review. Covers injection, broken auth, authorization, data exposure, cryptography, input validation, dependency risk. Reports only findings with a concrete exploit sentence ("An attacker who <capability> can <action> resulting in <impact>") and a fix. Stack conditionals: Supabase RLS + service-role leakage, Stripe webhook signature + idempotency, JWT `alg` pinning + claim validation.

### code-reviewer
Bugs and maintenance debt, not style. Off-by-one, null dereference, inverted conditions, race conditions, swallowed errors, misleading names. Every finding carries a "when <input/state>, this <observable result>" sentence. Stack conditionals: React/Next RSC boundaries, TS type erosion (`any`, non-null `!`), Node async pitfalls.

### performance-reviewer
Real bottlenecks, not theoretical micro-optimizations. N+1 queries, missing indexes, unbounded caches, repeated computation, blocking I/O on hot paths, unnecessary re-renders, bundle bloat, lock contention. Only flags issues with a measurable impact path. Skips findings on out-of-scope PRs (docs-only, lockfile bumps).

### doc-reviewer
Accuracy, completeness, staleness, clarity. Cross-references docs against actual source via grep/file reads. Flags stale function signatures, broken examples, missing prerequisites, undocumented error cases. Skips taste-level prose edits.

## When to Invoke Which

| Agent | Invoke when |
|---|---|
| `@security-reviewer` | PR touches auth, sessions, input handling, file I/O, SQL, external HTTP, secrets, crypto. Also before any release. |
| `@code-reviewer` | Any non-trivial PR. Skip for pure renames, lockfile bumps, generated-file changes. |
| `@performance-reviewer` | PR touches a request handler, DB query, render-hot component, or data pipeline. Skip for CLI-only or one-shot scripts. |
| `@doc-reviewer` | PR changes `README.md`, `docs/`, API docs, or public-facing docstrings. |
| `@frontend-designer` | Greenfield UI, new page/component, design overhaul. |

Agents run in isolated context — they don't see your conversation history or loaded rules, but they have codebase access through their tools.

## Adding Your Own

Create a new `.md` file in this directory:

```yaml
---
name: your-agent-name
description: When Claude should delegate to this agent
tools:
  - Read
  - Grep
  - Glob
  - Bash
---

Your agent's system prompt here.
```

See [Claude Code docs](https://code.claude.com/docs/en/sub-agents) for all frontmatter options.
