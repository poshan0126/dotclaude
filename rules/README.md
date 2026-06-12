# Rules

Rules are modular instruction files that Claude Code loads automatically from `.claude/rules/`. They extend `CLAUDE.md` without bloating it.

- **No `paths:` frontmatter**. Loaded every session, like `CLAUDE.md`. Costs tokens every turn, so keep it tight.
- **`paths: [...]` frontmatter**. Loaded only when working with files matching the glob patterns. Free until you're near matched files.

Budget convention for always-loaded rules: under 30 lines each. Push everything that doesn't actively change Claude's behavior into a path-scoped rule, into an agent, or out entirely.

## Available rules

### code-quality.md
**Scope**: Always. ~28 lines.

Anti-defaults that counter common Claude tendencies (no premature abstraction, no scope expansion, no surrounding refactors, WHY-not-WHAT comments). Plus naming conventions, code markers (TODO, FIXME, HACK, NOTE), and file organization.

### testing.md
**Scope**: Always. ~7 lines.

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

### frontend.md
**Scope**: Path-scoped (`**/*.tsx`, `**/*.jsx`, `**/*.vue`, `**/*.svelte`, `**/*.css`, `**/*.scss`, `**/*.html`, `**/components/**`, `**/pages/**`, etc.)

Loads when touching frontend files. Design token requirements, design principle pick-list, component framework options, layout rules, accessibility (WCAG 2.1 AA), performance.

## Adding your own

Create a new `.md` file in this directory. With no frontmatter it loads every session:

```markdown
# Your Rule Name

- Your instructions here
```

Or path-scoped, so it only loads when Claude touches matching files:

```yaml
---
paths:
  - "src/your-area/**"
---

# Your Rule Name

- Instructions that only apply when touching these files
```

See [Claude Code docs](https://code.claude.com/docs/en/memory#path-specific-rules) for glob pattern syntax.
