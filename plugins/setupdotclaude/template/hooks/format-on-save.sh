#!/bin/bash
# Auto-formats files after Claude edits them.
# PostToolUse hook for Edit|Write.
# Silent on success. All formatter stdout and stderr is redirected so the
# hook contributes zero tokens on the common path. Auto-detects formatters
# (requires both the binary AND a config file).

# Requires jq for JSON parsing.
if ! command -v jq >/dev/null 2>&1; then
  exit 0
fi

INPUT=$(cat)
FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty')

if [ -z "$FILE_PATH" ] || [ ! -f "$FILE_PATH" ]; then
  exit 0
fi

EXTENSION="${FILE_PATH##*.}"
FORMATTED=false

# Find the project root (nearest directory with a manifest or .git).
find_project_root() {
  local dir="$PWD"
  while [ "$dir" != "/" ]; do
    if [ -f "$dir/package.json" ] || [ -f "$dir/pyproject.toml" ] || [ -f "$dir/Cargo.toml" ] || [ -f "$dir/go.mod" ] || [ -d "$dir/.git" ]; then
      echo "$dir"
      return
    fi
    dir=$(dirname "$dir")
  done
  echo "$PWD"
}

ROOT=$(find_project_root)

# Biome (JS, TS, JSON, CSS all-in-one). Faster than Prettier; check first.
if [ "$FORMATTED" = false ] && [ -f "$ROOT/node_modules/.bin/biome" ] && { [ -f "$ROOT/biome.json" ] || [ -f "$ROOT/biome.jsonc" ]; }; then
  case "$EXTENSION" in
    js|jsx|ts|tsx|json|css)
      npx biome format --write "$FILE_PATH" >/dev/null 2>&1 && FORMATTED=true
      ;;
  esac
fi

# Prettier (Node.js, TypeScript, web).
if [ "$FORMATTED" = false ] && [ -f "$ROOT/node_modules/.bin/prettier" ]; then
  HAS_PRETTIER_CONFIG=false
  for cfg in .prettierrc .prettierrc.json .prettierrc.yml .prettierrc.yaml .prettierrc.js .prettierrc.cjs .prettierrc.mjs .prettierrc.toml prettier.config.js prettier.config.cjs prettier.config.mjs; do
    if [ -f "$ROOT/$cfg" ]; then
      HAS_PRETTIER_CONFIG=true
      break
    fi
  done
  if [ "$HAS_PRETTIER_CONFIG" = false ] && [ -f "$ROOT/package.json" ] && grep -q '"prettier"' "$ROOT/package.json" 2>/dev/null; then
    HAS_PRETTIER_CONFIG=true
  fi

  if [ "$HAS_PRETTIER_CONFIG" = true ]; then
    case "$EXTENSION" in
      js|jsx|ts|tsx|json|css|scss|md|yaml|yml|html)
        npx prettier --write "$FILE_PATH" >/dev/null 2>&1 && FORMATTED=true
        ;;
    esac
  fi
fi

# Ruff (Python). Modern replacement for Black + isort.
if [ "$FORMATTED" = false ] && command -v ruff >/dev/null 2>&1; then
  HAS_RUFF_CONFIG=false
  if [ -f "$ROOT/ruff.toml" ] || [ -f "$ROOT/.ruff.toml" ]; then
    HAS_RUFF_CONFIG=true
  elif [ -f "$ROOT/pyproject.toml" ] && grep -q '\[tool\.ruff\]' "$ROOT/pyproject.toml" 2>/dev/null; then
    HAS_RUFF_CONFIG=true
  fi

  if [ "$HAS_RUFF_CONFIG" = true ]; then
    case "$EXTENSION" in
      py)
        ruff format "$FILE_PATH" >/dev/null 2>&1
        ruff check --fix "$FILE_PATH" >/dev/null 2>&1
        FORMATTED=true
        ;;
    esac
  fi
fi

# Black + isort (Python). Fallback if Ruff is not configured.
if [ "$FORMATTED" = false ] && command -v black >/dev/null 2>&1; then
  HAS_BLACK_CONFIG=false
  if [ -f "$ROOT/pyproject.toml" ] && grep -q '\[tool\.black\]' "$ROOT/pyproject.toml" 2>/dev/null; then
    HAS_BLACK_CONFIG=true
  fi

  if [ "$HAS_BLACK_CONFIG" = true ]; then
    case "$EXTENSION" in
      py)
        black --quiet "$FILE_PATH" >/dev/null 2>&1
        command -v isort >/dev/null 2>&1 && isort --quiet "$FILE_PATH" >/dev/null 2>&1
        FORMATTED=true
        ;;
    esac
  fi
fi

# Rust (rustfmt is standard, no config check needed).
if [ "$FORMATTED" = false ] && command -v rustfmt >/dev/null 2>&1; then
  case "$EXTENSION" in
    rs)
      rustfmt "$FILE_PATH" >/dev/null 2>&1 && FORMATTED=true
      ;;
  esac
fi

# Go (gofmt is standard, no config check needed).
if [ "$FORMATTED" = false ] && command -v gofmt >/dev/null 2>&1; then
  case "$EXTENSION" in
    go)
      gofmt -w "$FILE_PATH" >/dev/null 2>&1 && FORMATTED=true
      ;;
  esac
fi

exit 0
