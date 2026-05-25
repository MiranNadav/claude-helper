# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Purpose

Terminal companion/extension for Claude Code. Surfaces context that Claude Code doesn't show by default — session labels in the title bar, iTerm2 tab highlighting when approval is needed, and a status line showing model, token usage, and session label.

## Requirements

- macOS
- iTerm2 (escape sequences used for tab color, badge, and user vars)
- Python 3 (transcript parsing in `iterm-attention.sh`)

## Architecture

Hooks live in `hooks/`. Each hook is a standalone shell script wired into `~/.claude/settings.json` under the relevant event (`UserPromptSubmit`, `PreToolUse`, `PostToolUse`, `Stop`, `StatusLine`).

Hook input arrives via stdin as JSON. Output to stdout is captured by Claude Code; use `/dev/tty` for anything that must reach the terminal directly.

Marker files under `/tmp/claude-helper/` share state between hooks and the status line:
- `label-<SESSION_KEY>` — current session label (first prompt, truncated to 80 chars)
- `model-<SESSION_KEY>` — model name (stripped of `claude-` prefix)
- `tokens-<SESSION_KEY>` — formatted token counts (`in:Xk out:Yk`)

Session key is `iterm-<ITERM_SESSION_ID>` when inside iTerm2, otherwise `tty-<TTY>`.

## Hooks

| File | Event(s) | What it does |
|------|----------|-------------|
| `hooks/session-title.sh` | `UserPromptSubmit` | Sets terminal window/tab title to current prompt; writes label to marker file |
| `hooks/iterm-attention.sh` | `PermissionRequest`, `PostToolUse`, `UserPromptSubmit`, `Stop` | On `PermissionRequest`: highlights iTerm2 tab green + plays sound when user is prompted for tool approval; clears on `PostToolUse`/`UserPromptSubmit`; on `Stop`: parses transcript, writes model + token marker files, sets iTerm2 user var `claude_status` |
| `hooks/statusline.sh` | `StatusLine` | Reads marker files, outputs `label \| tokens \| model` to Claude Code's status bar |

Approval detection uses the `PermissionRequest` hook event, which fires only when Claude Code is about to show a permission prompt to the user. No allowlist needed.

## Installing a new hook

1. Add script to `hooks/`
2. `chmod +x hooks/<name>.sh`
3. Add entry to `~/.claude/settings.json` under the relevant event key
