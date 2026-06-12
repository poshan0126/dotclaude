# Agents

Agents are specialized Claude instances that run in **isolated context**. They don't see your conversation history or loaded rules. They only have their own system prompt and tools.

Claude delegates to agents automatically based on the task description, or you can invoke them with `@agent-name`.

## Available agents

Listed core-first: the first three run on virtually every code review; the rest activate when their subject matter appears in the diff.

### code-reviewer
General code review with specific bug patterns to catch: off-by-one errors, null dereferences, inverted conditions, race conditions, swallowed errors, misleading names, excessive complexity. Includes concrete examples for each category. Skips style nitpicks.

### silent-failure-hunter
Hunts the one bug class worse than a crash: code that fails without telling anyone. Empty catch blocks, errors masked as success, fallback values that hide breakage, floating promises, retries that never surface their final failure. For each error path it asks: if this fails in production, who finds out?

### pr-test-analyzer
Judges whether a diff's tests actually verify the change — test critique, not test generation (that's the `test-writer` skill). Catches assertion-free tests, mock theater, tests that can't fail, snapshot-only coverage of logic changes, and assertions weakened to make tests pass. Core question: if the implementation were wrong, would any test go red?

### security-reviewer
Reviews code for OWASP-style vulnerabilities: injection, broken auth, data exposure, weak crypto, missing validation. Reports findings by severity with exact file:line locations and specific fixes.

### performance-reviewer
Finds real bottlenecks, not theoretical micro-optimizations. Covers database (N+1, missing indexes), memory (leaks, unbounded caches), computation (repeated work, blocking calls), network (sequential calls, missing timeouts), frontend (re-renders, bundle size), and concurrency (lock contention, missing pooling).

### doc-reviewer
Reviews documentation for accuracy (do docs match code?), completeness (are required params documented?), staleness (do referenced APIs still exist?), and clarity. Cross-references with actual source code using grep and file reads.

### frontend-designer
Creates distinctive, production-grade UI. Finds or creates design tokens first, picks a design principle, states its plan, then builds components. Has Write and Edit tools so it actually generates files. Anti-AI-slop aesthetics built in.

## Adding your own

Create a directory per agent — `agents/<name>/<name>.md` (Claude Code scans agents directories recursively; one dir per agent is what lets the plugin marketplace symlink each agent individually):

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
