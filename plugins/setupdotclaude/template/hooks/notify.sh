#!/bin/bash
# Sends a native OS notification when Claude needs user input.
# Used as a Notification hook.
# Supports macOS (osascript), Linux (notify-send), and WSL (powershell).

INPUT=$(cat 2>/dev/null)

# Extract the notification message if jq is available
MESSAGE="Claude Code needs your attention"
if command -v jq >/dev/null 2>&1 && [ -n "$INPUT" ]; then
  MSG=$(echo "$INPUT" | jq -r '.message // empty' 2>/dev/null)
  if [ -n "$MSG" ]; then
    MESSAGE="$MSG"
  fi
fi

TITLE="Claude Code"

# macOS
if command -v osascript >/dev/null 2>&1; then
  osascript -e "display notification \"$MESSAGE\" with title \"$TITLE\"" 2>/dev/null
  exit 0
fi

# Linux (native)
if command -v notify-send >/dev/null 2>&1; then
  notify-send "$TITLE" "$MESSAGE" 2>/dev/null
  exit 0
fi

# WSL → Windows toast
if command -v powershell.exe >/dev/null 2>&1; then
  powershell.exe -Command "[System.Reflection.Assembly]::LoadWithPartialName('System.Windows.Forms') | Out-Null; \$n = New-Object System.Windows.Forms.NotifyIcon; \$n.Icon = [System.Drawing.SystemIcons]::Information; \$n.Visible = \$true; \$n.ShowBalloonTip(5000, '$TITLE', '$MESSAGE', 'Info')" 2>/dev/null
  exit 0
fi

# No notification method available. Silent exit
exit 0
