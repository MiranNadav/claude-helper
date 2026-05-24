#!/usr/bin/env bash
# Fires on PreToolUse, PostToolUse, UserPromptSubmit, Stop.

INPUT=$(cat)
MARKER_DIR="/tmp/claude-helper"
mkdir -p "$MARKER_DIR"

# Walk process tree to find TTY
PID=$$
TTY_PATH=""
while [[ "$PID" -gt 1 ]]; do
    T=$(ps -p "$PID" -o tty= 2>/dev/null | tr -d ' ')
    if [[ -n "$T" && "$T" != "??" ]]; then
        [[ "$T" == tty* ]] && TTY_PATH="/dev/$T" || TTY_PATH="/dev/tty$T"
        break
    fi
    PID=$(ps -p "$PID" -o ppid= 2>/dev/null | tr -d ' ')
    [[ -z "$PID" ]] && break
done

[[ -z "$TTY_PATH" || ! -e "$TTY_PATH" ]] && exit 0

RAW_TTY="${TTY_PATH#/dev/}"
if [[ -n "$ITERM_SESSION_ID" ]]; then
    SESSION_KEY="iterm-${ITERM_SESSION_ID}"
else
    SESSION_KEY="tty-${RAW_TTY}"
fi

HOOK_EVENT=$(echo "$INPUT" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('hook_event_name',''))" 2>/dev/null)
TRANSCRIPT_PATH=$(echo "$INPUT" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('transcript_path',''))" 2>/dev/null)

# Always clear any stale badge
printf '\033]1337;SetBadgeFormat=%s\007' "$(echo -n '' | base64)" > "$TTY_PATH"

set_waiting() {
    printf '\033]1337;SetColors=tab=00E600\007' > "$TTY_PATH"
    printf '\033]6;1;bg;red;brightness;0\007' > "$TTY_PATH"
    printf '\033]6;1;bg;green;brightness;230\007' > "$TTY_PATH"
    printf '\033]6;1;bg;blue;brightness;0\007' > "$TTY_PATH"
    printf '\033]1337;SetColors=bg=001a00\007' > "$TTY_PATH"
}

clear_waiting() {
    printf '\033]6;1;bg;red;brightness;0\007' > "$TTY_PATH"
    printf '\033]6;1;bg;green;brightness;0\007' > "$TTY_PATH"
    printf '\033]6;1;bg;blue;brightness;0\007' > "$TTY_PATH"
    printf '\033]111\007' > "$TTY_PATH"
}

case "$HOOK_EVENT" in
    PreToolUse)
        set_waiting
        ;;
    PostToolUse|UserPromptSubmit)
        clear_waiting
        ;;
    Stop)
        clear_waiting
        if [[ -f "$TRANSCRIPT_PATH" ]]; then
            python3 - "$TRANSCRIPT_PATH" "$MARKER_DIR" "$SESSION_KEY" << 'PYEOF'
import json, sys

path, marker, session_key = sys.argv[1], sys.argv[2], sys.argv[3]
model = ''
total_input = 0
total_cache_read = 0
total_output = 0

try:
    with open(path) as f:
        for line in f:
            line = line.strip()
            if not line:
                continue
            try:
                d = json.loads(line)
            except Exception:
                continue
            if d.get('type') == 'assistant':
                msg = d.get('message', {})
                if not model and msg.get('model'):
                    model = msg['model'].replace('claude-', '', 1)
                usage = msg.get('usage', {})
                total_input += usage.get('input_tokens', 0)
                total_cache_read += usage.get('cache_read_input_tokens', 0)
                total_output += usage.get('output_tokens', 0)
except Exception:
    sys.exit(0)

def fmt(n):
    if n >= 1_000_000:
        return f'{n/1_000_000:.1f}m'
    if n >= 1000:
        return f'{n/1000:.1f}k'
    return str(n)

if model:
    with open(f'{marker}/model-{session_key}', 'w') as f:
        f.write(model)

tokens = f'in:{fmt(total_input + total_cache_read)} out:{fmt(total_output)}'
with open(f'{marker}/tokens-{session_key}', 'w') as f:
    f.write(tokens)
PYEOF
        fi
        ;;
esac

MODEL=$(cat "$MARKER_DIR/model-${SESSION_KEY}" 2>/dev/null)
LABEL=$(cat "$MARKER_DIR/label-${SESSION_KEY}" 2>/dev/null)
TOKENS=$(cat "$MARKER_DIR/tokens-${SESSION_KEY}" 2>/dev/null)
STATUS="${MODEL:+[$MODEL] }${LABEL}${TOKENS:+ | $TOKENS}"
printf '\033]1337;SetUserVar=claude_status=%s\007' "$(echo -n "$STATUS" | base64)" > "$TTY_PATH"

exit 0
