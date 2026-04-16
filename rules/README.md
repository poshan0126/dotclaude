# Rules

Rules are modular instruction files that Claude loads automatically. They extend CLAUDE.md without bloating it.

- `alwaysApply: true` — loaded every session, regardless of what files are open
- `paths: [...]` — loaded only when working with files matching the glob patterns

## Available Rules

### code-quality.md
**Scope**: Always

Principles (single-responsibility, no premature abstraction, composition over inheritance), naming conventions (files, variables, functions, constants), comment guidelines, code markers (TODO/FIXME/HACK/NOTE), and file organization (import order, export patterns, function ordering).

### testing.md
**Scope**: Always

Three focused principles: test behavior not implementation, run single test files not the full suite, fix or delete flaky tests. Comprehensive test writing is handled by the `test-writer` skill.

### security.md
**Scope**: Path-scoped (`src/api/**`, `src/auth/**`, `src/middleware/**`, `**/routes/**`, `**/controllers/**`)

Loads when touching API or auth code. Covers input validation, parameterized queries, XSS prevention, token handling, secret logging, constant-time comparison, security headers, rate limiting.

### database.md
**Scope**: Path-scoped (migration directories — `**/migrations/**`, `**/prisma/**`, `**/alembic/**`, etc.)

Loads when touching schema and migration files. Covers migration safety (reversibility, backward compatibility for one deploy cycle, NOT NULL with backfill, index creation strategy), transaction boundaries, destructive-statement guardrails, and foreign-key discipline.

### error-handling.md
**Scope**: Path-scoped (backend surfaces — handlers, controllers, services, workers)

Loads when touching server code. Covers error shape consistency, never-swallow rules, retry/backoff policies, fail-open vs fail-closed semantics, timeout discipline, and the difference between expected failures (validation) and unexpected failures (bugs — propagate).

### frontend.md
**Scope**: Path-scoped (`**/*.tsx`, `**/*.jsx`, `**/*.vue`, `**/*.svelte`, `**/*.css`, `**/*.scss`, `**/*.html`, `**/components/**`, `**/pages/**`, etc.)

Loads when touching frontend files. Design token requirements, design principles pick-list, component framework options, layout rules, accessibility (WCAG 2.1 AA), performance.

## Adding Your Own

Create a new `.md` file in this directory:

```yaml
---
alwaysApply: true
---

# Your Rule Name

- Your instructions here
```

Or path-scoped:

```yaml
---
paths:
  - "src/your-area/**"
---

# Your Rule Name

- Instructions that only apply when touching these files
```

See [Claude Code docs](https://code.claude.com/docs/en/memory#path-specific-rules) for glob pattern syntax.
