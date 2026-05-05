---
alwaysApply: true
---

# Code Quality

## Anti-defaults (counter common Claude tendencies)

- No premature abstractions. Three similar lines beats a helper used once.
- Don't add features or improvements beyond what was asked.
- Don't refactor adjacent code while fixing a bug.
- No dead code or commented-out blocks. Git has history.
- WHY comments, never WHAT. If code needs a "what" comment, rename instead.
- API docs at module boundaries only, not every internal function.

## Naming

- Files: PascalCase for components and classes (`UserProfile.tsx`), kebab-case for utilities and directories (`date-utils.ts`).
- Booleans: `is` / `has` / `should` / `can` prefix. Functions: verb-first (`getUser`). Handlers: `handle*` internal, `on*` as props.
- Factories: `create*`. Converters: `to*`. Predicates: `is*` / `has*`. Constants: `SCREAMING_SNAKE`.
- Abbreviations only when universally known (`id`, `url`, `api`, `db`, `auth`). Acronyms as words: `userId`, not `userID`.

## Code Markers

`TODO(author): desc (#issue)` for planned work. `FIXME(author): desc (#issue)` for known bugs. `HACK(author): desc (#issue)` for ugly workarounds (explain the proper fix). `NOTE: desc` for non-obvious context. Owner and issue link required. Never `XXX`, `TEMP`, `REMOVEME`.

## File Organization

- Imports: builtins, external, internal, relative, types. Blank line between groups.
- Exports: named over default. One component or class per file.
- Function order: public API first, then helpers in call order.
