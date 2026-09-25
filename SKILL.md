---
name: ask-secret
description: Ask the user for a password, token, API key or any other secret through a native macOS dialog and store it in a dotenv file without it ever going through the chat. Use it whenever you need a credential you don't have, instead of asking the user to paste it into the conversation or edit a file by hand.
---

# Ask the user for a secret

Never ask the user to paste secrets into the chat or to open a file and type them in.
Open the dialog instead:

```bash
~/.agents/skills/ask-secret/ask-secret.sh -f <file> NAME [NAME...]
```

- Opens a macOS dialog with a hidden input field for each `NAME`. The user pastes the value and clicks Save.
- Stores `NAME=value` (unquoted, one line per key) in `<file>`. An existing key is replaced.
- Without `-f` it uses `./.env.local`. If the project already has a credentials file
  (e.g. `.env.dev`), use that one.
- Creates the file with mode 600 and adds it to `.gitignore` if it is inside a repo and not already ignored.
- Use descriptive UPPER_SNAKE_CASE names (`DB_PASSWORD`, `OPENAI_API_KEY`).
- Tell the user in one line before opening it ("I'm opening a dialog for you to paste X"), because
  the dialog waits for their answer.

Exit codes: `0` saved · `1` the user cancelled or did not answer within 10 min · `2` bad usage ·
`3` could not open the dialog or write the file.

**Sandboxed agents (Codex and similar):** the sandbox blocks the dialog and writes outside the
workspace (exit code `3`). Run this command outside the sandbox / request elevated permissions.

To see what is stored (names only, never values):

```bash
~/.agents/skills/ask-secret/ask-secret.sh -f <file> --list
```

## Using secrets without seeing them

- Do not `cat`, `grep` or `echo` the file, or read it with your tools: the value would end up in the conversation.
- Load them only inside the command that needs them, with `run`:
  ```bash
  ~/.agents/skills/ask-secret/ask-secret.sh -f .env.local run -- node script.js
  ```
  or read them from the script itself (parse `KEY=value`, splitting on the first `=`).
- **Never** use `source` or `set -a; . file`: values are unquoted and the shell would execute them
  (a value with spaces, `$(...)` or backticks is interpreted as code).
- Avoid passing secrets as command-line arguments (they show up in `ps`); prefer environment variables.
- Never print the values in logs or script output.
