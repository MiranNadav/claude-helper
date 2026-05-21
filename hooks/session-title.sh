#!/usr/bin/env bash
# Sets terminal window/tab title to the first user message of the Claude session.
# Runs on every UserPromptSubmit; no-ops after the first message per session.

INPUT=$(cat)

MARKER_DIR="/tmp/claude-helper"
mkdir -p "$MARKER_DIR"

SESSION_ID=$(echo "$INPUT" | python3 -c "
import sys, json
d = json.load(sys.stdin)
print(d.get('session_id', 'unknown'))
" 2>/dev/null)

MARKER="$MARKER_DIR/$SESSION_ID"

if [ ! -f "$MARKER" ]; then
    PROMPT=$(echo "$INPUT" | python3 -c "
import sys, json
d = json.load(sys.stdin)
p = d.get('prompt', '').strip().replace('\n', ' ')
print(p[:80])
" 2>/dev/null)
    touch "$MARKER"
    # /dev/tty unavailable when Claude detaches controlling terminal from hook subprocess.
    # Walk process tree to find the actual TTY device (macOS: ps tty 's003' -> /dev/ttys003).
    TTY_PATH=""
    PID=$$
    while [ "$PID" -gt 1 ] && [ -z "$TTY_PATH" ]; do
        TTY_NAME=$(ps -p "$PID" -o tty= 2>/dev/null | tr -d ' ')
        if [ -n "$TTY_NAME" ] && [ "$TTY_NAME" != "??" ]; then
            TTY_PATH="/dev/tty${TTY_NAME}"
        fi
        PID=$(ps -p "$PID" -o ppid= 2>/dev/null | tr -d ' ')
    done

    if [ -n "$TTY_PATH" ] && [ -e "$TTY_PATH" ]; then
        printf '\033]0;%s\007' "$PROMPT" > "$TTY_PATH"
    fi
fi
