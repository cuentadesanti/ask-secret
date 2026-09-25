---
name: pedir-secreto
description: Pide al usuario una contraseña, token, API key o cualquier secreto mediante una ventanita nativa de macOS y lo guarda en un archivo dotenv sin que pase por el chat. Úsalo siempre que necesites una credencial que no tengas, en lugar de pedir que la peguen en la conversación o que editen un archivo a mano.
---

# Pedir un secreto al usuario

Nunca pidas al usuario que pegue secretos en el chat ni que abra un archivo para escribirlos.
Lanza la ventanita:

```bash
~/.agents/skills/pedir-secreto/pedir-secreto.sh -f <archivo> NOMBRE [NOMBRE...]
```

- Abre un diálogo de macOS con campo oculto por cada `NOMBRE`. El usuario pega el valor y pulsa Guardar.
- Guarda `NOMBRE=valor` (sin comillas, una línea por clave) en `<archivo>`. Si la clave ya existe, la reemplaza.
- Si no se pasa `-f`, usa `./.env.local`. Si el proyecto ya tiene un archivo de credenciales
  (p. ej. `.env.dev`), usa ese.
- Crea el archivo con permisos 600 y lo añade a `.gitignore` si está en un repo y no estaba ignorado.
- Usa nombres en MAYÚSCULAS_CON_GUIONES_BAJOS que describan bien el secreto (`ACTUAL_DEV_PASSWORD`, `OPENAI_API_KEY`).
- Avisa al usuario en una línea antes de lanzarlo ("te abro una ventana para que pegues X"), porque
  el diálogo espera respuesta.

Códigos de salida: `0` guardado · `1` el usuario canceló o no respondió en 10 min · `2` uso incorrecto ·
`3` no se pudo abrir la ventana.

**Agentes con sandbox (Codex y similares):** el sandbox bloquea el diálogo (sale con código `3`).
Ejecuta este comando fuera del sandbox / pidiendo permisos elevados; también necesita escribir en
`<archivo>`.

Para saber qué hay guardado (solo nombres, nunca valores):

```bash
~/.agents/skills/pedir-secreto/pedir-secreto.sh -f <archivo> --list
```

## Usar los secretos sin verlos

- No hagas `cat`, `grep`, `echo` ni leas el archivo con tus herramientas: el valor entraría en la conversación.
- Cárgalos solo dentro del comando que los necesita, con `run`:
  ```bash
  ~/.agents/skills/pedir-secreto/pedir-secreto.sh -f .env.local run -- node script.cjs
  ```
  o léelos desde el propio script (Node: parsear `KEY=valor` separando por el primer `=`).
- **Nunca** uses `source` ni `set -a; . archivo`: los valores van sin comillas y la shell los
  ejecutaría (un valor con espacios, `$(...)` o comillas invertidas se interpreta como código).
- No los pases como argumentos de línea de comandos si se puede evitar (se ven en `ps`); mejor por variable de entorno.
- No imprimas los valores en logs ni en la salida de los scripts.
