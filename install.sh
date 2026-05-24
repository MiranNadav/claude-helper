#!/usr/bin/env bash
set -euo pipefail

REPO_DIR="$(cd "$(dirname "$0")" && pwd)"

echo "claude-helper: installing from $REPO_DIR"

# Make hooks executable
chmod +x "$REPO_DIR/hooks/"*.sh
echo "  hooks marked executable"

# Merge hook entries into ~/.claude/settings.json
python3 - "$REPO_DIR" << 'PYEOF'
import json, os, sys

repo_dir = sys.argv[1]
settings_path = os.path.expanduser("~/.claude/settings.json")

def cmd(script):
    return f'bash "{repo_dir}/hooks/{script}"'

to_add = {
    "UserPromptSubmit": [cmd("session-title.sh"), cmd("iterm-attention.sh")],
    "PreToolUse":       [cmd("iterm-attention.sh")],
    "PostToolUse":      [cmd("iterm-attention.sh")],
    "Stop":             [cmd("iterm-attention.sh")],
    "StatusLine":       [cmd("statusline.sh")],
}

settings = {}
if os.path.exists(settings_path):
    with open(settings_path) as f:
        settings = json.load(f)

settings.setdefault("hooks", {})
added = []

for event, commands in to_add.items():
    event_hooks = settings["hooks"].setdefault(event, [])
    existing = {h.get("command", "") for entry in event_hooks for h in entry.get("hooks", [])}
    for c in commands:
        if c not in existing:
            event_hooks.append({"matcher": "", "hooks": [{"type": "command", "command": c}]})
            added.append(f"  {event}: {c}")
            existing.add(c)

os.makedirs(os.path.dirname(settings_path), exist_ok=True)
with open(settings_path, "w") as f:
    json.dump(settings, f, indent=2)
    f.write("\n")

if added:
    print("  added to ~/.claude/settings.json:")
    for a in added:
        print(a)
else:
    print("  all hooks already present — nothing to do")
PYEOF

echo "Done. Restart Claude Code for changes to take effect."
