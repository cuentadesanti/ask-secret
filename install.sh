#!/bin/zsh
# Instala la skill para todos los agentes detectados.
# La copia canónica vive en ~/.agents/skills/pedir-secreto (la leen Codex y Gemini CLI directamente);
# en el resto se crea un enlace simbólico. Solo se enlaza si el agente está instalado (existe su carpeta).
set -eu
src="${0:A:h}"
canon="$HOME/.agents/skills/pedir-secreto"

if [[ "$src" != "$canon" ]]; then
  mkdir -p "${canon:h}"
  [[ -e "$canon" ]] && { echo "Ya existe $canon; bórralo antes de reinstalar desde otra ruta." >&2; exit 1; }
  cp -R "$src" "$canon"
  echo "Copiado a $canon (Codex, Gemini CLI)"
else
  echo "Canónica en $canon (Codex, Gemini CLI)"
fi
chmod +x "$canon/pedir-secreto.sh"

# agente:carpeta-del-agente:carpeta-de-skills
for entry in \
  "Claude Code:$HOME/.claude:$HOME/.claude/skills" \
  "Cursor:$HOME/.cursor:$HOME/.cursor/skills" \
  "Antigravity:$HOME/.gemini/antigravity:$HOME/.gemini/config/skills"; do
  agent="${entry%%:*}"; rest="${entry#*:}"; home="${rest%%:*}"; dir="${rest#*:}"
  [[ -d "$home" ]] || { echo "$agent: no instalado, se omite"; continue; }
  link="$dir/pedir-secreto"
  if [[ -L "$link" ]]; then ln -sfn "$canon" "$link"
  elif [[ -e "$link" ]]; then echo "$agent: $link existe y no es un enlace; no lo toco" >&2; continue
  else mkdir -p "$dir"; ln -s "$canon" "$link"; fi
  echo "$agent: enlazado $link"
done
