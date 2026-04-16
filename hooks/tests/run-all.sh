#!/usr/bin/env bash
# Hook test runner. Iterates every fixture under hooks/tests/fixtures/<hook>/
# and invokes hooks/<hook>.sh with the fixture's stdin, comparing exit code
# and stdout/stderr substrings against the fixture's expectations.
#
# Fixture format (JSON):
#   {
#     "name":        "human readable",
#     "stdin":       <object passed to the hook as JSON>,
#     "expect_exit": 0 | 2,
#     "expect_stdout_contains": ["substring", ...],   // optional
#     "expect_stdout_not_contains": ["substring", ...], // optional
#     "expect_stderr_contains": ["substring", ...]    // optional
#   }
#
# Exit 0 on all pass, 1 on any fail.

set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
FIXTURES="$ROOT/tests/fixtures"

if ! command -v jq >/dev/null 2>&1; then
  echo "FATAL: jq required" >&2
  exit 2
fi

PASS=0
FAIL=0
FAILED_NAMES=()

run_case() {
  local hook_name="$1"
  local fixture="$2"
  local hook_path="$ROOT/${hook_name}.sh"
  [[ -x "$hook_path" ]] || chmod +x "$hook_path" 2>/dev/null || true

  local name stdin expect_exit
  name=$(jq -r '.name' "$fixture")
  stdin=$(jq -c '.stdin' "$fixture")
  expect_exit=$(jq -r '.expect_exit' "$fixture")

  local out_file err_file actual_exit
  out_file=$(mktemp)
  err_file=$(mktemp)

  local env_exports
  env_exports=$(jq -r '(.env // {}) | to_entries | map("\(.key)=\(.value|tostring)") | .[]' "$fixture")

  if [[ -n "$env_exports" ]]; then
    printf '%s' "$stdin" | env $env_exports bash "$hook_path" >"$out_file" 2>"$err_file"
  else
    printf '%s' "$stdin" | bash "$hook_path" >"$out_file" 2>"$err_file"
  fi
  actual_exit=$?

  local ok=1
  if [[ "$actual_exit" != "$expect_exit" ]]; then
    ok=0
  fi

  check_subs() {
    local field="$1" file="$2" invert="$3"
    local count
    count=$(jq -r "(.${field} // []) | length" "$fixture")
    local i=0
    while [[ $i -lt $count ]]; do
      local sub
      sub=$(jq -r ".${field}[$i]" "$fixture")
      if [[ "$invert" == "no" ]]; then
        grep -qF -- "$sub" "$file" || ok=0
      else
        grep -qF -- "$sub" "$file" && ok=0
      fi
      i=$((i+1))
    done
  }

  check_subs "expect_stdout_contains"     "$out_file" "no"
  check_subs "expect_stdout_not_contains" "$out_file" "yes"
  check_subs "expect_stderr_contains"     "$err_file" "no"

  if [[ $ok -eq 1 ]]; then
    printf '  PASS  %s :: %s\n' "$hook_name" "$name"
    PASS=$((PASS+1))
  else
    printf '  FAIL  %s :: %s (exit=%s, expected=%s)\n' "$hook_name" "$name" "$actual_exit" "$expect_exit"
    printf '        stdout: %s\n' "$(head -c 500 "$out_file")"
    [[ -s "$err_file" ]] && printf '        stderr: %s\n' "$(head -c 500 "$err_file")"
    FAIL=$((FAIL+1))
    FAILED_NAMES+=("$hook_name::$name")
  fi
  rm -f "$out_file" "$err_file"
}

for dir in "$FIXTURES"/*/; do
  [[ -d "$dir" ]] || continue
  hook_name=$(basename "$dir")
  echo "== $hook_name =="
  for f in "$dir"*.json; do
    [[ -f "$f" ]] || continue
    run_case "$hook_name" "$f"
  done
done

echo
echo "RESULT: $PASS passed, $FAIL failed"
if [[ $FAIL -gt 0 ]]; then
  printf 'Failed: %s\n' "${FAILED_NAMES[@]}"
  exit 1
fi
exit 0
