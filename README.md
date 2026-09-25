# ask-secret

An [Agent Skill](https://agentskills.io) that lets your coding agent (Claude Code, Codex, Cursor, Gemini CLI, Antigravity…)
ask you for passwords, tokens and API keys **without them ever going through the chat**.

When the agent needs a credential, it opens a native macOS dialog with a hidden input field.
You paste the value, click **Save**, and it lands in a `.env` file that the agent uses without ever reading it.

## Install

```bash
git clone https://github.com/cuentadesanti/ask-secret ~/.agents/skills/ask-secret
~/.agents/skills/ask-secret/install.sh
```

`~/.agents/skills` is the shared, tool-agnostic skills folder: Codex and Gemini CLI read it directly.
`install.sh` creates symlinks for the other agents you have installed:

| Agent | Path |
|---|---|
| Codex, Gemini CLI | `~/.agents/skills/ask-secret` (canonical copy) |
| Claude Code | `~/.claude/skills/ask-secret` → symlink |
| Cursor | `~/.cursor/skills/ask-secret` → symlink |
| Antigravity | `~/.gemini/config/skills/ask-secret` → symlink |

To update: `git -C ~/.agents/skills/ask-secret pull`.

## Usage

Nothing to do: when the agent needs a credential, it opens the dialog. You can also use it by hand:

```bash
S=~/.agents/skills/ask-secret/ask-secret.sh

$S -f .env.local OPENAI_API_KEY DB_PASSWORD    # one dialog per secret
$S -f .env.local --list                        # names only, never values
$S -f .env.local run -- node script.js         # run with the secrets as environment variables
```

- File format: `NAME=value`, one line per key, unquoted. Existing keys are replaced.
- Default file: `./.env.local`. It is created with mode `600` and added to `.gitignore` when needed.
- `run` reads the file literally: values are never executed as shell code.
  **Don't `source` these files.**
- Exit codes: `0` saved · `1` cancelled or no answer within 10 min · `2` bad usage · `3` could not open the dialog or write the file.

### Sandboxed agents

Codex's sandbox (and similar ones) blocks the dialog and writes outside the workspace. The script
exits with code `3` and a clear message, and the skill tells the agent to rerun it with elevated
permissions, which you approve.

## What it protects against (and what it doesn't)

- ✅ Secrets ending up in the chat transcript, in logs or in command output.
- ✅ Having to open an editor and paste them into a file by hand.
- ❌ It does not stop an agent that deliberately reads the file: it is plain text on your disk and any
  process running as your user can read it. The skill tells the agent not to; to enforce it, deny
  reads of those files in your agent's permission settings.

## Requirements

- macOS for the dialog (it uses `osascript`). `run` and `--list` work anywhere with `zsh`.

## License

MIT
