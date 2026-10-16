#!/usr/bin/env bash
# init.sh — verificación de entorno + tests.
# Todos los agentes (leader, implementer, reviewer) lo ejecutan y no pueden darse por
# terminados si no termina en verde.
#
# Este script falla A PROPÓSITO en una instalación recién copiada. Un arnés cuyo único
# gate objetivo devuelve "OK" sin ejecutar nada es peor que no tener gate: da confianza
# falsa. Rellena la sección CONFIGURAR (RUTAS_TESTS y los CMD_*) y pon
# PROYECTO_CONFIGURADO=true.
#
# Uso:
#   ./init.sh            verificación completa (deps, lint, suite de tests, trazabilidad)
#   ./init.sh --rapido   solo lint + CMD_RAPIDO, para tareas de nivel "rapido"
#
# La salida es deliberadamente corta: cada línea que llega al chat la paga el modelo. Un paso
# que pasa imprime una línea; uno que falla, solo las últimas INIT_MAX_LINEAS (40 por defecto).
# Para ver la salida entera al depurar a mano: INIT_VERBOSE=1 ./init.sh

set -euo pipefail

MODO=completo
case "${1:-}" in
  --rapido) MODO=rapido ;;
  "") ;;
  *) echo "uso: $0 [--rapido]" >&2; exit 2 ;;
esac

# ---------------------------------------------------------------------------
# CONFIGURAR: ponlo a true cuando hayas rellenado RUTAS_TESTS y los CMD_* de abajo.
# ---------------------------------------------------------------------------
PROYECTO_CONFIGURADO=false

# Rutas donde viven los tests, separadas por espacios. Se usan para el check de
# trazabilidad RF→test. Déjalo vacío para saltarte ese check.
RUTAS_TESTS=""

# Comandos reales del stack. Uno vacío se salta, avisándolo en una línea.
CMD_ENTORNO=""   # ej: command -v node >/dev/null
CMD_DEPS=""      # ej: npm ci --silent / composer install -q / pip install -q -r requirements.txt
CMD_LINT=""      # ej: npm run -s lint / ./vendor/bin/pint --test / ruff check .
CMD_TESTS=""     # ej: npm test --silent / php artisan test / pytest -q
# Lo que corre --rapido además del lint: algo que tarde segundos y pille lo que un cambio de
# estilos o textos puede romper (typecheck, build, snapshots). Vacío = solo lint.
CMD_RAPIDO=""    # ej: npx tsc --noEmit / npm run -s build

fallo() { echo "ERROR: $*" >&2; exit 1; }

MAX_LINEAS="${INIT_MAX_LINEAS:-40}"
# paso <nombre> <comando>: en silencio si pasa, solo la cola de la salida si falla.
paso() {
  local nombre="$1" cmd="$2" log
  if [ -z "$cmd" ]; then
    echo "    $nombre: sin configurar, saltado"
    return 0
  fi
  if [ "${INIT_VERBOSE:-0}" = "1" ]; then
    bash -c "$cmd" || fallo "$nombre falló ($cmd)"
    return 0
  fi
  log=$(mktemp)
  if bash -c "$cmd" >"$log" 2>&1; then
    echo "    $nombre: OK"
    rm -f "$log"
  else
    echo "ERROR: $nombre falló ($cmd). Últimas $MAX_LINEAS líneas:" >&2
    tail -n "$MAX_LINEAS" "$log" >&2
    rm -f "$log"
    exit 1
  fi
}

# ---------------------------------------------------------------------------
# Checks del propio arnés (no tocar: son independientes del stack)
# ---------------------------------------------------------------------------

echo "==> Verificando que el arnés está configurado..."

# Los ficheros de convenciones se copian con placeholders <...>. Si quedan sin rellenar,
# los agentes los leen como si fueran instrucciones reales.
pendientes=""
for f in docs/constitution.md rules/*.md; do
  [ -f "$f" ] || continue
  if grep -qE '<[^>]+>' "$f"; then
    pendientes="$pendientes $f"
  fi
done
if [ -n "$pendientes" ]; then
  fallo "quedan placeholders <...> sin rellenar en:$pendientes
       Rellénalos con las convenciones reales del proyecto antes de arrancar el flujo.
       (specs/_template/ y progress/_template-session-context.md sí llevan placeholders
       a propósito: son plantillas, no se comprueban.)"
fi

echo "==> Validando tasks.json..."
if [ -f tasks.json ]; then
  if command -v python3 >/dev/null 2>&1; then
    python3 -c 'import json,sys; json.load(open("tasks.json"))' \
      || fallo "tasks.json no es JSON válido. Lo escribe el leader; arréglalo a mano antes de seguir."
  else
    echo "    (python3 no disponible: me salto la validación de JSON)"
  fi
else
  fallo "falta tasks.json en la raíz del repo."
fi

# Trazabilidad RF→test: cada requisito EARS de una feature con la implementación terminada
# debe aparecer citado por su id en algún test. Es lo que convierte el punto 3 del reviewer
# en algo objetivo. "Terminada" = status in_review o done, o in_progress sin ninguna casilla
# [ ] en su tasks.md. Antes no se exige: una spec recién escrita todavía no tiene tests, y
# exigirlos haría fallar init.sh justo cuando el leader lo ejecuta para pasarla a
# in_progress, y al implementer en cada tarea intermedia.
echo "==> Comprobando trazabilidad RF→test..."
if [ "$MODO" = "rapido" ]; then
  echo "    (--rapido: check saltado)"
elif [ -z "$RUTAS_TESTS" ]; then
  echo "    (RUTAS_TESTS vacío: check saltado)"
else
  command -v python3 >/dev/null 2>&1 \
    || fallo "el check de trazabilidad necesita python3 para leer el estado de tasks.json."
  python3 - $RUTAS_TESTS <<'PY' || fallo "requisitos sin ningún test que los cite por id (ver arriba).
       Convención: el nombre del test incluye el id (ej. test_RF3_… / it('RF-3: …'))."
import json, pathlib, re, sys
tasks = json.load(open("tasks.json")).get("tasks", [])
ficheros = []
for raiz in map(pathlib.Path, sys.argv[1:]):
    if raiz.is_file():
        ficheros.append(raiz)
    elif raiz.is_dir():
        ficheros.extend(p for p in raiz.rglob("*") if p.is_file())
corpus = "\n".join(p.read_text(errors="ignore") for p in ficheros)
faltan, revisadas = [], 0
for t in tasks:
    # Solo las de nivel completo tienen requirements.md con RF-x. Sin "nivel", manda el
    # use_sdd antiguo: false equivale a ligero.
    nivel = t.get("nivel") or ("ligero" if t.get("use_sdd") is False else "completo")
    if nivel != "completo":
        continue
    spec = pathlib.Path(t.get("spec_path") or f"specs/{t.get('feature', '')}/")
    req, tareas = spec / "requirements.md", spec / "tasks.md"
    if not req.is_file():
        continue
    status = t.get("status")
    terminada = status in ("in_review", "done") or (
        status == "in_progress" and tareas.is_file()
        and not re.search(r"^\s*- \[ \]", tareas.read_text(), re.M)
    )
    if not terminada:
        continue
    revisadas += 1
    for num in sorted(set(re.findall(r"RF-(\d+)", req.read_text())), key=int):
        # Acepta RF-3, RF_3 y RF3: en Python el id vive en el nombre de la función
        # (test_RF3_...) y ahí el guion no es legal.
        if not re.search(rf"RF[-_]?{num}(?!\d)", corpus):
            faltan.append(f"  - {t.get('feature')}: RF-{num}")
if faltan:
    print("\n".join(faltan))
    sys.exit(1)
print(f"    {revisadas} feature(s) con la implementación terminada revisadas.")
PY
fi

if [ "$PROYECTO_CONFIGURADO" != "true" ]; then
  fallo "init.sh todavía no está personalizado para este proyecto.
       Rellena los CMD_* de la sección CONFIGURAR con los comandos reales (deps,
       linter, tests) y pon PROYECTO_CONFIGURADO=true.
       Mientras esto no se haga, 'tests en verde' sería solo un echo: el leader, el
       implementer y el reviewer estarían aprobando contra nada."
fi

# ---------------------------------------------------------------------------
# Comandos del stack (se rellenan arriba, en CONFIGURAR).
# ---------------------------------------------------------------------------

if [ "$MODO" = "rapido" ]; then
  echo "==> Verificación rápida..."
  paso "linter" "$CMD_LINT"
  paso "rápido" "$CMD_RAPIDO"
  echo "==> init.sh --rapido: OK."
  exit 0
fi

echo "==> Verificando entorno y dependencias..."
paso "entorno" "$CMD_ENTORNO"
paso "dependencias" "$CMD_DEPS"

echo "==> Linter y tests..."
paso "linter" "$CMD_LINT"
paso "tests" "$CMD_TESTS"

echo "==> init.sh: entorno OK."
