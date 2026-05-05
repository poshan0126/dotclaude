# Rules

Rules are modular instruction files that Claude loads automatically. They extend `CLAUDE.md` without bloating it.

- `alwaysApply: true`. Loaded every session, regardless of what files are open. Costs tokens every turn, so keep it tight.
- `paths: [...]`. Loaded only when working with files matching the glob patterns. Free until you're near matched files.

Budget convention for `alwaysApply` rules: under 30 lines each. Push everything that doesn't actively change Claude's behavior into a path-scoped rule, into an agent, or out entirely.

## Available rules

### code-quality.md
**Scope**: Always. ~22 lines.

Anti-defaults that counter common Claude tendencies (no premature abstraction, no scope expansion, no surrounding refactors, WHY-not-WHAT comments). Plus naming conventions, code markers (TODO, FIXME, HACK, NOTE), and file organization.

### testing.md
**Scope**: Always. ~10 lines.

Six terse principles: verify behavior, run the specific test file, fix or delete flaky tests, prefer real implementations, one assertion per test, no empty assertions. Comprehensive test writing is handled by the `test-writer` skill.

### security.md
**Scope**: Path-scoped (`src/api/**`, `src/auth/**`, `src/middleware/**`, `**/routes/**`, `**/controllers/**`)

Loads when touching API or auth code. Input validation, parameterized queries, XSS prevention, token handling, secret logging, constant-time comparison, security headers, rate limiting.

### error-handling.md
**Scope**: Path-scoped (`src/api/**`, `src/services/**`, `**/controllers/**`, `**/routes/**`, `**/handlers/**`)

Loads near backend code. Typed error classes, no swallowing, no floating promises, consistent HTTP error shapes, no stack-trace leaks, retry policy.

### database.md
**Scope**: Path-scoped (migration directories across Prisma, Drizzle, Knex, Sequelize, TypeORM, Alembic, Flyway, Liquibase)

Loads near migrations. Never modify existing migrations, reversibility, test both directions, no raw SQL when an ORM method exists, never seed production data in migrations.

### database.md
**Scope**: Path-scoped (migration directories. `**/migrations/**`, `**/prisma/**`, `**/alembic/**`, etc.)

Loads when touching schema and migration files. Covers migration safety (reversibility, backward compatibility for one deploy cycle, NOT NULL with backfill, index creation strategy), transaction boundaries, destructive-statement guardrails, and foreign-key discipline.

### error-handling.md
**Scope**: Path-scoped (backend surfaces. Handlers, controllers, services, workers)

Loads when touching server code. Covers error shape consistency, never-swallow rules, retry/backoff policies, fail-open vs fail-closed semantics, timeout discipline, and the difference between expected failures (validation) and unexpected failures (bugs. Propagate).

### frontend.md
**Scope**: Path-scoped (`**/*.tsx`, `**/*.jsx`, `**/*.vue`, `**/*.svelte`, `**/*.css`, `**/*.scss`, `**/*.html`, `**/components/**`, `**/pages/**`, etc.)

Loads when touching frontend files. Design token requirements, design principle pick-list, component framework options, layout rules, accessibility (WCAG 2.1 AA), performance.

## Adding your own

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
