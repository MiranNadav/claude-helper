#!/usr/bin/env bash
# Sets terminal window/tab title to the latest user message each turn.

INPUT=$(cat)

mkdir -p /tmp/claude-helper
echo "[$(date '+%H:%M:%S')] session-title triggered" >> /tmp/claude-helper/hooks.log

MARKER_DIR="/tmp/claude-helper"

SESSION_ID=$(echo "$INPUT" | python3 -c "
import sys, json
d = json.load(sys.stdin)
print(d.get('session_id', 'unknown'))
" 2>/dev/null)

touch "$MARKER_DIR/$SESSION_ID"

PROMPT=$(echo "$INPUT" | python3 -c "
import sys, json
d = json.load(sys.stdin)
p = d.get('prompt', '').strip().replace('\n', ' ')
print(p[:80])
" 2>/dev/null)

# Normalise TTY name from ps output (may be 'ttys005' or 's005' on macOS)
normalise_tty() {
    local t="$1"
    if [[ "$t" == tty* ]]; then
        echo "/dev/$t"
    else
        echo "/dev/tty$t"
    fi
}

# Walk process tree to find TTY
find_tty() {
    local PID=$$
    while [[ "$PID" -gt 1 ]]; do
        local T
        T=$(ps -p "$PID" -o tty= 2>/dev/null | tr -d ' ')
        if [[ -n "$T" && "$T" != "??" ]]; then
            echo "$T"
            return
        fi
        PID=$(ps -p "$PID" -o ppid= 2>/dev/null | tr -d ' ')
        [[ -z "$PID" ]] && break
    done
}

RAW_TTY=$(find_tty)
[[ -z "$RAW_TTY" ]] && exit 0

TTY_PATH=$(normalise_tty "$RAW_TTY")

# Determine session key for label file
if [[ -n "$ITERM_SESSION_ID" ]]; then
    SESSION_KEY="iterm-${ITERM_SESSION_ID}"
else
    SESSION_KEY="tty-${RAW_TTY}"
fi

echo "$PROMPT" > "$MARKER_DIR/label-${SESSION_KEY}"

[[ -e "$TTY_PATH" ]] && printf '\033]0;%s\007' "$PROMPT" > "$TTY_PATH"

exit 0
