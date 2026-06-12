---
name: claude-md
description: Keep CLAUDE.md current and lean — capture this session's durable learnings into it (default), or `audit` it for stale commands, drift, and bloat. Enforces the line budget either way.
argument-hint: "[audit?]"
disable-model-invocation: true
---

`CLAUDE.md` loads every turn for every developer; this skill is how it earns that. Two modes: default captures learnings from the current session; `audit` checks the whole file against reality.

## Capture (default)

Scan THIS conversation for durable, project-level learnings. A learning qualifies only if ALL of these hold:

- **It would prevent a repeat mistake.** The user corrected you, a command failed in a non-obvious way, or a constraint surprised you.
- **It's not derivable from the code.** Claude can re-discover file structure and signatures; it can't re-discover "the staging DB is the one named `prod_replica`".
- **It's durable.** True next month, not just this task. Session-specific state belongs in `/catchup handoff`, not here.
- **It's not already covered** by CLAUDE.md, a rule in `.claude/rules/`, or enforced by a hook.

For each qualifying learning (usually 0-3 per session — finding none is a fine outcome):

1. Draft it as ONE line, with the why if it isn't obvious: `Use \`make test-fast\` for iteration — \`make test\` spins up Docker (3 min).`
2. Pick its destination: command fixes → Commands section; constraints with a path scope → suggest a path-scoped rule instead; everything else → the matching CLAUDE.md section.
3. If it contradicts an existing line, propose editing that line, not appending a second truth.

Present all candidates with AskUserQuestion (multiSelect — let the user pick which to keep), then apply only the selected ones.

## Audit (when `$ARGUMENTS` contains `audit`)

Check every line of CLAUDE.md against reality:

1. **Commands**: does each documented command still exist (`package.json` scripts, Makefile targets, etc.) and match its description? Run `--help`/`--dry-run` variants where cheap.
2. **Paths and names**: do referenced directories, files, and tools still exist?
3. **Duplication**: lines that repeat `.claude/rules/` content, hook-enforced behavior, or standard conventions Claude already knows — propose deletion.
4. **Leftovers**: any `> REPLACE:` template blocks — propose deletion.
5. **Staleness candidates**: claims contradicted by recent code (cross-check anything that smells off against the source).

Report findings as a table (line → problem → proposed fix/deletion), confirm, apply.

## Budget check (both modes, always last)

```bash
grep -cv '^[[:space:]]*$' CLAUDE.md
```

Under 25 non-blank lines = healthy. 25-50 = list the longest sections, propose trims. Over 50 = the additions don't go in until something comes out — propose the trade explicitly ("add line X, delete lines Y-Z").

## Rules

- NEVER write without user confirmation.
- Adding is guilty until proven innocent: every line must pay for itself every session.
- One line per learning. If it needs a paragraph, it belongs in a rule or in docs, with at most a pointer here.
- Don't touch `CLAUDE.local.md` — that's the user's personal space.
