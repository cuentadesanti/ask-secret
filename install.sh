#!/bin/zsh
# Installs the skill for every detected agent.
# The canonical copy lives in ~/.agents/skills/ask-secret (read directly by Codex and Gemini CLI);
# other agents get a symlink. An agent is only linked if it is installed (its home folder exists).
set -eu
src="${0:A:h}"
canon="$HOME/.agents/skills/ask-secret"

if [[ "$src" != "$canon" ]]; then
  mkdir -p "${canon:h}"
  [[ -e "$canon" ]] && { echo "$canon already exists; remove it before reinstalling from another path." >&2; exit 1; }
  cp -R "$src" "$canon"
  echo "Copied to $canon (Codex, Gemini CLI)"
else
  echo "Canonical copy at $canon (Codex, Gemini CLI)"
fi
chmod +x "$canon/ask-secret.sh"

# agent:agent-home:skills-dir
for entry in \
  "Claude Code:$HOME/.claude:$HOME/.claude/skills" \
  "Cursor:$HOME/.cursor:$HOME/.cursor/skills" \
  "Antigravity:$HOME/.gemini/antigravity:$HOME/.gemini/config/skills"; do
  agent="${entry%%:*}"; rest="${entry#*:}"; home="${rest%%:*}"; dir="${rest#*:}"
  [[ -d "$home" ]] || { echo "$agent: not installed, skipped"; continue; }
  link="$dir/ask-secret"
  if [[ -L "$link" ]]; then ln -sfn "$canon" "$link"
  elif [[ -e "$link" ]]; then echo "$agent: $link exists and is not a symlink; leaving it alone" >&2; continue
  else mkdir -p "$dir"; ln -s "$canon" "$link"; fi
  echo "$agent: linked $link"
done
