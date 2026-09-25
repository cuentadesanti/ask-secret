#!/bin/zsh
# Abre una ventanita de macOS para que el usuario pegue un secreto y lo guarda en un archivo dotenv.
# El valor nunca se imprime: solo se escribe en el archivo (permisos 600).
#
# Uso:
#   pedir-secreto.sh [-f ARCHIVO] NOMBRE [NOMBRE...]   pide cada NOMBRE y lo guarda como NOMBRE=valor
#   pedir-secreto.sh [-f ARCHIVO] --list               muestra solo los nombres guardados
#   pedir-secreto.sh [-f ARCHIVO] run -- COMANDO...    ejecuta COMANDO con los secretos como variables de entorno
# ARCHIVO por defecto: ./.env.local

set -u
file=".env.local"
if [[ "${1:-}" == "-f" ]]; then file="$2"; shift 2; fi

if [[ "${1:-}" == "run" ]]; then
  shift
  [[ "${1:-}" == "--" ]] && shift
  (( $# > 0 )) || { echo "Uso: pedir-secreto.sh [-f ARCHIVO] run -- COMANDO..." >&2; exit 2; }
  [[ -f "$file" ]] || { echo "No existe $file" >&2; exit 1; }
  # Lee el archivo literalmente: el valor nunca se evalúa como código de shell.
  while IFS= read -r line || [[ -n "$line" ]]; do
    [[ "$line" =~ '^[A-Za-z_][A-Za-z0-9_]*=' ]] || continue
    export "${line%%=*}=${line#*=}"
  done < "$file"
  exec "$@"
fi

if [[ "${1:-}" == "--list" ]]; then
  [[ -f "$file" ]] || { echo "No existe $file"; exit 0; }
  grep -oE '^[A-Za-z_][A-Za-z0-9_]*=' "$file" | tr -d '='
  exit 0
fi

(( $# > 0 )) || { echo "Uso: pedir-secreto.sh [-f ARCHIVO] NOMBRE [NOMBRE...] | --list" >&2; exit 2; }

[[ "$(uname)" == Darwin ]] || { echo "La ventana por ahora solo funciona en macOS (usa osascript)." >&2; exit 3; }

if ! { touch "$file" && chmod 600 "$file"; } 2>/dev/null; then
  echo "No se puede escribir en $file. Si el agente corre en un sandbox (p. ej. Codex)," >&2
  echo "ejecuta este comando fuera del sandbox / con permisos elevados." >&2
  exit 3
fi
abs="${file:A}"

# Si está en un repo git y no está ignorado, lo añade al .gitignore.
if root=$(git -C "${abs:h}" rev-parse --show-toplevel 2>/dev/null); then
  if ! git -C "$root" check-ignore -q "$abs"; then
    printf '\n%s\n' "${abs#$root/}" >> "$root/.gitignore"
    echo "Añadido ${abs#$root/} a $root/.gitignore"
  fi
fi

for name in "$@"; do
  if [[ ! "$name" =~ '^[A-Za-z_][A-Za-z0-9_]*$' ]]; then
    echo "Nombre inválido: $name" >&2; exit 2
  fi

  err=$(mktemp)
  value=$(osascript \
    -e 'on run argv' \
    -e 'activate' \
    -e 'set r to display dialog ("Pega el valor de " & item 1 of argv & return & return & "Se guardará en " & item 2 of argv) default answer "" with hidden answer with title "Secreto para tu agente" buttons {"Cancelar", "Guardar"} default button "Guardar" cancel button "Cancelar" giving up after 600' \
    -e 'if gave up of r then error number -128' \
    -e 'return text returned of r' \
    -e 'end run' \
    "$name" "$abs" 2>"$err")
  code=$?
  msg=$(<"$err"); rm -f "$err"
  if (( code != 0 )); then
    if [[ "$msg" == *"-128"* ]]; then echo "$name: cancelado"; exit 1; fi
    echo "$name: no se pudo abrir la ventana. Si el agente corre en un sandbox (p. ej. Codex)," >&2
    echo "ejecuta este comando fuera del sandbox / con permisos elevados. Detalle: $msg" >&2
    exit 3
  fi

  value="${value//$'\r'/}"
  value="${value//$'\n'/}"
  if [[ -z "$value" ]]; then echo "$name: vacío, no se guarda"; continue; fi

  tmp="${abs}.tmp.$$"
  ( umask 077; grep -v "^${name}=" "$abs" > "$tmp"; printf '%s=%s\n' "$name" "$value" >> "$tmp" )
  mv "$tmp" "$abs"
  unset value
  echo "$name: guardado en $abs"
done
