#!/usr/bin/env bash
# Sync source agents/ and skills/ into per-plugin directories, and bundle the
# full dotclaude template into plugins/setupdotclaude/template/ so that plugin
# can bootstrap .claude/ from scratch in any project.
#
# Plugins must be self-contained (Claude Code copies each plugin to a cache
# on install and paths can't escape the plugin root), so each agent/skill
# physically lives inside its plugin folder.

set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

shopt -s nullglob

# 1. Sync agents: agents/<name>.md -> plugins/<name>/agents/<name>.md
for f in agents/*.md; do
  name="$(basename "$f" .md)"
  [ "$name" = "README" ] && continue
  mkdir -p "plugins/$name/agents"
  cp "$f" "plugins/$name/agents/$name.md"
  echo "  agent  $name"
done

# 2. Sync skills: skills/<name>/SKILL.md -> plugins/<name>/skills/<name>/SKILL.md
for d in skills/*/; do
  name="$(basename "$d")"
  [ -f "${d}SKILL.md" ] || continue
  mkdir -p "plugins/$name/skills/$name"
  cp "${d}SKILL.md" "plugins/$name/skills/$name/SKILL.md"
  echo "  skill  $name"
done

# 3. Bundle the full dotclaude template into the setupdotclaude plugin
#    so it can bootstrap .claude/ in any project at install time.
TEMPLATE="plugins/setupdotclaude/template"
rm -rf "$TEMPLATE"
mkdir -p "$TEMPLATE"

cp settings.json                   "$TEMPLATE/"
[ -f settings.local.json.example ] && cp settings.local.json.example "$TEMPLATE/"
cp CLAUDE.md                       "$TEMPLATE/"
cp CLAUDE.local.md.example         "$TEMPLATE/"
cp -r rules                        "$TEMPLATE/"
cp -r skills                       "$TEMPLATE/"
cp -r agents                       "$TEMPLATE/"
cp -r hooks                        "$TEMPLATE/"

echo "  bundle setupdotclaude/template (full dotclaude content)"
echo "Done."
