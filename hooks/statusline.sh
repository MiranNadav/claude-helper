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

CYAN="\033[36m"
YELLOW="\033[33m"
RESET="\033[0m"

MODEL=""
LABEL=""
if [[ -n "$SESSION_KEY" ]]; then
    RAW_MODEL=$(cat "$MARKER_DIR/model-${SESSION_KEY}" 2>/dev/null)
    MODEL="${RAW_MODEL#claude-}"
    RAW_LABEL=$(cat "$MARKER_DIR/label-${SESSION_KEY}" 2>/dev/null)
    if [[ ${#RAW_LABEL} -gt 30 ]]; then
        LABEL="${RAW_LABEL:0:30}…"
    else
        LABEL="$RAW_LABEL"
    fi
    TOKENS=$(cat "$MARKER_DIR/tokens-${SESSION_KEY}" 2>/dev/null)
fi

LEFT=""
RIGHT_PARTS=()
[[ -n "$LABEL" ]] && LEFT="$LABEL"
[[ -n "$TOKENS" ]] && RIGHT_PARTS+=("${YELLOW}${TOKENS}${RESET}")
[[ -n "$MODEL" ]] && RIGHT_PARTS+=("${CYAN}${MODEL}${RESET}")

RIGHT=""
for i in "${!RIGHT_PARTS[@]}"; do
    [[ $i -gt 0 ]] && RIGHT+=" | "
    RIGHT+="${RIGHT_PARTS[$i]}"
done

if [[ -n "$LEFT" && -n "$RIGHT" ]]; then
    printf '%b\n' "${LEFT} | ${RIGHT}"
elif [[ -n "$LEFT" ]]; then
    printf '%b\n' "$LEFT"
elif [[ -n "$RIGHT" ]]; then
    printf '%b\n' "$RIGHT"
fi
