# Project Instructions

> REPLACE: Customize this file for your project. Delete sections that don't apply. Every line costs tokens. Code style lives in `.claude/rules/code-quality.md`, don't duplicate here. Run `/setupdotclaude` to auto-customize, or edit manually and delete all `> REPLACE:` blocks when done. Target: under 25 non-blank lines after customization. Hard cap: 50.

## Commands

```bash
# Build
npm run build            # or: cargo build, go build ./..., make build

# Test
npm test                 # run full suite
npm test -- path/to/file # run single test file

# Lint & Format
npm run lint             # check style
npm run lint:fix         # auto-fix style
npm run typecheck        # type checking

# Dev
npm run dev              # start dev server
```

## Architecture

> REPLACE: Describe non-obvious architectural decisions. Don't list files; Claude can explore.

- `src/`. Application source.
- `src/api/`. REST endpoints (versioned: `/v1/`).
- `src/services/`. Business logic (no direct DB access from controllers).
- `src/models/`. Data models and types.

## Key Decisions

> REPLACE: Record WHY non-obvious choices were made. This is the most valuable section. Examples: "Auth tokens in httpOnly cookies because XSS risk", "Billing is a separate module for audit independence".

## Domain Knowledge

> REPLACE: Terms, abbreviations, or concepts that aren't obvious from the code. Example: "SKU" = Stock Keeping Unit, the unique product identifier from our warehouse system.

## Workflow

- Run typecheck after making a series of code changes
- Prefer fixing the root cause over adding workarounds
- When unsure about approach, use plan mode (`Shift+Tab`) before coding

## Don'ts

- Don't modify generated files (`*.gen.ts`, `*.generated.*`)
