# dotclaude (this repo)

A Claude Code plugin marketplace: agents, skills, rules, and safety hooks, published from the top-level directories. There is no application code, build, or package manager here — everything is bash + markdown + JSON.

## Commands

```bash
bash hooks/tests/run-all.sh          # run all hook fixture tests (requires jq)
claude plugin validate . --strict    # validate marketplace + plugin manifests
```

## Architecture

- Top-level `agents/`, `skills/`, `rules/`, `hooks/` are the single source of truth. `.claude-plugin/marketplace.json` publishes them directly via `source: "./"` + `strict: false` component arrays — there are no per-plugin copies to keep in sync.
- `CLAUDE.template.md` is the template shipped to user projects by `/setupdotclaude`. This file (`CLAUDE.md`) is for working on the repo itself — don't confuse the two.
- `settings.json` at the repo root is the template users copy to `.claude/settings.json`; it wires the hooks.

## Key decisions

- Plugins carry no `version`: updates are git-SHA-based (every commit is an update), same as anthropics/skills. Don't add version fields to marketplace entries.
- Hooks fail open (exit 0) when `jq` is missing, except file-protection hooks which fail closed. Hook `timeout` values are in seconds.
- Agents never set `model` — users choose their own.

## Workflow

- Every new or modified hook MUST ship with fixtures under `hooks/tests/fixtures/<hook-name>/` (see CONTRIBUTING.md).
- After changing any manifest, skill, or agent frontmatter, run `claude plugin validate . --strict`.
- Adding/renaming a skill or agent requires updating `.claude-plugin/marketplace.json` and the folder README.
