#!/usr/bin/env bash
# Claude Code statusLine — outputs model | session title | caveman mode
# Runs periodically by Claude Code; reads from files written by hooks.

MARKER_DIR="/tmp/claude-helper"

# Detect session key (mirrors session-title.sh and iterm-attention.sh)
if [[ -n "$ITERM_SESSION_ID" ]]; then
    SESSION_KEY="iterm-${ITERM_SESSION_ID}"
else
    PID=$$
    RAW_TTY=""
    while [[ "$PID" -gt 1 ]]; do
        T=$(ps -p "$PID" -o tty= 2>/dev/null | tr -d ' ')
        if [[ -n "$T" && "$T" != "??" ]]; then
            RAW_TTY="$T"
            break
        fi
        PID=$(ps -p "$PID" -o ppid= 2>/dev/null | tr -d ' ')
        [[ -z "$PID" ]] && break
    done
    [[ -n "$RAW_TTY" ]] && SESSION_KEY="tty-${RAW_TTY}" || SESSION_KEY=""
fi

MODEL=""
LABEL=""
if [[ -n "$SESSION_KEY" ]]; then
    RAW_MODEL=$(cat "$MARKER_DIR/model-${SESSION_KEY}" 2>/dev/null)
    MODEL="${RAW_MODEL#claude-}"
    LABEL=$(cat "$MARKER_DIR/label-${SESSION_KEY}" 2>/dev/null)
    TOKENS=$(cat "$MARKER_DIR/tokens-${SESSION_KEY}" 2>/dev/null)
fi

PARTS=()
[[ -n "$MODEL" ]] && PARTS+=("$MODEL")
[[ -n "$LABEL" ]] && PARTS+=("$LABEL")
[[ -n "$TOKENS" ]] && PARTS+=("$TOKENS")

(IFS=' | '; printf '%s\n' "${PARTS[*]}")
