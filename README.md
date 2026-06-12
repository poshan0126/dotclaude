# dotclaude

A lean `.claude/` setup for daily development. Seven specialist agents, twelve workflow skills, six modular rules, and eight safety/productivity hooks. No bloat, no model assignments, no opinions you can't override.

## Get started

Two paths to the same place: a customized `.claude/` in your project. Most people should pick the marketplace path. It's faster, there's nothing to clean up afterward, and you don't have to think about where files go.

### Option 1 (recommended): install via the marketplace

Add the marketplace once on your machine, then install the all-in-one setup plugin:

```
/plugin marketplace add poshan0126/dotclaude
/plugin install setupdotclaude@dotclaude
```

Open your project in Claude Code and run:

```
/setupdotclaude
```

That's the whole flow. The `setupdotclaude` plugin carries the complete dotclaude kit (settings, rules, hooks, all agents and skills, the `CLAUDE.md` template) — but it doesn't dump it all into your project. When you run the slash command it deep-scans your codebase (manifests, real source and test files, directory layout, git workflow, existing AI configs), interviews you about scope and preferences, then proposes an install plan where every component is justified by evidence from the scan. Only the approved plan gets copied in, customized to your stack. Every change is confirmed before it's applied.

After it finishes, restart Claude Code so the new agents, skills, rules, and hooks load.

If you only want one or two pieces instead of the full kit, install them individually:

```
/plugin install code-reviewer@dotclaude
/plugin install safety-hooks@dotclaude
/plugin install ship@dotclaude
```

Full plugin list: `code-reviewer`, `silent-failure-hunter`, `pr-test-analyzer`, `security-reviewer`, `performance-reviewer`, `doc-reviewer`, `frontend-designer`, `safety-hooks`, `setupdotclaude`, `catchup`, `claude-md`, `fix-issue`, `debug-fix`, `ship`, `pr-review`, `tdd`, `explain`, `refactor`, `test-writer`, `context-budget`.

The `safety-hooks` plugin packages the four PreToolUse guards (dangerous commands, secret scanning, protected files, build artifacts) so you get deterministic guardrails without copying any files.

Plugins are semver-versioned (see each `plugins/<name>/.claude-plugin/plugin.json`); `/plugin update` picks up new releases.

### Option 2: clone the repo

Pick this if you'd rather own the files in your dotfiles repo or skip the plugin layer entirely.

```bash
git clone https://github.com/poshan0126/dotclaude.git /tmp/dotclaude

cd your-project
mkdir -p .claude

cp /tmp/dotclaude/settings.json .claude/
cp -r /tmp/dotclaude/{rules,skills,agents,hooks} .claude/
cp /tmp/dotclaude/CLAUDE.template.md ./CLAUDE.md
cp /tmp/dotclaude/CLAUDE.local.md.example ./

chmod +x .claude/hooks/*.sh
rm -rf /tmp/dotclaude

echo "CLAUDE.local.md" >> .gitignore
```

Reload Claude Code, then run `/setupdotclaude`. It's the same skill as Option 1, just operating in reverse: since you copied the whole kit, it scans your project, builds the same evidence-based plan, and proposes *removing* the pieces your project doesn't need (plus repo artifacts like folder READMEs, `.claude-plugin/`, and `hooks/tests/` if you did a bulk `cp -r`), then customizes what stays.

## Troubleshooting

| Problem | Fix |
|---------|-----|
| Skills or agents not showing up | Restart Claude Code. Everything loads at session start. |
| Hooks not running | Run `chmod +x .claude/hooks/*.sh` and verify `jq` is installed. |
| "jq not found" blocking everything | Install jq: `brew install jq` (macOS) or `apt install jq` (Linux). |
| format-on-save not formatting | Make sure the formatter binary is installed and its config file exists in the project root. |
| Permission denied on allowed commands | Check the glob in `settings.json`. `Bash(npm run test *)` matches arguments after `test`. |
| `/setupdotclaude` asks to confirm `settings.json` edits | Expected. `protect-files.sh` prompts when editing `settings.json`. Hook scripts stay hard-blocked. |

## Make it yours

`/setupdotclaude` gets you most of the way. To take it the rest of the way:

- `rules/code-quality.md`. Naming conventions to match your team's style. Comment guidelines, code marker format, import order.
- `rules/frontend.md`. Pick your design principle. Highlight the component framework your project actually uses.
- `rules/security.md`. Add paths specific to your project's sensitive areas, beyond the defaults.
- `CLAUDE.md`. Architectural decisions, domain knowledge, workflow quirks unique to your project.
- `CLAUDE.local.md`. Personal preferences (gitignored). Rename the `.example` file to start.
- `hooks/format-on-save.sh`. Auto-detects Biome, Prettier, Ruff, Black, rustfmt, and gofmt. If your formatter isn't covered, add a detection block to the script.

The defaults are foundations. Your edits on top are what make Claude effective for *your* project.

## Keep it tuned

dotclaude is built for daily iteration, so the setup is a loop, not a one-shot. When `/setupdotclaude` finishes it saves a fingerprint of your project's manifests to `.claude/.dotclaude.json` (commit it — the team shares the baseline). From then on the `session-start` hook compares fingerprints each session and emits a single line — `config drift: project manifests changed since setup` — only when your stack actually changed. Zero tokens otherwise.

When to re-run `/setupdotclaude`:

- The drift nudge appears (new scripts, framework, package manager, or build tool detected).
- You added a major area the rules should cover (first migrations, first frontend code, a new package in the monorepo).
- After a big restructuring that moved source or test directories (path-scoped rule globs go stale).

Re-runs are cheap: on an existing `.claude/` the skill runs as a gap analysis and only proposes deltas — it never re-installs the world.

## Skills (slash commands)

Skills are invoked with `/name` in your Claude Code session. All except `/test-writer` are manual only.

| Command | Arguments | Description |
|---------|-----------|-------------|
| `/setupdotclaude` | `[focus area]` | Set up dotclaude in any project. Deep-scans the codebase (manifests, real source and test files, layout, git workflow, existing AI configs), interviews you about scope, then proposes an evidence-based install plan — only approved components get copied in and customized to your stack. On an existing `.claude/`, runs as a gap analysis instead. Confirms every change before applying. |
| `/debug-fix` | `[issue #, error, or description] [--fast]` | Find and fix a bug. Default is the careful path: reproduce, investigate, write a regression test, fix, commit. Add `--fast` for emergency production mode (`hotfix/` branch from production, minimal change, critical tests only, ships a `[HOTFIX]` PR). Warns if a fast fix turns out to be complex. |
| `/ship` | `[commit message or PR title]` | Full shipping workflow. Scans changes, stages files (skipping secrets, locks, and build output), drafts a commit message in the repo's style, pushes, creates a PR, then offers to delete local branches whose remotes are gone. Every step requires confirmation. |
| `/pr-review` | `[PR #, "staged", file path, or omit]` | Delegates review to specialist agents in parallel: `@code-reviewer` and `@silent-failure-hunter` (almost always), `@pr-test-analyzer` (tests or untested behavior changes), `@security-reviewer`, `@performance-reviewer`, `@doc-reviewer` (when the diff warrants). Synthesizes a deduplicated, deconflicted, confidence-bucketed report. |
| `/fix-issue` | `[issue # or URL]` | GitHub issue to tested fix: reads the issue and its comment thread, reproduces, fixes with a regression test, verifies each acceptance criterion, preps a PR with `Fixes #N`. |
| `/catchup` | `[handoff \| focus area]` | Rebuilds context after `/clear`: reads the handoff note plus branch commits and changed files, summarizes goal/done/in-flight/next. `handoff` mode writes `.claude/HANDOFF.md` at session end. |
| `/claude-md` | `[audit?]` | Captures this session's durable learnings into `CLAUDE.md` (each confirmed, one line each), or with `audit` verifies every documented command and path still exists and enforces the line budget. |
| `/tdd` | `[feature description or function signature]` | Strict red-green-refactor TDD loop. One failing test, then minimum code to pass, then refactor. Commits after each green-plus-refactor cycle. Works simple to complex: degenerate cases, happy path, variations, edge cases, errors. |
| `/explain` | `[file, function, or concept]` | Explains code with a one-sentence summary, a mental model analogy, an ASCII diagram, key non-obvious details, and a modification guide. Focuses on the why and the landmines, not the obvious. |
| `/refactor` | `[file, function, or pattern \| --diff]` | Safe refactoring with tests as a safety net. Writes tests first if none exist, plans transformations, makes small testable steps, and verifies after each one. Never mixes refactoring with behavior changes. `--diff` simplifies only the current working diff as a pre-commit polish pass. |
| `/test-writer` | *(auto-triggers)* | Writes comprehensive tests for new or changed code. Discovers changes via `git diff`, maps all code paths (happy, edge, error, concurrency), writes one test per scenario with Arrange-Act-Assert. The only skill that can auto-trigger. Claude may invoke it after you add new features. |
| `/context-budget` | `[--api]` | Estimates per-turn token cost of this project's `.claude/` and `CLAUDE.md`. Reports always-loaded vs path-scoped vs invoked-only, ranks top contributors, flags entries over budget. Default heuristic is `chars/4`. Add `--api` for Anthropic-tokenizer exact counts (requires `$ANTHROPIC_API_KEY`). |

## Agents (subagents)

Agents are specialized Claude instances that run in their own isolated context. Auto-delegated based on the task, or you can invoke any of them explicitly with `@agent-name` in your prompt.

| Agent | When it's used | What it does |
|-------|----------------|--------------|
| `@code-reviewer` | Auto-delegated by `/pr-review`, or invoke directly | Reviews code for correctness and maintainability. Catches off-by-one errors, null dereferences, logic bugs, race conditions, error handling gaps, excessive complexity, and missing tests. Focuses on real issues with evidence, not style nitpicks. |
| `@silent-failure-hunter` | Auto-delegated by `/pr-review` on almost every code diff | Finds code that fails silently: empty catch blocks, errors masked as success, fallback values that hide breakage, floating promises, retries that never surface their final failure. Asks of every error path: if this fails in production, who finds out? |
| `@pr-test-analyzer` | Auto-delegated by `/pr-review` when tests changed or behavior changed untested | Judges whether the diff's tests actually verify the change. Catches assertion-free tests, mock theater, tests that can't fail, and assertions weakened to make tests pass. Would any test go red if the implementation were wrong? |
| `@security-reviewer` | Auto-delegated by `/pr-review` when security-related code changes | Senior security engineer doing static analysis. Covers injection (SQL, command, XSS, template, path traversal), auth and authorization flaws, data exposure, cryptography issues, dependency vulnerabilities, and input validation gaps. Reports severity, attack vector, and concrete fix for each finding. |
| `@performance-reviewer` | Auto-delegated by `/pr-review` when performance-sensitive code changes | Finds real bottlenecks, not theoretical micro-optimizations. Checks for N+1 queries, missing indexes, unbounded queries, memory leaks, repeated computation, blocking I/O on hot paths, unnecessary re-renders, bundle size issues, and lock contention. Only flags issues with measurable impact. |
| `@frontend-designer` | Auto-delegated when building UI, or invoke directly | Creates distinctive, production-grade frontend UI that avoids generic AI aesthetics. Enforces design tokens, picks an appropriate design principle (glassmorphism, brutalism, editorial, and so on), ensures accessibility (WCAG), and prevents common anti-patterns like purple gradients, centered-everything layouts, and overused fonts. |
| `@doc-reviewer` | Auto-delegated by `/pr-review` when documentation changes | Reviews docs for accuracy by cross-referencing actual source code. Verifies function signatures, code examples, config options, and file paths. Identifies stale references, missing prerequisites, undocumented error cases, and unclear instructions. |

### Using agents directly

You can invoke any agent in your prompt:

```
@security-reviewer Review the auth middleware changes in src/middleware/auth.ts
```

```
@frontend-designer Build a dashboard page for the analytics module
```

```
@code-reviewer Check my staged changes before I commit
```

Agents run in isolated context. They don't see your conversation history, but they have access to the full codebase through their allowed tools.

## Customization guide

| Want to... | Do this |
|---|---|
| Add project-specific rules | Create `.claude/rules/your-rule.md` |
| Scope rules to file paths | Add `paths:` frontmatter to rule files |
| Add a team workflow | Create `.claude/skills/your-skill/SKILL.md` |
| Add a specialist reviewer | Create `.claude/agents/your-agent.md` |
| Enforce behavior deterministically | Add a hook in `settings.json` |
| Override settings locally | Copy `settings.local.json.example` to `.claude/settings.local.json` |
| Personal CLAUDE.md overrides | Rename `CLAUDE.local.md.example` to `CLAUDE.local.md` |

### Example: project-specific rule

```yaml
---
paths:
  - "src/billing/**"
---

# Billing Module

- All monetary values use cents (integers), never floating point dollars
- Tax calculations must use the tax-engine service, never inline math
- Every billing mutation must be idempotent with a unique request ID
```

## What's inside

> The repo is flat, not nested inside `.claude/`. `CLAUDE.md` belongs at your project root and everything else goes inside `.claude/`. Both setup paths above handle the separation for you.

```
dotclaude/
├── CLAUDE.md                           # Instructions for working on this repo (not shipped)
├── CLAUDE.template.md                  # Template project instructions, lands in your project as CLAUDE.md
├── CLAUDE.local.md.example             # Personal overrides template, rename to CLAUDE.local.md
├── LICENSE                             # MIT
├── settings.json                       # Project settings, copy to .claude/
├── settings.local.json.example         # Personal settings template, copy to .claude/settings.local.json
├── .gitignore                          # Gitignore for the dotclaude repo (not for your project's .claude/)
├── .claude-plugin/                     # Marketplace catalog (only used by the plugin install path)
│   └── marketplace.json                #   20 plugin entries pointing at ./plugins/<name>
├── plugins/                            # One dir per plugin: plugin.json + symlinks into the top-level dirs
│   └── <20 plugins>/                   #   No copies — symlinks dereference to real files at install time
├── rules/                              # Modular instructions, copy to .claude/rules/
│   ├── code-quality.md                 #   Principles, naming, comments, markers, file organization (always loaded)
│   ├── testing.md                      #   Testing conventions (always loaded)
│   ├── database.md                     #   Migration safety rules (loads near migration files)
│   ├── error-handling.md               #   Error handling patterns (loads near backend files)
│   ├── security.md                     #   Security rules (loads near API and auth files)
│   └── frontend.md                     #   Design tokens, principles, accessibility (loads near UI files)
├── skills/                             # Slash commands, copy to .claude/skills/   (also published as plugins)
│   ├── setupdotclaude/SKILL.md         #   /setupdotclaude. Bootstrap and customize all config files.
│   ├── debug-fix/SKILL.md              #   /debug-fix [--fast]. Bug fix, careful by default, hotfix mode opt-in.
│   ├── ship/SKILL.md                   #   /ship. Commit, push, PR with confirmations.
│   ├── pr-review/SKILL.md              #   /pr-review. Review PR or staged changes via specialist agents.
│   ├── tdd/SKILL.md                    #   /tdd. Strict red-green-refactor TDD loop.
│   ├── explain/SKILL.md                #   /explain <file or function>.
│   ├── refactor/SKILL.md               #   /refactor <target>.
│   ├── test-writer/SKILL.md            #   Auto-triggers on new features. Comprehensive tests.
│   ├── catchup/SKILL.md                #   /catchup [handoff]. Rebuild context after /clear; write handoff notes.
│   ├── claude-md/SKILL.md              #   /claude-md [audit]. Capture session learnings; keep CLAUDE.md honest.
│   ├── fix-issue/SKILL.md              #   /fix-issue <#>. GitHub issue to tested fix with regression test.
│   └── context-budget/SKILL.md         #   /context-budget [--api]. Estimates per-turn token cost of .claude/ + CLAUDE.md.
├── agents/                             # Specialized subagents (one dir each), copy to .claude/agents/   (also published as plugins)
│   ├── code-reviewer/                  #   General code review.
│   ├── silent-failure-hunter/          #   Swallowed errors, failures masked as success.
│   ├── pr-test-analyzer/               #   Do the diff's tests actually verify the change?
│   ├── security-reviewer/              #   Security-focused code review.
│   ├── performance-reviewer/           #   Real bottlenecks, not theoretical ones.
│   ├── doc-reviewer/                   #   Documentation accuracy and completeness.
│   └── frontend-designer/              #   Distinctive UI, anti-AI-slop.
├── hooks/                              # Hook scripts, copy to .claude/hooks/
│   ├── protect-files.sh                #   Block edits to sensitive files and directories.
│   ├── warn-large-files.sh             #   Block writes to build artifacts and binary files.
│   ├── scan-secrets.sh                 #   Detect API keys, tokens, and credentials in file content.
│   ├── block-dangerous-commands.sh     #   Block push to main, force push, reset --hard, publish, rm -rf, DROP TABLE.
│   ├── format-on-save.sh               #   Auto-format after edits. Detects Prettier, Black, Ruff, Biome, rustfmt, gofmt.
│   ├── auto-test.sh                    #   Run the matching test file after edits. Silent on success.
│   ├── session-start.sh                #   Inject branch + dirty state at session start (verbose mode opt-in).
│   ├── notify.sh                       #   Native OS notification when Claude needs attention (macOS/Linux/WSL).
│   └── tests/                          #   Fixture-based test suite: bash hooks/tests/run-all.sh
└── .github/workflows/ci.yml            # CI: hook fixtures (Linux+macOS) + claude plugin validate --strict
```

## What NOT to put in .claude/

Keep `.claude/` focused on what helps your daily work, not what's nice-to-know:

- Things Claude can read from code. Don't describe your file structure. Claude can explore.
- Standard conventions Claude already knows (PEP 8, ESLint defaults, Go formatting).
- Verbose explanations. Every line in `CLAUDE.md` costs tokens. If removing it doesn't cause mistakes, cut it.
- Frequently changing info. Volatile details belong in code comments or docs, not in `CLAUDE.md`.

Token cost rule of thumb: rules without `paths:` frontmatter (and `CLAUDE.md`) cost tokens every turn. Path-scoped rules only cost tokens when working near matched files. Skills and agents cost tokens only when invoked. Run `/context-budget` for the exact breakdown, or `claude plugin details <plugin>@dotclaude` for a plugin's always-on vs on-invoke cost.

## Credits

Built from research across:
- [Official Claude Code documentation](https://code.claude.com/docs/en)
- [Trail of Bits claude-code-config](https://github.com/trailofbits/claude-code-config)
- [awesome-claude-code](https://github.com/hesreallyhim/awesome-claude-code)
- [awesome-claude-code-config](https://github.com/Mizoreww/awesome-claude-code-config)
- Community best practices from hundreds of Claude Code power users

## License

MIT. Use it, fork it, adapt it, share it. See [LICENSE](LICENSE).
