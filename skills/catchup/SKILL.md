---
name: catchup
description: Rebuild working context fast after /clear or a fresh session — reads the handoff note and the branch's changes, then summarizes where work stands. Add `handoff` to write the note before stopping.
argument-hint: "[handoff | focus area]"
disable-model-invocation: true
allowed-tools:
  - Read
  - Bash(git status)
  - Bash(git log *)
  - Bash(git diff *)
  - Bash(git branch *)
  - Bash(git merge-base *)
---

Two modes. `$ARGUMENTS` containing `handoff` → write the handoff note (end of session). Anything else → catch up (start of session), treating any remaining arguments as a focus area.

## Catch up (default)

Rebuild context in four steps, cheapest first. Read; never modify anything.

1. **Handoff note**: if `.claude/HANDOFF.md` exists, read it first — it's the previous session's intent and beats anything inferable from git. Note its date; flag if it predates the latest commit (it may be stale).
2. **Branch state**:
   - `git status` — uncommitted/staged work in flight
   - `git log --oneline $(git merge-base HEAD origin/HEAD 2>/dev/null || echo HEAD~10)..HEAD` — what this branch did
   - `git diff --stat $(git merge-base HEAD origin/HEAD 2>/dev/null || echo HEAD~10)..HEAD` — where the change mass is
3. **Read the changed files** — the diff hunks, not whole files. If more than ~15 files changed, read the 5 with the most churn plus anything matching the focus area, and list the rest by name.
4. **Summarize** in this shape, terse:

```
## Catchup: <branch>

**Goal** (from handoff or inferred): <one line>
**Done**: <commits/changes, 2-4 bullets>
**In flight**: <uncommitted work, or "clean">
**Next** (from handoff, or inferred): <one line>
**Watch out**: <gotchas from the handoff, if any>
```

If there's no handoff note and no branch divergence (fresh clone, main at origin), say so and ask what to work on instead of inventing a summary.

## Handoff (when `$ARGUMENTS` contains `handoff`)

Write `.claude/HANDOFF.md` capturing THIS session for the next one. Keep it under 30 lines — it's a note, not a transcript:

```markdown
# Handoff — <date> — <branch>

## Goal
<what this work is trying to achieve, one line>

## State
- Done: <completed + verified>
- In flight: <started, not finished — exact file/function>
- Untouched: <known remaining scope>

## Gotchas
- <what failed and why, dead ends not to repeat, surprising constraints>

## Next step
<the single concrete action to take first>
```

Show the note and confirm before writing. Overwrite any existing note (it described an older state). Suggest adding `.claude/HANDOFF.md` to `.gitignore` if it isn't there — it's personal session state, like `CLAUDE.local.md`.

## Rules

- Catchup mode is strictly read-only.
- Never paste large diffs into the summary — reference `file:line` and characterize.
- The handoff captures decisions and dead ends, not narrative. "Tried X, broke Y, use Z instead" is the gold standard line.
