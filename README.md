# claude-helper

Terminal companion for [Claude Code](https://claude.ai/code). Surfaces context the CLI doesn't show by default:

- **Session title** — terminal tab/window title tracks the current conversation prompt
- **Attention highlight** — iTerm2 tab turns green and plays a sound when Claude needs your approval; clears automatically when you respond
- **Status line** — model name, token usage (`in/out`), and session label displayed in Claude Code's status bar

## Requirements

- macOS
- [iTerm2](https://iterm2.com) (escape sequences for tab color, badge, user variables)
- Python 3 (bundled on macOS)
- Claude Code CLI

## Hooks

| Script | Event(s) | Purpose |
|--------|----------|---------|
| `hooks/session-title.sh` | `UserPromptSubmit` | Sets terminal title to the current prompt |
| `hooks/iterm-attention.sh` | `PreToolUse`, `PostToolUse`, `UserPromptSubmit`, `Stop` | Tab highlight + sound on approval-required tools; parses transcript on stop to write model/token stats |
| `hooks/statusline.sh` | `StatusLine` | Outputs `label \| in:Xk out:Yk \| model` to Claude Code's status bar |

## Installation

### 1. Clone the repo

```bash
git clone https://github.com/nadavmiran/claude-helper.git ~/Repositories/claude-helper
```

### 2. Make hooks executable

```bash
chmod +x ~/Repositories/claude-helper/hooks/*.sh
```

### 3. Wire hooks into `~/.claude/settings.json`

Run the install script — it merges the hook entries into your existing `~/.claude/settings.json` without overwriting anything else:

```bash
bash ~/Repositories/claude-helper/install.sh
```

The script is idempotent; running it again is safe. It exits with a summary of what was added (or "nothing to do" if already installed).

<details>
<summary>Manual configuration (if you prefer)</summary>

Add the following under the `"hooks"` key. Adjust the repo path if you cloned elsewhere.

```json
{
  "hooks": {
    "UserPromptSubmit": [
      {
        "matcher": "",
        "hooks": [
          { "type": "command", "command": "bash \"/Users/YOUR_USERNAME/Repositories/claude-helper/hooks/session-title.sh\"" },
          { "type": "command", "command": "bash \"/Users/YOUR_USERNAME/Repositories/claude-helper/hooks/iterm-attention.sh\"" }
        ]
      }
    ],
    "PreToolUse": [
      { "matcher": "", "hooks": [{ "type": "command", "command": "bash \"/Users/YOUR_USERNAME/Repositories/claude-helper/hooks/iterm-attention.sh\"" }] }
    ],
    "PostToolUse": [
      { "matcher": "", "hooks": [{ "type": "command", "command": "bash \"/Users/YOUR_USERNAME/Repositories/claude-helper/hooks/iterm-attention.sh\"" }] }
    ],
    "Stop": [
      { "matcher": "", "hooks": [{ "type": "command", "command": "bash \"/Users/YOUR_USERNAME/Repositories/claude-helper/hooks/iterm-attention.sh\"" }] }
    ],
    "StatusLine": [
      { "matcher": "", "hooks": [{ "type": "command", "command": "bash \"/Users/YOUR_USERNAME/Repositories/claude-helper/hooks/statusline.sh\"" }] }
    ]
  }
}
```

Replace `YOUR_USERNAME` with your macOS username.
</details>

### 4. Restart Claude Code

Changes to `settings.json` take effect on the next session.

## How it works

All hooks share state via marker files in `/tmp/claude-helper/`. The session key is `iterm-<ITERM_SESSION_ID>` inside iTerm2, or `tty-<TTY>` otherwise. This lets the status line script read data written by the attention hook without any inter-process communication.

The attention hook skips highlighting for tools that never require user approval (`Read`, `Glob`, `Grep`, `LS`, `WebSearch`, `WebFetch`, `TodoRead`, `TaskGet`, `TaskList`, `TaskOutput`, `Bash`). All other tools trigger the green highlight + sound until you respond.
