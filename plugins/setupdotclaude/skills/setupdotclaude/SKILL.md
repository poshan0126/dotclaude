---
name: setupdotclaude
description: Set up dotclaude in any project end-to-end. Bootstrap `.claude/` from the bundled template if missing, then customize every config file to match the project's actual tech stack, conventions, and patterns.
argument-hint: "[optional: focus area like 'frontend' or 'backend']"
disable-model-invocation: true
---

Set up dotclaude in this project end-to-end. If `.claude/` doesn't exist yet, bootstrap it from the template bundled inside this plugin; then customize every config file to match the actual tech stack, conventions, and patterns in use. Confirm with the user before each change using AskUserQuestion.

`CLAUDE.md` must be at the project root (`./CLAUDE.md`), NOT inside `.claude/`. All other config files live inside `.claude/`.

If the project is empty or has no source code yet, bootstrap defaults but tell the user the customization passes will be skipped until they add code.

## Phase Init: Bootstrap .claude/ if missing

Decide whether to bootstrap by checking for `.claude/settings.json`:

- If it exists: the user has already populated `.claude/` (likely via the clone+copy flow). Skip this phase entirely and go to Phase 0.
- If it does NOT exist: bootstrap from the bundled template.

When bootstrapping:

1. Use AskUserQuestion: "This project has no `.claude/` set up yet. Bootstrap it from the dotclaude template bundled in this plugin?" Options: `yes` / `no`.

2. If the user says **no**, stop with: "setupdotclaude needs dotclaude's content to operate. Either clone https://github.com/poshan0126/dotclaude and copy the files in, or re-run and choose `yes` to use the bundled template."

3. If the user says **yes**, run these Bash commands to copy the bundled template (Claude Code sets `$CLAUDE_PLUGIN_ROOT` to this plugin's installation directory):

   ```bash
   mkdir -p .claude
   cp    "$CLAUDE_PLUGIN_ROOT/template/settings.json"          .claude/
   cp -r "$CLAUDE_PLUGIN_ROOT/template/rules"                  .claude/
   cp -r "$CLAUDE_PLUGIN_ROOT/template/skills"                 .claude/
   cp -r "$CLAUDE_PLUGIN_ROOT/template/agents"                 .claude/
   cp -r "$CLAUDE_PLUGIN_ROOT/template/hooks"                  .claude/
   chmod +x .claude/hooks/*.sh
   ```

   Then handle the project-root files (don't clobber existing `CLAUDE.md`):

   ```bash
   [ -f ./CLAUDE.md ]                  || cp "$CLAUDE_PLUGIN_ROOT/template/CLAUDE.md" ./
   [ -f ./CLAUDE.local.md.example ]    || cp "$CLAUDE_PLUGIN_ROOT/template/CLAUDE.local.md.example" ./
   ```

   Then ensure `CLAUDE.local.md` is gitignored:

   ```bash
   touch .gitignore
   grep -qxF 'CLAUDE.local.md' .gitignore || echo 'CLAUDE.local.md' >> .gitignore
   ```

4. Tell the user what was placed and continue to Phase 0.

If `$CLAUDE_PLUGIN_ROOT` is unset (rare, only when this skill is run from a non-plugin location like a direct clone), tell the user to either re-install via the marketplace or follow the manual clone+copy flow at https://github.com/poshan0126/dotclaude.

## Phase 0: Clean Up Non-Config Files

Before continuing, delete files and directories inside `.claude/` that come along with a clone+copy of the dotclaude repo but don't belong in a project's `.claude/`. They waste tokens at runtime or just clutter the directory. Use Bash with `rm -rf` (or `rm -f` for files). Don't error on missing entries.

**Files** to remove from `.claude/`:
- `.claude/README.md` (repo README accidentally copied in)
- `.claude/CONTRIBUTING.md` (repo contributing guide)
- `.claude/LICENSE` (repo license)
- `.claude/CLAUDE.md` (`CLAUDE.md` belongs at the project root, not inside `.claude/`)
- `.claude/.gitignore` (for the dotclaude repo, not the project; the project has its own root `.gitignore`)
- `.claude/settings.local.json.example` (example template, not used at runtime)
- `.claude/rules/README.md`, `.claude/agents/README.md`, `.claude/hooks/README.md`, `.claude/skills/README.md` (folder descriptions for GitHub browsing only)

**Directories** to remove from `.claude/` (only exist when a user did a bulk `cp -r dotclaude/* .claude/`; they belong to the dotclaude repo, not to a consuming project):
- `.claude/.claude-plugin/` (marketplace catalog, only used for plugin distribution)
- `.claude/plugins/` (per-plugin self-contained copies, only used for plugin distribution)
- `.claude/scripts/` (repo maintenance scripts like sync-plugins.sh)

After cleanup, briefly tell the user what was removed (count of files plus directories), then continue.

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

### 3.1 CLAUDE.md (target: under 25 non-blank lines, hard cap: 50)

`CLAUDE.md` loads every turn for every developer. Aggressive trimming pays for itself fast.

Replace the template commands with actual commands from the detected manifest:
- **Build**: actual build command from package.json scripts, Makefile targets, etc.
- **Test**: actual test command plus how to run a single test file.
- **Lint/Format**: actual lint and format commands.
- **Dev**: actual dev server command.

Strip every `> REPLACE:` block. They are template guidance, not content.

For each remaining section, decide on inclusion:

| Section | Keep if... | Otherwise |
|---|---|---|
| **Architecture** | The project has at least one non-obvious structural decision (a domain split, a layering rule that contradicts the file tree). | Delete. Listing source directories is duplicative. Claude can explore. |
| **Key Decisions** | At least one decision exists where knowing the WHY would prevent a wrong fix (`auth tokens in httpOnly cookies because XSS`). | Delete. |
| **Domain Knowledge** | At least one term, abbreviation, or concept is non-obvious from the code. | Delete. |
| **Workflow** | You have project-specific workflow quirks. | Delete. Generic workflow lines duplicate `rules/code-quality.md`. |
| **Don'ts** | At least one project-specific don't (`don't modify *.gen.ts`). | Delete. Generic don'ts belong in rules. |

Most projects end up with just Commands plus three to five extra lines. That's expected. A 10-line `CLAUDE.md` is healthy.

### 3.2 settings.json

Update permissions to match actual commands:
- Replace `npm run` with the actual package manager (`pnpm run`, `yarn`, `bun run`, `cargo`, `go`, `make`, `python -m pytest`, etc.)
- Add project-specific allow rules for detected scripts
- Keep deny rules for secrets as-is (these are universal)

### 3.3 rules/code-quality.md

Update naming conventions ONLY if the project's existing code uses different patterns:
- Sample 5-10 source files to detect actual naming style (camelCase vs snake_case, etc.)
- If the project uses different file naming than the template, update
- If the project's import style differs, update the import order section

If everything matches the defaults, leave it unchanged.

### 3.4 rules/testing.md

Update if the detected test framework has specific idioms. Otherwise leave as-is (it's only a few lines).

### 3.5 rules/security.md

Update the `paths:` frontmatter to match actual project directories:
- Replace `src/api/**` with actual API directory paths found
- Replace `src/auth/**` with actual auth directory paths
- Replace `src/middleware/**` with actual middleware paths
- If none found, keep the defaults as reasonable guesses

### 3.5b rules/error-handling.md

Update the `paths:` frontmatter to match actual backend directories (same paths as security.md plus service/handler directories). If the project has no backend, delete this file.

### 3.6 rules/frontend.md

- **If no frontend files exist** (no .tsx, .jsx, .vue, .svelte, .css): delete this file entirely
- **If frontend exists**: update the Component Framework table to highlight which options the project actually uses (detected from dependencies)
- Update path patterns in frontmatter if the project uses non-standard directories

### 3.7 hooks/format-on-save.sh

Uncomment the section matching the detected formatter:
- Prettier found: uncomment Node.js section
- Black/isort found: uncomment Python section
- Ruff found: uncomment Ruff section
- Biome found: uncomment Biome section
- rustfmt found: uncomment Rust section
- gofmt found: uncomment Go section
- Multiple languages: uncomment all relevant sections

### 3.8 hooks/block-dangerous-commands.sh

Check the default branch name (`git symbolic-ref refs/remotes/origin/HEAD 2>/dev/null` or `git remote show origin`). If it's not `main` or `master`, update the regex pattern.

### 3.9 rules/database.md

- Check if the project has a database (look for: migration directories, ORM config files like `prisma/schema.prisma`, `drizzle.config.*`, `alembic.ini`, `knexfile.*`, `sequelize` in dependencies, `typeorm` in dependencies, `ActiveRecord` patterns, `flyway`, `liquibase`)
- **If database/migrations detected**: keep the rule, update `paths:` frontmatter to match the actual migration directory paths found
- **If no database detected**: delete `rules/database.md` entirely

### 3.10 skills/

All skills are methodology-based and project-agnostic. Leave unchanged by default.

If the user wants a minimal setup, list the actual contents of `.claude/skills/` (run `ls -1 .claude/skills/`) and use AskUserQuestion to ask which (if any) directories they want to delete. Delete the ones they opt out of. Otherwise keep all.

### 3.11 agents/

- **frontend-designer.md**: delete if no frontend files exist
- **doc-reviewer.md**: delete if the project has no documentation directory (no `docs/`, `doc/`, or significant `.md` files beyond README)
- **security-reviewer.md**: keep (security applies everywhere)
- **code-reviewer.md**: keep (universal)
- **performance-reviewer.md**: keep (universal)

## Phase 4: Review & Simplify

After all changes are applied, run a thorough final review pass.

### CLAUDE.md size budget (hard check)

Run this Bash to count non-blank lines in `CLAUDE.md`:

```bash
grep -cv '^[[:space:]]*$' CLAUDE.md
```

Apply the budget:

| Non-blank lines | Verdict | Action |
|---|---|---|
| Under 25 | PASS | Continue. |
| 25 to 50 | WARN | List the longest sections by line count and ask the user via AskUserQuestion which to trim. Apply trims they confirm, then continue. |
| Over 50 | FAIL | Block. Identify the top three biggest sections by line count and propose specific cuts. Do not continue Phase 4 until `CLAUDE.md` is at or under 50 non-blank lines. |

Reasons to stay tight: every line of `CLAUDE.md` loads on every turn for every developer. A 50-line file across 50 turns/day costs roughly 1,000 tokens of always-on overhead, every day, even on a one-line bugfix.

Strip any remaining `> REPLACE:` placeholder blocks. They are template guidance that should have been replaced with real content or removed during Phase 3.1.

### Codebase consistency review

Review the entire codebase alongside the customized `.claude/` configuration:
- Do the rules match how the code is actually written?
- Do the settings permissions cover the commands the project actually uses?
- Do the security rule paths match where sensitive code actually lives?
- Do the hook protections cover the files that actually need protecting in this project?
- Are there project patterns, conventions, or architectural decisions not yet captured in the config?
- Remove any redundancy introduced during customization.
- Ensure no file contradicts another.
- Trim any verbose instructions back to essentials.
- Verify all YAML frontmatter is valid.
- Verify all hook scripts referenced in settings.json exist and are executable.

Present the review findings to the user. If changes are needed, confirm before applying.

## Phase 5: Summary

After everything is finalized, count `CLAUDE.md`'s non-blank lines once more and present a summary:

```
Setup complete. Here's what was customized:

- Bootstrap: [yes, copied template into .claude/ | no, used existing .claude/]
- CLAUDE.md: [N non-blank lines]. Verdict: [PASS under 25 / WARN 25-50 / FAIL over 50]. Customized commands for [stack].
- settings.json: permissions updated for [package manager]
- rules/security.md: paths updated to [actual dirs]
- rules/frontend.md: [kept/removed]
- hooks/format-on-save.sh: enabled [formatter]
- [any other changes]

Files left as defaults (universal, no project-specific changes needed):
- [list]

Review pass: [any issues found and fixed, or "all clean"]

Tip: run `/context-budget` to see the per-turn token cost of the resulting configuration, broken down by always-loaded vs path-scoped vs invoked-only.
```

## Rules

- NEVER write changes without user confirmation first
- NEVER delete a file without confirming. Propose "remove" and explain why.
- If the project is empty (no source files, no manifests), bootstrap defaults and stop. Tell the user "Project appears empty. Keeping all defaults. Re-run after adding code to customize."
- If detection is uncertain, ASK the user rather than guessing
- Preserve any manual edits the user has already made to .claude/ files. Only update sections that need project-specific customization.
- Keep it minimal. If the default works, leave it alone.
