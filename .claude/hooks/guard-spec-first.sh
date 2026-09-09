#!/usr/bin/env bash
# guard-spec-first.sh — hook PreToolUse (Write|Edit|NotebookEdit).
#
# La "regla de oro" de AGENTS.md dice que no se toca código de producción sin una spec
# aprobada. Hasta ahora eso era solo prosa: dependía de que el modelo se acordara en cada
# turno. Este hook lo hace insaltable.
#
# Bloquea escrituras sobre ficheros de producción salvo que en tasks.json haya al menos
# una tarea con status "in_progress" (que es el estado al que solo se llega tras la
# aprobación humana de la spec, o directamente si la tarea es "use_sdd": false).
#
# Los ficheros del propio arnés (specs/, progress/, docs/, rules/, tasks.json...) se
# escriben siempre: son justo lo que hay que poder editar ANTES de tener una spec.
#
# Escape hatch: SDD_GUARD=off claude
#
# Salida: exit 2 = bloqueado, y stderr se le devuelve a Claude como motivo.

set -uo pipefail

[ "${SDD_GUARD:-on}" = "off" ] && exit 0

RAIZ="${CLAUDE_PROJECT_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)}"
payload=$(cat)

# --- extraer la ruta del fichero que se quiere escribir ---
ruta=""
if command -v python3 >/dev/null 2>&1; then
  ruta=$(printf '%s' "$payload" | python3 -c '
import json,sys
try:
    d = json.load(sys.stdin)
except Exception:
    sys.exit(0)
ti = d.get("tool_input") or {}
print(ti.get("file_path") or ti.get("notebook_path") or "")
' 2>/dev/null)
else
  ruta=$(printf '%s' "$payload" | sed -n 's/.*"\(file_path\|notebook_path\)"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\2/p' | head -1)
fi

# Sin ruta legible no hay nada que juzgar: no bloqueamos por no entender el payload.
[ -n "$ruta" ] || exit 0

# Normalizar a ruta relativa a la raíz del repo.
case "$ruta" in
  /*) abs="$ruta" ;;
  *)  abs="$PWD/$ruta" ;;
esac
abs=$(printf '%s' "$abs" | sed 's://*:/:g')
case "$abs" in
  "$RAIZ"/*) rel="${abs#"$RAIZ"/}" ;;
  *) exit 0 ;;  # fuera del repo (scratchpad, ~/.claude...): no es asunto de este hook
esac

# --- ficheros del arnés: siempre permitidos ---
case "$rel" in
  specs/*|progress/*|docs/*|rules/*|.claude/*) exit 0 ;;
  tasks.json|history.md|instincts.md|prompts.md|AGENTS.md|CLAUDE.md|README.md|GUIA_DE_USO.md|init.sh|.gitignore|.gitignore.example) exit 0 ;;
esac

# --- ¿hay alguna tarea in_progress? ---
hay_in_progress=1
if [ -f "$RAIZ/tasks.json" ]; then
  if command -v python3 >/dev/null 2>&1; then
    python3 -c '
import json,sys
try:
    t = json.load(open(sys.argv[1])).get("tasks", [])
except Exception:
    sys.exit(1)
sys.exit(0 if any(x.get("status") == "in_progress" for x in t) else 1)
' "$RAIZ/tasks.json" && hay_in_progress=0
  else
    grep -qE '"status"[[:space:]]*:[[:space:]]*"in_progress"' "$RAIZ/tasks.json" && hay_in_progress=0
  fi
fi

[ "$hay_in_progress" -eq 0 ] && exit 0

cat >&2 <<MSG
BLOQUEADO por el arnés SDD: '$rel' es código de producción y ahora mismo no hay ninguna
tarea con status "in_progress" en tasks.json.

La regla de oro de AGENTS.md: no se implementa nada sin spec aprobada por el humano.

Salidas legítimas, según en qué fase estés:
  - Falta la spec        -> lanza al spec-author; escribe en specs/<feature>/, no aquí.
  - Spec en spec_ready   -> pídele al humano que la apruebe y pon la tarea en in_progress.
  - Tarea trivial        -> márcala "use_sdd": false y pásala a in_progress.
  - Review en curso      -> el reviewer no arregla el código que juzga; RECHAZA con notas
                            y que el leader devuelva la tarea a in_progress.

No intentes rodear esto escribiendo el fichero por Bash: sería saltarse el mismo gate.
Si de verdad hace falta desactivarlo, es decisión del humano: SDD_GUARD=off claude
MSG
exit 2
