#!/bin/zsh
# Opens a native macOS dialog so the user can paste a secret, and stores it in a dotenv file.
# The value is never printed: it is only written to the file (mode 600).
#
# Usage:
#   ask-secret.sh [-f FILE] NAME [NAME...]    ask for each NAME and store it as NAME=value
#   ask-secret.sh [-f FILE] --list            print stored names only
#   ask-secret.sh [-f FILE] run -- COMMAND... run COMMAND with the secrets as environment variables
# Default FILE: ./.env.local

set -u
file=".env.local"
if [[ "${1:-}" == "-f" ]]; then file="$2"; shift 2; fi

if [[ "${1:-}" == "run" ]]; then
  shift
  [[ "${1:-}" == "--" ]] && shift
  (( $# > 0 )) || { echo "Usage: ask-secret.sh [-f FILE] run -- COMMAND..." >&2; exit 2; }
  [[ -f "$file" ]] || { echo "$file does not exist" >&2; exit 1; }
  # Read the file literally: values are never evaluated as shell code.
  while IFS= read -r line || [[ -n "$line" ]]; do
    [[ "$line" =~ '^[A-Za-z_][A-Za-z0-9_]*=' ]] || continue
    export "${line%%=*}=${line#*=}"
  done < "$file"
  exec "$@"
fi

if [[ "${1:-}" == "--list" ]]; then
  [[ -f "$file" ]] || { echo "$file does not exist"; exit 0; }
  grep -oE '^[A-Za-z_][A-Za-z0-9_]*=' "$file" | tr -d '='
  exit 0
fi

(( $# > 0 )) || { echo "Usage: ask-secret.sh [-f FILE] NAME [NAME...] | --list | run -- COMMAND..." >&2; exit 2; }

[[ "$(uname)" == Darwin ]] || { echo "The dialog currently only works on macOS (it uses osascript)." >&2; exit 3; }

if ! { touch "$file" && chmod 600 "$file"; } 2>/dev/null; then
  echo "Cannot write to $file. If the agent runs in a sandbox (e.g. Codex)," >&2
  echo "run this command outside the sandbox / with elevated permissions." >&2
  exit 3
fi
abs="${file:A}"

# If the file is inside a git repo and not ignored, add it to .gitignore.
if root=$(git -C "${abs:h}" rev-parse --show-toplevel 2>/dev/null); then
  if ! git -C "$root" check-ignore -q "$abs"; then
    printf '\n%s\n' "${abs#$root/}" >> "$root/.gitignore"
    echo "Added ${abs#$root/} to $root/.gitignore"
  fi
fi

for name in "$@"; do
  if [[ ! "$name" =~ '^[A-Za-z_][A-Za-z0-9_]*$' ]]; then
    echo "Invalid name: $name" >&2; exit 2
  fi

  err=$(mktemp)
  value=$(osascript \
    -e 'on run argv' \
    -e 'activate' \
    -e 'set r to display dialog ("Paste the value for " & item 1 of argv & return & return & "It will be saved to " & item 2 of argv) default answer "" with hidden answer with title "Secret for your agent" buttons {"Cancel", "Save"} default button "Save" cancel button "Cancel" giving up after 600' \
    -e 'if gave up of r then error number -128' \
    -e 'return text returned of r' \
    -e 'end run' \
    "$name" "$abs" 2>"$err")
  code=$?
  msg=$(<"$err"); rm -f "$err"
  if (( code != 0 )); then
    if [[ "$msg" == *"-128"* ]]; then echo "$name: cancelled"; exit 1; fi
    echo "$name: could not open the dialog. If the agent runs in a sandbox (e.g. Codex)," >&2
    echo "run this command outside the sandbox / with elevated permissions. Details: $msg" >&2
    exit 3
  fi

  value="${value//$'\r'/}"
  value="${value//$'\n'/}"
  if [[ -z "$value" ]]; then echo "$name: empty, not saved"; continue; fi

  tmp="${abs}.tmp.$$"
  ( umask 077; grep -v "^${name}=" "$abs" > "$tmp"; printf '%s=%s\n' "$name" "$value" >> "$tmp" )
  mv "$tmp" "$abs"
  unset value
  echo "$name: saved to $abs"
done
