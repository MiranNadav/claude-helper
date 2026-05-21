# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Purpose

Terminal companion/extension for Claude Code. Surfaces context that Claude Code doesn't show by default — starting with labeling terminal windows by session so you can tell which window runs which conversation.

## Architecture

Hooks live in `hooks/`. Each hook is a standalone shell script (or can be Node.js) wired into `~/.claude/settings.json` under the relevant event (`UserPromptSubmit`, `PostToolUse`, etc.).

Hook input arrives via stdin as JSON. Output to stdout is captured by Claude; use `/dev/tty` for anything that must reach the terminal directly.

Session deduplication uses marker files under `/tmp/claude-helper/<session_id>`.

## Hooks

| File | Event | What it does |
|------|-------|-------------|
| `hooks/session-title.sh` | `UserPromptSubmit` | Sets terminal window title to first user message of session |

## Installing a new hook

1. Add script to `hooks/`
2. `chmod +x hooks/<name>.sh`
3. Add entry to `~/.claude/settings.json` under the relevant event key
