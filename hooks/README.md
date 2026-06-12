# Hooks

Hook scripts are deterministic enforcement. Unlike rules (advisory), hooks **guarantee** behavior by blocking or modifying tool calls before or after they execute.

Hooks are wired in `settings.json` under the `"hooks"` key. Each hook specifies an event, a matcher, and a command to run. `timeout` values are in **seconds**.

The four PreToolUse guards below are also packaged as the `safety-hooks` plugin (`/plugin install safety-hooks@dotclaude`) via `plugins/safety-hooks/hooks/hooks.json`, so you can get them without copying any files. `tests/` holds the fixture suite (`bash hooks/tests/run-all.sh`); it doesn't belong in a project's `.claude/hooks/`.

## Available hooks

### protect-files.sh
**Event**: PreToolUse (`Edit` | `Write`)

Blocks edits to sensitive and generated files. Fails closed (blocks if `jq` is missing).

- `.env`, `.env.*`. Secrets, by basename and path.
- `*.pem`, `*.key`, `*.crt`, `*.p12`, `*.pfx`. Certificates and keys.
- `id_rsa`, `id_ed25519`, `credentials.json`, `.npmrc`, `.pypirc`. Credentials.
- `package-lock.json`, `yarn.lock`, `pnpm-lock.yaml`. Lock files.
- `*.gen.ts`, `*.generated.*`. Generated code.
- `*.min.js`, `*.min.css`. Minified bundles.
- Anything inside `.git/`, `secrets/`, or `.claude/hooks/`.
- Self-protecting: blocks edits to hook scripts and `settings.json`.

### warn-large-files.sh
**Event**: PreToolUse (`Edit` | `Write`)

Blocks writes to build artifacts, dependency directories, and binary files. Fails closed.

- `node_modules/`, `vendor/`, `dist/`, `build/`, `.next/`, `__pycache__/`, `.venv/`.
- `*.wasm`, `*.so`, `*.dylib`, `*.dll`, `*.exe`, `*.zip`, `*.tar.*`.
- `*.mp4`, `*.mov`, `*.mp3`, `*.pyc`, `*.class`.

### block-dangerous-commands.sh
**Event**: PreToolUse (`Bash`)

Blocks dangerous shell commands. Detects patterns even in chained commands (`&&`, `;`). Fails closed.

- **Git**: `git push origin main/master`, `git push --force` (allows `--force-with-lease`), bare `git push` on main.
- **Filesystem**: `rm -rf /`, `rm -rf ~`, recursive delete on root/home paths.
- **Database**: `DROP TABLE/DATABASE`, `DELETE FROM` without WHERE, `TRUNCATE TABLE`.
- **System**: `chmod 777`, piping `curl`/`wget` to `bash`/`sh`, `mkfs`, `dd if=`, writes to `/dev/`.

### format-on-save.sh
**Event**: PostToolUse (`Edit` | `Write`)

Auto-formats files after Claude edits them. Auto-detects formatters by checking for both the binary and a config file:

- Biome: `biome.json` plus `node_modules/.bin/biome`.
- Prettier: `.prettierrc*` or `package.json` prettier key plus `node_modules/.bin/prettier`.
- Ruff: `ruff.toml` or `pyproject.toml [tool.ruff]` plus `ruff` binary.
- Black: `pyproject.toml [tool.black]` plus `black` binary.
- rustfmt: standard for Rust (no config needed).
- gofmt: standard for Go (no config needed).

### session-start.sh
**Event**: SessionStart

Injects dynamic project context at session start.

**Default (minimal, ~5 to 10 tokens)**: current branch (or detached HEAD warning) and a `dirty` tag if there are uncommitted changes. That's it. No network calls, no extra detail.

**Verbose**: set `DOTCLAUDE_SESSION_VERBOSE=1` in your shell to also emit:
- Last commit oneline.
- Uncommitted file count.
- Staged indicator.
- Stash count.
- Active PR info via `gh` (adds a network round-trip).

The verbose payload runs ~30 to 90 tokens per session. Default is recommended for daily iterative work where every new conversation pays this cost.

**Drift nudge**: if `.claude/.dotclaude.json` exists (written by `/setupdotclaude` at the end of setup), the hook hashes the project's manifests (`package.json` scripts, `pyproject.toml`, `Cargo.toml`, `go.mod`, `Gemfile`, `composer.json`, `Makefile`) and appends a one-line re-tune nudge only when the hash no longer matches. `DOTCLAUDE_FINGERPRINT=1 session-start.sh` prints the fingerprint JSON (how the skill writes the file); `DOTCLAUDE_META` overrides the fingerprint path (used by tests).

### auto-test.sh
**Event**: PostToolUse (`Edit` | `Write`)

Finds and runs the test file matching the edited source file (same-dir, `__tests__/`, or parallel `tests/` conventions; vitest/jest/mocha, pytest/unittest, `go test`, `cargo test`). Silent on success — passing tests contribute zero tokens. Only emits output when tests fail. Skips test files themselves, config files, and non-code extensions.

### notify.sh
**Event**: Notification

Sends a native OS notification when Claude needs your attention. Supports macOS (`osascript`), Linux (`notify-send`), and WSL (PowerShell toast). Extracts the actual message from the hook input when `jq` is available. Exits silently when no notifier exists. Set `DOTCLAUDE_NOTIFY_DRYRUN=1` to print instead of notify (used by the test fixtures).

## Adding your own

1. Create a `.sh` script in this directory.
2. Make it executable: `chmod +x your-hook.sh`.
3. Wire it in `settings.json`:

```json
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Bash",
        "hooks": [
          {
            "type": "command",
            "command": "$CLAUDE_PROJECT_DIR/.claude/hooks/your-hook.sh"
          }
        ]
      }
    ]
  }
}
```

- Exit 0 to allow, exit 2 to block.
- Scripts receive JSON on stdin with `tool_input`.
- Requires `jq` for JSON parsing.

See [Claude Code docs](https://code.claude.com/docs/en/hooks) for all hook events.
