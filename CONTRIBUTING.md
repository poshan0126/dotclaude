# Contributing to dotclaude

Thanks for wanting to make this better. This project aims to be the standard `.claude/` folder structure. Contributions that help more developers ship faster are welcome.

## Before you contribute

- Check existing issues and open PRs to avoid duplicate work.
- For large changes (new skills, new agents, restructuring), open an issue first to discuss the approach.

## What we're looking for

**Yes, please:**
- Bug fixes in hook scripts
- Improvements to existing rules, skills, or agents that make them more effective
- New skills for common daily workflows (not project-creation workflows)
- New agents for common review or analysis tasks
- Better token efficiency. Same quality, fewer tokens.
- Documentation improvements

**Probably not:**
- Language-specific rules. Claude already knows standard conventions.
- Project scaffolding skills. This repo is for daily work, not project creation.
- Vendor-specific configurations (specific CI providers, cloud platforms, etc.)

> Plugin packaging is welcome. Dotclaude itself ships as a marketplace (see the main README). Improvements to `.claude-plugin/marketplace.json` or `hooks/hooks.json` count as documentation improvements.

## PR rules

### One thing per PR

Each PR should do exactly one thing. Don't bundle a new skill with a rule fix and a README update. Split them.

### File requirements

| File type | Must have | Must NOT have |
|---|---|---|
| **Rules** (`.md` in `rules/`) | `paths:` frontmatter for scoped rules; no frontmatter for always-loaded | Language-specific conventions Claude already knows |
| **Skills** (`SKILL.md`) | `name`, `description` in frontmatter | Hardcoded package names, model assignments |
| **Agents** (`agents/<name>/<name>.md`) | `name`, `description` (delegation trigger: "Use after/when..."), `tools` in frontmatter | `model` field (users choose their own model) |
| **Hooks** (`.sh` in `hooks/`) | `jq` availability check, proper exit codes (0 = allow, 2 = block) | Hardcoded paths, missing `#!/bin/bash` |

### Naming

- Skill directories: `kebab-case`. `debug-fix/`, `test-writer/`.
- Agent files: one dir per agent, `agents/<kebab-case>/<kebab-case>.md`. `agents/code-reviewer/code-reviewer.md`.
- Rule files: `kebab-case.md`. `code-quality.md`, `frontend.md`.
- Hook scripts: `kebab-case.sh`. `protect-files.sh`, `block-dangerous-commands.sh`.

### No duplication

Before adding content, check that it's not already covered elsewhere:

- If a hook enforces it, don't also add a rule saying the same thing.
- If a skill covers it, don't duplicate the guidance in a rule.
- If `CLAUDE.md` says it, don't repeat it in a rule.
- Agents run isolated and CAN repeat rule content. They don't see rules.

### No hardcoded opinions

This is a template. Keep it framework-agnostic.

- Don't hardcode `npm`, `pnpm`, `yarn`, or any specific package manager.
- Don't hardcode specific component libraries, CSS frameworks, or test runners.
- Don't assign `model` to agents or skills. Let users choose.
- Present options as tables or lists, not mandates.
- The `/setupdotclaude` skill handles project-specific customization at runtime.

### Token consciousness

Every line in a rule costs tokens every session. Every line in a skill costs tokens when invoked, and every skill's frontmatter `description` costs tokens in the per-session skill listing — keep descriptions under ~200 characters. Before adding content, ask: would removing this cause Claude to make mistakes? If no, don't add it.

CI enforces this: the `token-budget` job fails any PR that pushes always-loaded content (`CLAUDE.template.md` + rules without `paths:`) past ~1200 estimated tokens.

### Hook scripts must be safe

- Always check for `jq` availability before using it.
- Exit 0 (allow) if dependencies are missing. Don't block the user.
- PreToolUse hooks observe and block. They should never modify files. PostToolUse hooks may transform output (for example, formatting).
- Test with sample JSON input before submitting.

### Plugin marketplace consistency

The top-level `agents/`, `skills/`, `rules/`, and `hooks/` directories are the single source of truth. Each `plugins/<name>/` dir contains only a `.claude-plugin/plugin.json` plus **relative symlinks** into the top-level dirs — Claude Code dereferences them at install time, so there are no copies to keep in sync. Never place real component files inside `plugins/`, and never use `"./"` as a plugin source (the repo root as plugin root makes default discovery load everything into every plugin).

If you add or rename a skill or agent:

- Add or update its entry in `.claude-plugin/marketplace.json` (include `description`, `category`, and `keywords`; do NOT add a `version` there — versions live only in `plugin.json`).
- Bump the `version` in `plugins/<name>/.claude-plugin/plugin.json` whenever the plugin's components change.
- Create `plugins/<name>/` with a matching `plugin.json` and a directory symlink: `ln -s ../../agents/<name> plugins/<name>/agents` for an agent, or `ln -s ../../../skills/<name> plugins/<name>/skills/<name>` for a skill. Always symlink directories, never individual `.md` files — the component scanner skips file symlinks.
- Run `claude plugin validate . --strict` and make sure it passes. CI runs the same check on every PR.

### Hooks require tests

Every new or modified hook script MUST ship with fixtures under `hooks/tests/fixtures/<hook-name>/`. Each fixture is a JSON file specifying the stdin payload Claude Code would deliver, the expected exit code (0 allow, 2 block), and any substrings that must or must not appear in stdout. Cover at minimum: (a) one allow case, (b) one block case, and (c) every adversarial input class the hook's regexes touch (quoted paths, shell expansions, multi-statement SQL, combined flags, case variants, redirection edge cases). PRs that add or change a hook without corresponding fixtures will be rejected. Run `bash hooks/tests/run-all.sh` locally and ensure it passes before opening a PR. CI (`.github/workflows/ci.yml`) runs the same suite on Linux and macOS for every PR, plus `claude plugin validate . --strict`.

Fixtures for secret-detection hooks necessarily contain fake credentials, which trips external secret scanners (GitGuardian etc.). Make every fake unambiguous — alphabet tokens, `fake_password_for_tests`, `localhost` hosts — and keep fixture paths listed in `.gitguardian.yaml` so scanners skip them. Never paste a real credential into a fixture, even a revoked one.

### Update READMEs

If you add a new file to `rules/`, `skills/`, `agents/`, or `hooks/`, add a description to the README in that folder. Keep it to two or three lines.

### Update the root README

If your change adds or removes a file, update the structure tree in `README.md` to match.

## How to submit

1. Fork the repo.
2. Create a branch: `feat/your-skill-name` or `fix/hook-bug-description`.
3. Make your changes.
4. Test: run `bash hooks/tests/run-all.sh` and `claude plugin validate . --strict`. Verify YAML frontmatter is valid, hook scripts work with sample input, and there's no duplication with existing files.
5. Open a PR with:
   - **Title**: what you added or changed (under 72 chars)
   - **Body**: why it's useful, what daily workflow it improves
   - **Testing**: how you verified it works

## Code of conduct

Be helpful, be kind, be constructive. We're all here to make Claude Code better for daily development work.
