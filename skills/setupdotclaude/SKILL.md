---
name: setupdotclaude
description: Scan the project codebase and customize all .claude/ configuration files to match. Run this after adding the .claude/ folder to a new project.
argument-hint: "[optional: focus area like 'frontend' or 'backend']"
disable-model-invocation: true
---

Scan this project's codebase and customize every `.claude/` configuration file to match the actual tech stack, conventions, and patterns in use. Confirm with the user before each change using AskUserQuestion.

CLAUDE.md must be at the project root (`./CLAUDE.md`), NOT inside `.claude/`. All other config files live inside `.claude/`.

If the project is empty or has no source code yet, tell the user the defaults will be kept as-is and stop.

## Phase 0: Clean Up Non-Config Files

Before anything else, delete files inside `.claude/` that exist for the dotclaude repo itself but waste tokens or cause issues at runtime:
- `.claude/README.md` (repo README accidentally copied in)
- `.claude/CONTRIBUTING.md` (repo contributing guide accidentally copied in)
- `.claude/.gitignore` (for the dotclaude repo, not the project — the project has its own .gitignore)
- `.claude/rules/README.md`
- `.claude/agents/README.md`
- `.claude/hooks/README.md`
- `.claude/skills/README.md`
- `.claude/hooks/tests/` (entire directory — dotclaude's own regression fixtures, not for user projects)

Also delete `.claude/CLAUDE.md` if it exists — CLAUDE.md belongs at the project root, not inside `.claude/`.

If `.github/workflows/hook-tests.yml` exists in the project root, offer to delete it — that's dotclaude's own CI for its hook fixtures, not something the user's project needs. Confirm before deleting in case the user intentionally kept it.

## Phase 1: Detect Tech Stack

Scan for package manifests, config files, and folder structure to detect: language, framework, package manager, test framework, linter/formatter, architecture pattern, and source/test directories.

Check: `package.json`, `pyproject.toml`, `Cargo.toml`, `go.mod`, `Gemfile`, `composer.json`, `build.gradle`, `pom.xml`, `Makefile`, `Dockerfile`.

Check for monorepo indicators: `workspaces` key in package.json, `pnpm-workspace.yaml`, `lerna.json`, `nx.json`, `turbo.json`, or multiple `package.json` files at depth 2+. If a monorepo is detected, ask the user which packages/apps to focus on and customize rule path patterns to include package prefixes (e.g., `packages/api/src/**` instead of `src/**`).

Detect frameworks from dependencies and config files (frontend, backend, CSS, components, ORM/DB).

Detect test framework from config files (`jest.config.*`, `vitest.config.*`, `pytest.ini`, `conftest.py`, `playwright.config.*`, etc.).

Detect linter/formatter from config files (`.eslintrc.*`, `.prettierrc.*`, `biome.json`, `ruff.toml`, `tsconfig.json`, `.editorconfig`, etc.).

Detect folder structure pattern (feature-based, layered, monorepo, MVC) and locate source, test, API, and auth directories.

Check `git log --oneline -20` for commit message style.

## Phase 2: Present Findings

Present a summary to the user using AskUserQuestion:

```
I scanned your project. Here's what I found:

**Stack**: [language] + [framework] + [CSS] + [DB]
**Package manager**: [npm/pnpm/yarn/bun/pip/cargo/go]
**Test framework**: [jest/vitest/pytest/etc.]
**Linter/Formatter**: [eslint+prettier/ruff/clippy/etc.]
**Architecture**: [layered/feature-based/monorepo/etc.]
**Source dirs**: [list]
**Test dirs**: [list]

Should I customize the .claude/ files based on this? (yes/no/corrections)
```

If the user provides corrections, incorporate them.

## Phase 3: Customize Each File

For each file below, propose the specific changes and ask the user to confirm before applying.

### 3.1 — CLAUDE.md

Replace the template commands with actual commands from the detected manifest:
- **Build**: actual build command from package.json scripts, Makefile targets, etc.
- **Test**: actual test command + how to run a single test file
- **Lint/Format**: actual lint and format commands
- **Dev**: actual dev server command
- **Architecture**: replace placeholder directories with actual project structure (only non-obvious parts)

Remove sections that don't apply (e.g., Architecture section for a single-file utility).

### 3.2 — settings.json

Update permissions to match actual commands:
- Replace `npm run` with the actual package manager (`pnpm run`, `yarn`, `bun run`, `cargo`, `go`, `make`, `python -m pytest`, etc.)
- Add project-specific allow rules for detected scripts
- Keep deny rules for secrets as-is (these are universal)

### 3.3 — rules/code-quality.md

Update naming conventions ONLY if the project's existing code uses different patterns:
- Sample 5-10 source files to detect actual naming style (camelCase vs snake_case, etc.)
- If the project uses different file naming than the template, update
- If the project's import style differs, update the import order section

If everything matches the defaults, leave it unchanged.

### 3.4 — rules/testing.md

Update if the detected test framework has specific idioms. Otherwise leave as-is (it's only 3 lines).

### 3.5 — rules/security.md

Update the `paths:` frontmatter to match actual project directories:
- Replace `src/api/**` with actual API directory paths found
- Replace `src/auth/**` with actual auth directory paths
- Replace `src/middleware/**` with actual middleware paths
- If none found, keep the defaults as reasonable guesses

### 3.5b — rules/error-handling.md

Update the `paths:` frontmatter to match actual backend directories (same paths as security.md plus service/handler directories). If the project has no backend, delete this file.

### 3.6 — rules/frontend.md

- **If no frontend files exist** (no .tsx, .jsx, .vue, .svelte, .css): delete this file entirely
- **If frontend exists**: update the Component Framework table to highlight which options the project actually uses (detected from dependencies)
- Update path patterns in frontmatter if the project uses non-standard directories

### 3.7 — hooks/format-on-save.sh

Uncomment the section matching the detected formatter:
- Prettier found → uncomment Node.js section
- Black/isort found → uncomment Python section
- Ruff found → uncomment Ruff section
- Biome found → uncomment Biome section
- rustfmt found → uncomment Rust section
- gofmt found → uncomment Go section
- Multiple languages → uncomment all relevant sections

### 3.8 — hooks/block-dangerous-commands.sh

The hook already reads `git config init.defaultBranch` at runtime and honors the `CLAUDE_PROTECTED_BRANCHES` env var (comma-separated). **Do not edit the hook's regex.**

Instead:
1. Detect the repo's default branch via `git symbolic-ref refs/remotes/origin/HEAD 2>/dev/null | sed 's@^refs/remotes/origin/@@'` (fall back to `git config init.defaultBranch`, then `main`).
2. If the detected default is `main` or `master` → nothing to do, the hook's defaults cover it.
3. If the team also protects branches like `develop` / `release/*` / `production`, tell the user how to extend protection. Offer two options:
   - **Per-project** (recommended): add `"env": { "CLAUDE_PROTECTED_BRANCHES": "main,master,develop,production" }` to `.claude/settings.json` (confirm the exact list with the user first).
   - **Per-user**: export `CLAUDE_PROTECTED_BRANCHES` in their shell profile (mention this, don't edit their shell profile).
4. Never modify `block-dangerous-commands.sh` itself — the hook is generic and test-covered; local protection lists belong in configuration, not code.

### 3.8b — hooks/auto-test.sh

Open the script and check the test-runner detection block. If the project's test runner isn't covered (custom runner, non-standard command like `pnpm -F api test`, monorepo test filtering, or a Makefile target), either:
- **Adjust the detection block** to add the detected runner, or
- **Comment out the invocation** and leave a note — running the wrong command every Edit/Write is worse than silence.

Confirm the runner command with the user before patching. If the project has no tests yet, offer to disable the hook by commenting out its entry in `settings.json` under `PostToolUse`.

### 3.8c — hooks/context-recovery.sh

Open the script. It has a placeholder `RULES` block near the top that re-injects non-negotiables after Claude Code context compaction. **This placeholder is not useful as-is — it must be customized per project.**

Propose 3–6 non-negotiables drawn from this project's detected stack and conventions:
- The most critical items from `CLAUDE.md` "Don'ts" or "Key Decisions"
- Any hard invariants (e.g. "all migrations must be reversible", "payment handlers must verify Stripe signatures", "never use `any` in TypeScript")
- Branch/PR policy if non-obvious (e.g. "default branch is `develop`, not `main`")

Show the user the proposed RULES block before writing. If the user doesn't use context compaction or can't think of non-negotiables, offer to disable the hook by removing its entry from `settings.json` under `SessionStart` (with matcher `compact`).

### 3.9 — rules/database.md

- Check if the project has a database (look for: migration directories, ORM config files like `prisma/schema.prisma`, `drizzle.config.*`, `alembic.ini`, `knexfile.*`, `sequelize` in dependencies, `typeorm` in dependencies, `ActiveRecord` patterns, `flyway`, `liquibase`)
- **If database/migrations detected**: keep the rule, update `paths:` frontmatter to match the actual migration directory paths found
- **If no database detected**: delete `rules/database.md` entirely

### 3.10 — skills/

All skills are methodology-based and project-agnostic. Leave unchanged.

### 3.11 — agents/

- **frontend-designer.md**: delete if no frontend files exist
- **doc-reviewer.md**: delete if the project has no documentation directory (no `docs/`, `doc/`, or significant `.md` files beyond README)
- **security-reviewer.md**: keep (security applies everywhere)
- **code-reviewer.md**: keep (universal)
- **performance-reviewer.md**: keep (universal)

## Phase 4: Review & Simplify

After all changes are applied, run a thorough final review pass.

Strip any remaining `> REPLACE:` placeholder blocks from `CLAUDE.md` — these are template guidance that should have been replaced with real content or removed during Phase 3.1.

Review the entire codebase alongside the customized `.claude/` configuration:
- Do the rules match how the code is actually written?
- Do the settings permissions cover the commands the project actually uses?
- Do the security rule paths match where sensitive code actually lives?
- Do the hook protections cover the files that actually need protecting in this project?
- Are there project patterns, conventions, or architectural decisions not yet captured in the config?
- Remove any redundancy introduced during customization
- Ensure no file contradicts another
- Trim any verbose instructions back to essentials
- Verify all YAML frontmatter is valid
- Verify all hook scripts referenced in settings.json exist and are executable

Present the review findings to the user. If changes are needed, confirm before applying.

## Phase 5: Summary

After everything is finalized, present a summary:

```
Setup complete. Here's what was customized:

- CLAUDE.md: updated commands for [stack]
- settings.json: permissions updated for [package manager]
- rules/security.md: paths updated to [actual dirs]
- rules/frontend.md: [kept/removed]
- hooks/format-on-save.sh: enabled [formatter]
- [any other changes]

Files left as defaults (universal, no project-specific changes needed):
- [list]

Review pass: [any issues found and fixed, or "all clean"]
```

## Rules

- NEVER write changes without user confirmation first
- NEVER delete a file without confirming — propose "remove" and explain why
- If the project is empty (no source files, no manifests), say "Project appears empty — keeping all defaults" and stop
- If detection is uncertain, ASK the user rather than guessing
- Preserve any manual edits the user has already made to .claude/ files — only update sections that need project-specific customization
- Keep it minimal — don't add complexity. If the default works, leave it alone.
