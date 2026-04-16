# Contributing to dotclaude

Thanks for wanting to make this better. This project aims to be the standard `.claude/` folder structure — contributions that help more developers ship faster are welcome.

## Before You Contribute

- Check existing issues and open PRs to avoid duplicate work
- For large changes (new skills, new agents, restructuring), open an issue first to discuss the approach

## What We're Looking For

**Yes, please:**
- Bug fixes in hook scripts
- Improvements to existing rules, skills, or agents that make them more effective
- New skills for common daily workflows (not project-creation workflows)
- New agents for common review/analysis tasks
- Better token efficiency — same quality, fewer tokens
- Documentation improvements

**Probably not:**
- Language-specific rules — Claude already knows standard conventions
- Plugin integrations — this repo is deliberately plugin-free
- Project scaffolding skills — this is for daily work, not project creation
- Vendor-specific configurations (specific CI providers, cloud platforms, etc.)

## PR Rules

### One thing per PR

Each PR should do exactly one thing. Don't bundle a new skill with a rule fix with a README update. Split them.

### File requirements

| File type | Must have | Must NOT have |
|---|---|---|
| **Rules** (`.md` in `rules/`) | `alwaysApply: true` or `paths:` frontmatter | Language-specific conventions Claude already knows |
| **Skills** (`SKILL.md`) | `name`, `description` in frontmatter | Hardcoded package names, model assignments |
| **Agents** (`.md` in `agents/`) | `name`, `description`, `tools` in frontmatter | `model` field (users choose their own model) |
| **Hooks** (`.sh` in `hooks/`) | `jq` availability check, proper exit codes (0=allow, 2=block) | Hardcoded paths, missing `#!/bin/bash` |

### Naming

- Skill directories: `kebab-case` — `debug-fix/`, `test-writer/`
- Agent files: `kebab-case.md` — `code-reviewer.md`, `security-reviewer.md`
- Rule files: `kebab-case.md` — `code-quality.md`, `frontend.md`
- Hook scripts: `kebab-case.sh` — `protect-files.sh`, `block-dangerous-commands.sh`

### No duplication

Before adding content, check that it's not already covered elsewhere:

- If a hook enforces it, don't also add a rule saying the same thing
- If a skill covers it, don't duplicate the guidance in a rule
- If `CLAUDE.md` says it, don't repeat it in a rule
- Agents run isolated and CAN repeat rule content (they don't see rules)

### No hardcoded opinions

This is a template — keep it framework-agnostic:

- Don't hardcode `npm`, `pnpm`, `yarn`, or any specific package manager
- Don't hardcode specific component libraries, CSS frameworks, or test runners
- Don't assign `model` to agents or skills — let users choose
- Present options as tables or lists, not mandates
- The `/setupdotclaude` skill handles project-specific customization at runtime

### Token consciousness

Every line in a rule costs tokens every session. Every line in a skill costs tokens when invoked. Before adding content, ask: "Would removing this cause Claude to make mistakes?" If no, don't add it.

### Hook scripts must be safe

- Always check for `jq` availability before using it
- Exit 0 (allow) if dependencies are missing — don't block the user
- PreToolUse hooks observe and block — they should never modify files. PostToolUse hooks may transform output (e.g., formatting).
- Test with sample JSON input before submitting

### Hooks require tests

Every new or modified hook script MUST ship with fixtures under `hooks/tests/fixtures/<hook-name>/`. Each fixture is a JSON file specifying the stdin payload Claude Code would deliver, the expected exit code (0 allow, 2 block), and any substrings that must or must not appear in stdout. Cover at minimum: (a) one allow case, (b) one block case, and (c) every adversarial input class the hook's regexes touch (quoted paths, shell expansions, multi-statement SQL, combined flags, case variants, redirection edge cases). PRs that add or change a hook without corresponding fixtures will be rejected. Run `bash hooks/tests/run-all.sh` locally and ensure it passes before opening a PR — CI (`.github/workflows/hook-tests.yml`) runs the same suite on Linux and macOS for every PR touching `hooks/`.

### Update READMEs

If you add a new file to `rules/`, `skills/`, `agents/`, or `hooks/`, add a description to the README in that folder. Keep it to 2-3 lines.

### Update the root README

If your change adds or removes a file, update the structure tree in `README.md` to match.

## How to Submit

1. Fork the repo
2. Create a branch: `feat/your-skill-name` or `fix/hook-bug-description`
3. Make your changes
4. Test: verify YAML frontmatter is valid, hook scripts work with sample input, no duplication with existing files
5. Open a PR with:
   - **Title**: what you added/changed (under 72 chars)
   - **Body**: why it's useful, what daily workflow it improves
   - **Testing**: how you verified it works

## Code of Conduct

Be helpful, be kind, be constructive. We're all here to make Claude Code better for daily development work.
