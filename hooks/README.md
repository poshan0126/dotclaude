# Hooks

Hook scripts are deterministic enforcement — unlike rules (advisory), hooks **guarantee** behavior by blocking or modifying tool calls before/after they execute.

Hooks are wired in `settings.json` under the `"hooks"` key. Each hook specifies an event, a matcher, and a command to run.

## Available Hooks

### protect-files.sh
**Event**: PreToolUse (Edit|Write)

Blocks edits to sensitive and generated files. Fails closed (blocks if `jq` is missing).
- `.env`, `.env.*` — secrets (by basename and path)
- `*.pem`, `*.key`, `*.crt`, `*.p12`, `*.pfx` — certificates and keys
- `id_rsa`, `id_ed25519`, `credentials.json`, `.npmrc`, `.pypirc` — credentials
- `package-lock.json`, `yarn.lock`, `pnpm-lock.yaml` — lock files
- `*.gen.ts`, `*.generated.*` — generated code
- `*.min.js`, `*.min.css` — minified bundles
- Anything inside `.git/`, `secrets/`, or `.claude/hooks/`
- Self-protecting: blocks edits to hook scripts and `settings.json`

### warn-large-files.sh
**Event**: PreToolUse (Edit|Write)

Blocks writes to build artifacts, dependency directories, and binary files. Fails closed.
- `node_modules/`, `vendor/`, `dist/`, `build/`, `.next/`, `__pycache__/`, `.venv/`
- `*.wasm`, `*.so`, `*.dylib`, `*.dll`, `*.exe`, `*.zip`, `*.tar.*`
- `*.mp4`, `*.mov`, `*.mp3`, `*.pyc`, `*.class`

### scan-secrets.sh
**Event**: PreToolUse (Edit|Write)

Scans file content for accidental secrets before writing. Allows (exits 0) if `jq` is missing — don't block the user. Blocks on matches for AWS keys, GitHub/GitLab tokens, Slack/Stripe keys, private key headers, OAuth bearer tokens, and high-entropy strings near keywords like `password`, `secret`, `api_key`. Uses `ask` (not hard deny) so user can override for legitimate cases (fixtures, docs).

### block-dangerous-commands.sh
**Event**: PreToolUse (Bash)

Blocks dangerous shell commands. Detects patterns even in chained commands (`&&`, `;`, subshells). Fails closed (blocks if `jq` missing).

**Protected branches are configurable** — set `CLAUDE_PROTECTED_BRANCHES` as a comma list (e.g. `main,master,develop,release`). The hook also reads `git config init.defaultBranch` automatically. Default: `main,master`.

- **Git**: push to any protected branch on any remote (`origin`, `upstream`, ...), explicit refspec (`HEAD:main`, `:main`), bare `git push` while on a protected branch, `--force` (allows `--force-with-lease`)
- **Filesystem**: `rm -rf /`, `rm -rf ~`, `rm -rf "$HOME/x"` (quoted paths), `rm -rf $VAR` (unknown expansions are blocked conservatively)
- **Database**: `DROP TABLE/DATABASE`, `DELETE FROM` without `WHERE` — multi-statement SQL is parsed per-statement (an unrelated `WHERE` in a later statement does not mask a missing `WHERE` earlier)
- **System**: `chmod 777` in all forms (`chmod 0777`, `chmod -R 777`, `chmod a+rwx`), piping `curl`/`wget` to `bash`/`sh`, `mkfs`, `dd if=`, destructive writes to device files (`/dev/sda`) — safe stderr/stdout redirects like `2>/dev/null` are explicitly allowed
- **Publish**: `npm publish` (allows `--dry-run`)

### format-on-save.sh
**Event**: PostToolUse (Edit|Write)

Auto-formats files after Claude edits them. Auto-detects formatters by checking for both the binary and a config file:
- Biome: `biome.json` + `node_modules/.bin/biome`
- Prettier: `.prettierrc*` or `package.json` prettier key + `node_modules/.bin/prettier`
- Ruff: `ruff.toml` or `pyproject.toml [tool.ruff]` + `ruff` binary
- Black: `pyproject.toml [tool.black]` + `black` binary
- rustfmt: standard for Rust (no config needed)
- gofmt: standard for Go (no config needed)

### auto-test.sh
**Event**: PostToolUse (Edit|Write)

After Claude edits a source file, finds the matching test file (`foo.ts` → `foo.test.ts` / `foo.spec.ts` / `__tests__/foo.*` / `tests/test_foo.py` / etc.) and runs it. Skips test files themselves, config files, and non-testable extensions. Silent no-op when no test runner is detected.

### session-start.sh
**Event**: SessionStart

Injects dynamic project context at session start: current branch (or detached HEAD warning), last commit, uncommitted changes count, staged changes indicator, and stash count.

### context-recovery.sh
**Event**: SessionStart (matcher: `compact`)

After context compaction, re-injects critical project rules that may have been summarized away. Edit the `RULES` section at the top of the script to list your non-negotiable requirements (e.g. "never use `any` in TypeScript", "all migrations must be reversible"). Fires only on compact, not on normal session start.

### notify.sh
**Event**: Notification

Native OS notification when Claude needs user attention (waiting for input, long idle). Supports macOS (`osascript`), Linux (`notify-send`), and WSL (`powershell.exe`). Degrades silently if no notification backend is available.

## Testing

Every hook ships with regression fixtures. Run locally:

```bash
bash hooks/tests/run-all.sh
```

Fixture format:

```json
{
  "name": "block push to origin main",
  "stdin": { "tool_input": { "command": "git push origin main" } },
  "env":   { "CLAUDE_PROTECTED_BRANCHES": "main,develop" },
  "expect_exit": 2,
  "expect_stdout_contains": ["deny", "main"],
  "expect_stdout_not_contains": []
}
```

The runner pipes `stdin` into `hooks/<hook-name>.sh` (with any fixture `env` exported), then checks exit code and substring assertions. CI at `.github/workflows/hook-tests.yml` runs the suite on Linux and macOS for every PR touching `hooks/`. See [CONTRIBUTING.md](../CONTRIBUTING.md) for the "every new/modified hook needs fixtures" rule.

## Adding Your Own

1. Create a `.sh` script in this directory
2. Make it executable: `chmod +x your-hook.sh`
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

- Exit 0 = allow, Exit 2 = block
- Scripts receive JSON on stdin with `tool_input`
- Requires `jq` for JSON parsing

See [Claude Code docs](https://code.claude.com/docs/en/hooks) for all hook events.
