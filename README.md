# dotclaude

The standard `.claude/` folder structure for everyday development.

## Why This Exists

Plugins consume hundreds of tokens per turn and are designed for specific workflows like scaffolding entire projects. But day-to-day, you're fixing bugs, adding features, reviewing code, and writing tests — not building products from scratch.

This repo provides a lean, token-efficient `.claude/` configuration optimized for **daily development work**. Copy what you need, delete what you don't.

## Getting Started

### 1. Copy everything into your project

```bash
git clone https://github.com/poshan0126/dotclaude.git /tmp/dotclaude

cd your-project
mkdir -p .claude

# Copy config files
cp /tmp/dotclaude/settings.json .claude/
cp -r /tmp/dotclaude/{rules,skills,agents,hooks} .claude/
cp /tmp/dotclaude/.gitignore .claude/
cp /tmp/dotclaude/CLAUDE.md ./
cp /tmp/dotclaude/CLAUDE.local.md.example ./

chmod +x .claude/hooks/*.sh
rm -rf /tmp/dotclaude

# Add CLAUDE.local.md to your project root .gitignore
echo "CLAUDE.local.md" >> .gitignore
```

### 2. Reload Claude Code

If you already have a Claude Code session open, **exit and restart it**. Skills, agents, and rules are loaded at session start — a running session won't see the new files.

### 3. Run `/setupdotclaude`

```
/setupdotclaude
```

This will:
- Clean up README files that waste tokens
- Scan your codebase (tech stack, test framework, linters, folder structure)
- Customize `CLAUDE.md` with your actual build/test/lint commands
- Update `settings.json` permissions for your package manager
- Adjust rule paths to match your real directories
- Auto-detect and enable your project's formatter (Prettier, Biome, Ruff, Black, rustfmt, gofmt)
- Remove config that doesn't apply (e.g., frontend rules if you have no frontend)
- Run a final review pass against your full codebase

Every change is confirmed with you before it's applied.

> If you skip `/setupdotclaude`, delete the `README.md` files inside `.claude/` subdirectories — they're for GitHub browsing only and waste tokens at runtime.

### Troubleshooting

| Problem | Fix |
|---------|-----|
| Skills or agents not showing up | **Restart Claude Code** — skills/agents/rules are loaded at session start |
| Hooks not running | Run `chmod +x .claude/hooks/*.sh` and verify `jq` is installed |
| "jq not found" blocking everything | Install jq: `brew install jq` (macOS) or `apt install jq` (Linux) |
| format-on-save not formatting | Ensure the formatter binary is installed locally and its config file exists in the project root |
| Permission denied on allowed commands | Check glob syntax in `settings.json` — `Bash(npm run test *)` means the `*` matches arguments after `test` |
| `/setupdotclaude` asks to confirm settings.json edits | This is expected — `protect-files.sh` prompts for confirmation when editing `settings.json` (hook scripts remain hard-blocked) |

### 4. Make it yours

`/setupdotclaude` gets you 90% of the way. To give it your unique touch:

- **`rules/code-quality.md`** — update naming conventions to match your team's style. Tweak the comment guidelines, code marker format, and import order.
- **`rules/frontend.md`** — pick your design principle. Highlight which component framework your project uses.
- **`rules/security.md`** — add paths specific to your project's sensitive areas beyond the defaults.
- **`CLAUDE.md`** — add architectural decisions, domain knowledge, and workflow quirks unique to your project.
- **`CLAUDE.local.md`** — rename the `.example` file for personal preferences (gitignored).
- **`hooks/format-on-save.sh`** — if `/setupdotclaude` didn't detect your formatter, uncomment the right section manually.

The defaults are solid foundations. Your edits on top are what make Claude truly effective for *your* project.

## Skills (Slash Commands)

Skills are invoked with `/name` in your Claude Code session. All skills except `/test-writer` are manual-only — you invoke them explicitly.

| Command | Arguments | Description |
|---------|-----------|-------------|
| `/setupdotclaude` | `[focus area]` | Scan your codebase and customize all `.claude/` config files to match your actual tech stack. Run once after copying dotclaude into a project. Detects language, framework, package manager, test runner, linter, and architecture — then updates CLAUDE.md, settings.json, rules, hooks, and agents. Confirms every change before applying. |
| `/debug-fix` | `[issue #, error msg, or description]` | Find and fix a bug from any source. Reproduces the issue, traces root cause through code and git history, makes the minimal fix, writes a regression test, and wraps up with a branch and commit. |
| `/ship` | `[commit message or PR title]` | Full shipping workflow: scans changes, stages files (skipping secrets/locks/build output), drafts a commit message matching repo style, pushes, and creates a PR. Every step requires your confirmation. |
| `/hotfix` | `[issue #, error msg, or description]` | Emergency production fix. Creates a `hotfix/` branch from main, makes the smallest correct change (no refactoring), runs only critical tests, and ships a PR with `[HOTFIX]` label. Warns if the fix is too complex for a hotfix. |
| `/pr-review` | `[PR #, "staged", file path, or omit]` | Delegates review to specialist agents: `@code-reviewer`, `@security-reviewer` (if security-related code), `@performance-reviewer` (if perf-sensitive), `@doc-reviewer` (if docs changed). Synthesizes a unified report with severity-ranked findings. |
| `/tdd` | `[feature description or function signature]` | Strict Red-Green-Refactor TDD loop. Writes one failing test, then minimum code to pass, then refactors. Commits after each green+refactor cycle. Works simple-to-complex: degenerate cases, happy path, variations, edge cases, errors. |
| `/explain` | `[file, function, or concept]` | Explains code with a one-sentence summary, mental model analogy, ASCII diagram, key non-obvious details, and modification guide. Focuses on the "why" and landmines, not the obvious. |
| `/refactor` | `[file, function, or pattern]` | Safe refactoring with tests as a safety net. Writes tests first if none exist, plans transformations, makes small testable steps, verifies after each step. Never mixes refactoring with behavior changes. |
| `/test-writer` | *(auto-triggers)* | Writes comprehensive tests for new or changed code. Discovers changes via git diff, maps all code paths (happy, edge, error, concurrency), writes one test per scenario with Arrange-Act-Assert. **This is the only skill that can auto-trigger** — Claude may invoke it automatically after you add new features. |

## Agents (Subagents)

Agents are specialized Claude instances that run in their own isolated context. They are auto-delegated by Claude based on the task, or you can invoke them explicitly with `@agent-name` in your prompt.

| Agent | When It's Used | What It Does |
|-------|---------------|--------------|
| `@code-reviewer` | Auto-delegated by `/pr-review`, or invoke directly | Reviews code for correctness and maintainability. Catches off-by-one errors, null dereferences, logic bugs, race conditions, error handling gaps, excessive complexity, and missing tests. Focuses on real issues with evidence — not style nitpicks or linter territory. |
| `@security-reviewer` | Auto-delegated by `/pr-review` when security-related code is changed | Senior security engineer performing static analysis. Covers injection (SQL, command, XSS, template, path traversal), auth/authz flaws, data exposure, cryptography issues, dependency vulnerabilities, and input validation gaps. Reports severity, attack vector, and concrete fix for each finding. |
| `@performance-reviewer` | Auto-delegated by `/pr-review` when performance-sensitive code is changed | Finds real bottlenecks, not theoretical micro-optimizations. Checks for N+1 queries, missing indexes, unbounded queries, memory leaks, repeated computation, blocking I/O on hot paths, unnecessary re-renders, bundle size issues, and lock contention. Only flags issues with measurable impact. |
| `@frontend-designer` | Auto-delegated when building UI, or invoke directly | Creates distinctive, production-grade frontend UI that avoids generic "AI aesthetics." Enforces design tokens, chooses appropriate design principles (glassmorphism, brutalism, editorial, etc.), ensures accessibility (WCAG), and prevents common anti-patterns like purple gradients, centered-everything layouts, and overused fonts. |
| `@doc-reviewer` | Auto-delegated by `/pr-review` when documentation changes | Reviews docs for accuracy by cross-referencing actual source code. Verifies function signatures, code examples, config options, and file paths are correct. Identifies stale references, missing prerequisites, undocumented error cases, and unclear instructions. |

### Using Agents Directly

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

Agents run in isolated context — they don't see your conversation history, but they have access to the full codebase through their allowed tools.

## Customization Guide

| Want to... | Do this |
|---|---|
| Add project-specific rules | Create `.claude/rules/your-rule.md` |
| Scope rules to file paths | Add `paths:` frontmatter to rule files |
| Add a team workflow | Create `.claude/skills/your-skill/SKILL.md` |
| Add a specialist reviewer | Create `.claude/agents/your-agent.md` |
| Enforce behavior deterministically | Add a hook in `settings.json` |
| Override settings locally | Copy `settings.local.json.example` → `.claude/settings.local.json` |
| Personal CLAUDE.md overrides | Rename `CLAUDE.local.md.example` → `CLAUDE.local.md` |

### Example: Project-specific rule

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

## What's Inside

> **Note**: This repo is flat (not nested inside `.claude/`) because `CLAUDE.md` goes at your project root while everything else goes inside `.claude/`. The copy commands below handle the separation.

```
dotclaude/
├── CLAUDE.md                           # Template project instructions → copy to YOUR project root
├── CLAUDE.local.md.example             # Personal overrides template → copy and rename to CLAUDE.local.md
├── settings.json                       # Project settings → copy to .claude/
├── settings.local.json.example         # Personal settings template → copy to .claude/settings.local.json
├── .gitignore                          # Gitignore for .claude/ directory
├── rules/                              # Modular instructions → copy to .claude/rules/
│   ├── code-quality.md                 #   Principles, naming, comments, markers, file organization
│   ├── testing.md                      #   Testing conventions (always loaded)
│   ├── database.md                     #   Migration safety rules (loads near migration files)
│   ├── error-handling.md               #   Error handling patterns (loads near backend files)
│   ├── security.md                     #   Security rules (loads near API/auth files)
│   └── frontend.md                     #   Design tokens, principles, accessibility (loads near UI files)
├── skills/                             # Slash commands → copy to .claude/skills/
│   ├── setupdotclaude/SKILL.md         #   /setupdotclaude — scan codebase, customize all config files
│   ├── debug-fix/SKILL.md              #   /debug-fix — find and fix bugs from any source
│   ├── ship/SKILL.md                   #   /ship — commit, push, PR with confirmations
│   ├── hotfix/SKILL.md                 #   /hotfix — emergency production fix, minimal change, ship fast
│   ├── pr-review/SKILL.md              #   /pr-review — review PR or staged changes via specialist agents
│   ├── tdd/SKILL.md                    #   /tdd — strict red-green-refactor TDD loop
│   ├── explain/SKILL.md                #   /explain <file-or-function>
│   ├── refactor/SKILL.md               #   /refactor <target>
│   └── test-writer/SKILL.md            #   Auto-triggers on new features — comprehensive tests
├── agents/                             # Specialized subagents → copy to .claude/agents/
│   ├── frontend-designer.md            #   Creates distinctive UI — anti-AI-slop
│   ├── security-reviewer.md            #   Security-focused code review
│   ├── performance-reviewer.md         #   Finds real bottlenecks, not theoretical ones
│   ├── code-reviewer.md                #   General code review
│   └── doc-reviewer.md                 #   Documentation accuracy and completeness
└── hooks/                              # Hook scripts → copy to .claude/hooks/
    ├── protect-files.sh                #   Block edits to sensitive files and directories
    ├── warn-large-files.sh             #   Block writes to build artifacts and binary files
    ├── scan-secrets.sh                 #   Detect API keys, tokens, and credentials in file content
    ├── block-dangerous-commands.sh     #   Block push to protected branches (configurable via CLAUDE_PROTECTED_BRANCHES), force push, rm -rf, DROP TABLE, DELETE FROM without WHERE, chmod 777, curl | sh
    ├── format-on-save.sh               #   Auto-format after edits (auto-detects Prettier, Black, Ruff, Biome, rustfmt, gofmt)
    ├── auto-test.sh                    #   Find and run the matching test file after edits
    ├── session-start.sh                #   Inject branch/commit/stash/PR context at session start
    ├── context-recovery.sh             #   Re-inject critical project rules after context compaction
    ├── notify.sh                       #   Native OS notification (macOS / Linux / WSL) when Claude needs input
    └── tests/                          #   Fixtures + runner for regression-testing hooks
        ├── run-all.sh                  #     Run all fixtures; exits non-zero on any failure
        └── fixtures/<hook>/*.json      #     Declarative test cases (stdin + expected exit/stdout)
```

CI: `.github/workflows/hook-tests.yml` runs the hook suite on Linux and macOS for every PR touching `hooks/`.

## What NOT to Put in .claude/

- **Plugins for daily work** — they eat 200-500+ tokens/turn and are scoped to specific workflows
- **Anything Claude can read from code** — don't describe your file structure, Claude can explore it
- **Standard conventions** — Claude already knows PEP 8, ESLint defaults, Go formatting
- **Verbose explanations** — every line in CLAUDE.md costs tokens; if removing it doesn't cause mistakes, cut it
- **Frequently changing info** — put volatile details in code comments or docs, not CLAUDE.md

**Token cost rule of thumb**: Rules with `alwaysApply: true` cost tokens every turn. Path-scoped rules only cost tokens when working near matched files. Skills and agents cost tokens only when invoked.

## Credits

Built from research across:
- [Official Claude Code Documentation](https://code.claude.com/docs/en)
- [Trail of Bits claude-code-config](https://github.com/trailofbits/claude-code-config)
- [awesome-claude-code](https://github.com/hesreallyhim/awesome-claude-code)
- [awesome-claude-code-config](https://github.com/Mizoreww/awesome-claude-code-config)
- Community best practices from hundreds of Claude Code power users

## License

MIT — use it, fork it, adapt it, share it.
