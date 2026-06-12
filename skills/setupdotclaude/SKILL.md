---
name: setupdotclaude
description: Set up dotclaude in any project. Deep-scans the codebase, interviews the user, installs only justified components, customized to the stack.
argument-hint: "[optional: focus area like 'frontend' or 'backend']"
disable-model-invocation: true
---

Set up dotclaude in this project with one governing principle: **install nothing without evidence and consent.** Every rule, hook, agent, and skill must be justified by something found in the codebase or explicitly requested by the user. When in doubt, leave it out — the user can always add more later; unused config costs tokens and trust forever.

`CLAUDE.md` must be at the project root (`./CLAUDE.md`), NOT inside `.claude/`. All other config files live inside `.claude/`.

Two modes, decided by what exists:
- **Fresh**: no `.claude/` content yet (whether the user will install from this plugin or has nothing at all).
- **Existing**: `.claude/` already has settings, rules, skills, agents, or hooks (from a clone+copy, an earlier run, or hand-rolled). Same scan and interview, but Phase 4 becomes a gap analysis: add what's missing and justified, propose removing what's unjustified, never touch user-customized content without showing the change first.

If `$ARGUMENTS` names a focus area (e.g. `frontend`), weight the scan and the proposals toward it.

## Phase 1: Deep scan (read-only — no writes of any kind in this phase)

Build an evidence table. Don't stop at manifests; read real code.

1. **Stack**: manifests (`package.json`, `pyproject.toml`, `Cargo.toml`, `go.mod`, `Gemfile`, `composer.json`, `build.gradle`, `pom.xml`, `Makefile`, `Dockerfile`) and CI workflows (`.github/workflows/`, `.gitlab-ci.yml`). Record the *actual* build/test/lint/dev commands and script names, not guesses.
2. **Monorepo**: `workspaces` key, `pnpm-workspace.yaml`, `lerna.json`, `nx.json`, `turbo.json`, or multiple manifests at depth 2+. List the packages.
3. **Source layout**: list the real source directories (`src/`, `app/`, `lib/`, `packages/*/src`, `cmd/`, `internal/`, ...). These become rule `paths:` globs later — record actual paths, never assume `src/`.
4. **Tests**: config files (`jest.config.*`, `vitest.config.*`, `pytest.ini`, `conftest.py`, `playwright.config.*`, ...), then **open 2-3 real test files**: runner, naming convention (`*.test.ts` vs `test_*.py`), test directory layout, assertion style, how much mocking they actually do.
5. **Frontend**: `.tsx`/`.jsx`/`.vue`/`.svelte` files, component directories, framework and styling approach from dependencies.
6. **Backend/API**: route/controller/handler/service directories; ORM and migration dirs (`prisma/`, `alembic/`, `migrations/`, `db/migrate/`, ...).
7. **Docs**: a `docs/` directory or substantial `.md` files beyond the README.
8. **Formatter/linter**: configs AND binaries (Biome, Prettier, Ruff, Black, rustfmt, gofmt, ESLint).
9. **Git**: default branch (`git symbolic-ref refs/remotes/origin/HEAD`), commit message style (`git log --oneline -20`), whether PRs/`gh` are part of the workflow (remote on GitHub, `gh` installed).
10. **Read 5-10 representative source files** across the main directories: naming style (camelCase vs snake_case), error-handling patterns (typed errors vs bare catch), comment density, generated-file markers (`*.gen.ts`, `*_pb2.py`, `// Code generated`).
11. **Existing AI/editor config**: `./CLAUDE.md`, `AGENTS.md`, `.cursorrules`, `.cursor/rules/`, `.github/copilot-instructions.md`, current `.claude/*`. This is content to *migrate*, never to clobber.
12. **Domain**: skim the README for domain terms, abbreviations, and architecture statements that aren't obvious from code.

If the project is empty (no source files, no manifests): say so, offer only the minimal baseline (`CLAUDE.md` template + safety hooks + settings), and stop after installing it. "Re-run after adding code to customize."

## Phase 2: Interview

Use AskUserQuestion (batch up to 4 questions per call; use `multiSelect` where choices aren't exclusive). Two rounds — enough to capture intent, not an interrogation.

**Round 1 — confirm reality.** First present a compact findings summary in text (stack, package manager, test runner, formatter, layout, git workflow, anything ambiguous). Then ask:
- "Did I read the project right?" — options: correct / mostly (I'll correct via Other) / wrong, let me describe it.
- If monorepo: "Which packages should this setup focus on?" (multiSelect of detected packages).
- "Anything the scan can't see?" — options like: generated dirs I must never touch / unusual deploy or branch constraints / domain terms worth recording / nothing special. Fold answers into the evidence table.

**Round 2 — scope and taste.**
- "Setup size?"
  - **Minimal**: `CLAUDE.md` + `settings.json` + the four safety hooks + `code-quality.md`. (Recommended for small projects or skeptics.)
  - **Standard** (recommended): Minimal + every component the evidence justifies (see Phase 3 mapping) — and nothing else.
  - **Full kit**: everything dotclaude ships, trimmed only where clearly inapplicable.
  - **Let me pick**: walk through each component group.
- "Which workflow skills do you want?" (multiSelect). Offer only the justified ones: `ship`/`pr-review` need a git/PR workflow, `fix-issue` needs a GitHub remote with `gh`, `tdd`/`test-writer` need a working test runner, `catchup`/`claude-md`/`debug-fix`/`explain`/`refactor`/`context-budget` are universal. Preselect per evidence; let the user drop any.
- "Optional hooks?" (multiSelect):
  - `format-on-save` — only offer if a formatter was detected.
  - `auto-test` — warn plainly: runs the matching test file after **every** edit; only sensible with a fast suite.
  - `notify` — OS notification when Claude needs attention. Personal taste.
  - `session-start` — injects branch + dirty state, ~5-10 tokens/session. Cheap, default on.
  - The four safety hooks (`protect-files`, `scan-secrets`, `block-dangerous-commands`, `warn-large-files`) are default-on in every size; only "Let me pick" can drop them.

## Phase 3: Install plan — the manifest

Produce a single plan table before touching anything. For every dotclaude component: **Install? | Evidence | Cost class** (always-loaded / path-scoped / invoked-only / hook—no context cost). Then a short "Not installing" list, each with a one-line reason. The plan is the contract: Phase 4 applies exactly this, nothing more.

Hard mapping rules (no exceptions without the user overriding):

| Component | Installs only if |
|---|---|
| `rules/frontend.md`, `agents/frontend-designer/` | Frontend files exist (Phase 1.5) |
| `rules/database.md` | Migrations or ORM detected (1.6), `paths:` rewritten to the real migration dirs |
| `rules/security.md`, `rules/error-handling.md` | Backend/API surfaces exist (1.6), `paths:` rewritten to the real dirs (with monorepo prefixes) |
| `rules/testing.md` | A test suite actually exists |
| `agents/doc-reviewer/` | Docs exist (1.7) |
| `agents/code-reviewer/`, `agents/silent-failure-hunter/`, `agents/security-reviewer/`, `agents/performance-reviewer/` | Standard size and up |
| `agents/pr-test-analyzer/` | A test suite actually exists (1.4), Standard size and up |
| `hooks/format-on-save.sh` | Formatter detected AND selected |
| `hooks/auto-test.sh` | Test runner detected AND explicitly selected |
| `hooks/notify.sh`, `hooks/session-start.sh` | Selected in Round 2 |
| Skills | Selected in Round 2 (only justified ones were offered) |
| `skills/setupdotclaude` itself | Skip when running from the plugin (`$CLAUDE_PLUGIN_ROOT` set) — re-runs come from the plugin. Offer only in the clone flow. |

`settings.json` is never copied verbatim: its `hooks` section must wire **only the hooks being installed**, and `permissions.allow` must list **only commands that exist in this project** (real package manager, real script names; `gh` rules only if PRs are part of the workflow). Keep the `deny` rules for secrets as-is — those are universal.

Ask one final AskUserQuestion: approve the plan / adjust (loop back) / cancel. Do not proceed without approval.

## Phase 4: Apply the plan

**Fresh mode (plugin install).** Copy each approved file individually from `$CLAUDE_PLUGIN_ROOT/template/` (the plugin bundles the full dotclaude template there). Copying per-file keeps folder READMEs and `hooks/tests/` out automatically. Example shape:

```bash
mkdir -p .claude/rules .claude/hooks .claude/agents .claude/skills
cp "$CLAUDE_PLUGIN_ROOT/template/rules/code-quality.md" .claude/rules/
cp "$CLAUDE_PLUGIN_ROOT/template/hooks/protect-files.sh" .claude/hooks/   # ...one cp per approved file
cp -r "$CLAUDE_PLUGIN_ROOT/template/skills/debug-fix" .claude/skills/     # skills copy as directories
cp -r "$CLAUDE_PLUGIN_ROOT/template/agents/code-reviewer" .claude/agents/ # agents too (one dir per agent; scanned recursively)
chmod +x .claude/hooks/*.sh
```

Project-root files (never clobber):

```bash
[ -f ./CLAUDE.md ]               || cp "$CLAUDE_PLUGIN_ROOT/template/CLAUDE.md" ./CLAUDE.md
[ -f ./CLAUDE.local.md.example ] || cp "$CLAUDE_PLUGIN_ROOT/template/CLAUDE.local.md.example" ./
touch .gitignore
grep -qxF 'CLAUDE.local.md' .gitignore || echo 'CLAUDE.local.md' >> .gitignore
```

If `$CLAUDE_PLUGIN_ROOT` is unset and there are no copied files to work with, tell the user to install via the marketplace (`/plugin install setupdotclaude@dotclaude`) or follow the clone flow at https://github.com/poshan0126/dotclaude.

**Existing/clone mode.** The user already has files. Apply the same plan as a diff:
- Add approved components that are missing.
- Propose **removing** files the plan doesn't justify (the whole-kit clone brings everything): unjustified rules/agents/skills/hooks, plus repo artifacts (`.claude/README.md`, `CONTRIBUTING.md`, `LICENSE`, `.gitignore`, `CLAUDE.template.md`, `settings.local.json.example`, folder READMEs, `.claude-plugin/`, `hooks/tests/`, `plugins/`, legacy `scripts/`). Confirm before each `rm`; list, don't surprise.
- Where a kept file differs from the shipped version, assume the user customized it: show the proposed change before applying.

**Customize while installing** (confirm each file's changes before writing):

1. **CLAUDE.md** (target <25 non-blank lines, hard cap 50): replace template commands with the real ones from Phase 1.1; strip every `> REPLACE:` block. For each remaining section keep it only if the scan produced real content for it:

| Section | Keep if... | Otherwise |
|---|---|---|
| Architecture | A non-obvious structural decision surfaced (1.3/1.12) | Delete — Claude can explore |
| Key Decisions | A WHY exists that would prevent a wrong fix | Delete |
| Domain Knowledge | Non-obvious terms surfaced (1.12 / Round 1) | Delete |
| Workflow | Project-specific quirks exist | Delete — generic lines duplicate `code-quality.md` |
| Don'ts | Project-specific don'ts exist (e.g. generated dirs from Round 1) | Delete |

   Most projects end up with Commands plus three to five lines. A 10-line `CLAUDE.md` is healthy.
2. **settings.json**: generate hooks + permissions per the plan (above).
3. **Rule `paths:`** rewritten to the directories actually found, with monorepo package prefixes when applicable.
4. **code-quality.md naming**: change only if the sampled code (1.10) genuinely differs from the defaults.
5. **block-dangerous-commands.sh**: update the protected-branch regex if the default branch isn't `main`/`master`.
6. **Migrate existing AI config** (1.11): offer to fold `.cursorrules` / `AGENTS.md` / copilot-instructions content into `CLAUDE.md` or a rule. Never delete the originals without asking.

## Phase 5: Verify, fingerprint, and report

1. **CLAUDE.md budget**: count non-blank lines (`grep -cv '^[[:space:]]*$' CLAUDE.md`). Under 25 = PASS. 25-50 = WARN: list the longest sections, ask which to trim. Over 50 = FAIL: propose specific cuts and don't finish until ≤50.
2. **Always-loaded estimate**: `CLAUDE.md` + rules without `paths:`, chars/4. Report the number; over ~1000 tokens, propose the single biggest trim.
3. **Mechanical checks**: every hook wired in `settings.json` exists and is executable; every installed file parses (YAML frontmatter, JSON); nothing was installed beyond the approved plan; no rule duplicates what a hook already enforces.
4. **Write the drift fingerprint** so the setup stays tuned over time. If `session-start.sh` was installed:

   ```bash
   [ -x .claude/hooks/session-start.sh ] && DOTCLAUDE_FINGERPRINT=1 .claude/hooks/session-start.sh > .claude/.dotclaude.json
   ```

   This records a hash of the project's manifests. From then on, the session-start hook emits a one-line "config drift" nudge whenever the manifests change (new scripts, new framework, new package manager) — the signal to re-run this skill. Commit `.claude/.dotclaude.json` so the whole team shares the baseline. If `session-start.sh` was not installed, skip and instead tell the user to re-run `/setupdotclaude` manually after stack changes.
5. **Summary**: three lists — installed (with the evidence that justified each), skipped (with reason), customized (what changed). Budget verdict. Close with the maintenance cadence: "Re-run `/setupdotclaude` when the drift nudge appears, after adding a framework or test runner, or after a big restructuring — it runs as a gap analysis on an existing setup, so re-runs are cheap and only propose deltas." Tip: run `/context-budget` for the full per-turn breakdown.

## Rules

- NEVER write or delete without confirmation. Propose, show, then apply.
- Install nothing the scan can't justify and the user didn't approve. The plan table is the contract.
- Preserve user edits. When changing a file the user may have touched, show the diff first.
- Uncertain detection → ask, don't guess.
- Empty project → minimal baseline, then stop.
- Keep it minimal. If a default works, leave it alone; if a component lacks evidence, leave it out.
