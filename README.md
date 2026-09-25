# pedir-secreto

Una [Agent Skill](https://agentskills.io) para que tu agente de código (Claude Code, Codex, Cursor, Gemini CLI, Antigravity…)
te pida contraseñas, tokens y API keys **sin que pasen por el chat**.

Cuando el agente necesita una credencial, abre una ventanita nativa de macOS con el campo oculto.
Pegas el valor, pulsas **Guardar** y queda en un archivo `.env` que el agente usa sin leerlo nunca.

> **EN:** An Agent Skill that lets your coding agent ask you for secrets through a native macOS
> password dialog and store them in a dotenv file, so they never go through the chat transcript.
> Secrets are then injected into commands with `pedir-secreto.sh run -- <cmd>` without the agent seeing them.

## Instalación

```bash
git clone https://github.com/cuentadesanti/pedir-secreto ~/.agents/skills/pedir-secreto
~/.agents/skills/pedir-secreto/install.sh
```

`~/.agents/skills` es el directorio estándar compartido: Codex y Gemini CLI lo leen directamente.
`install.sh` crea enlaces simbólicos para los agentes que tengas instalados:

| Agente | Ruta |
|---|---|
| Codex, Gemini CLI | `~/.agents/skills/pedir-secreto` (copia principal) |
| Claude Code | `~/.claude/skills/pedir-secreto` → enlace |
| Cursor | `~/.cursor/skills/pedir-secreto` → enlace |
| Antigravity | `~/.gemini/config/skills/pedir-secreto` → enlace |

Para actualizar: `git -C ~/.agents/skills/pedir-secreto pull`.

## Uso

No tienes que hacer nada: cuando el agente necesite una credencial, te abrirá la ventana. También puedes usarlo a mano:

```bash
S=~/.agents/skills/pedir-secreto/pedir-secreto.sh

$S -f .env.local OPENAI_API_KEY DB_PASSWORD    # una ventana por secreto
$S -f .env.local --list                        # solo nombres, nunca valores
$S -f .env.local run -- node script.js         # ejecuta con los secretos como variables de entorno
```

- Formato del archivo: `NOMBRE=valor`, una línea por clave, sin comillas. Si la clave existe, se reemplaza.
- Archivo por defecto: `./.env.local`. Se crea con permisos `600` y se añade a `.gitignore` si hace falta.
- `run` lee el archivo literalmente: los valores nunca se ejecutan como código de shell.
  **No uses `source`** con estos archivos.
- Códigos de salida: `0` guardado · `1` cancelado o sin respuesta en 10 min · `2` uso incorrecto · `3` no se pudo abrir la ventana o escribir el archivo.

### Agentes con sandbox

El sandbox de Codex (y similares) bloquea el diálogo y la escritura fuera del workspace. El script
sale con código `3` y un mensaje claro, y la skill le indica al agente que lo ejecute con permisos
elevados, que tendrás que aprobar.

## Qué protege y qué no

- ✅ Que un secreto acabe en el historial del chat, en logs o en la salida de un comando.
- ✅ Que tengas que abrir un editor y pegarlo a mano en un archivo.
- ❌ No protege frente a un agente que quiera leer el archivo a propósito: queda en texto plano en tu
  disco y cualquier proceso de tu usuario puede leerlo. La skill le pide al agente que no lo haga; si
  quieres garantizarlo, bloquea la lectura de esos archivos en los permisos de tu agente.

## Requisitos

- macOS (usa `osascript` para la ventana). `run` y `--list` funcionan en cualquier sistema con `zsh`.

## Licencia

MIT
