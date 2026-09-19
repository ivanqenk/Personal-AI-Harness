#!/usr/bin/env bash
# init.sh — verificación de entorno + tests.
# Todos los agentes (leader, implementer, reviewer) lo ejecutan y no pueden darse por
# terminados si no termina en verde.
#
# Este script falla A PROPÓSITO en una instalación recién copiada. Un arnés cuyo único
# gate objetivo devuelve "OK" sin ejecutar nada es peor que no tener gate: da confianza
# falsa. Rellena las dos secciones marcadas CONFIGURAR y pon PROYECTO_CONFIGURADO=true.

set -euo pipefail

# ---------------------------------------------------------------------------
# CONFIGURAR (1/2): ponlo a true cuando hayas rellenado los comandos reales de abajo.
# ---------------------------------------------------------------------------
PROYECTO_CONFIGURADO=false

# Rutas donde viven los tests, separadas por espacios. Se usan para el check de
# trazabilidad RF→test. Déjalo vacío para saltarte ese check.
RUTAS_TESTS=""

fallo() { echo "ERROR: $*" >&2; exit 1; }

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
if [ -z "$RUTAS_TESTS" ]; then
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
    if t.get("use_sdd") is False:
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
       Rellena las secciones CONFIGURAR de abajo con los comandos reales (deps, linter,
       tests) y pon PROYECTO_CONFIGURADO=true.
       Mientras esto no se haga, 'tests en verde' sería solo un echo: el leader, el
       implementer y el reviewer estarían aprobando contra nada."
fi

# ---------------------------------------------------------------------------
# CONFIGURAR (2/2): comandos reales del stack.
# ---------------------------------------------------------------------------

echo "==> Verificando entorno..."
# ej: command -v node >/dev/null || fallo "falta node"

echo "==> Instalando/verificando dependencias..."
# ej: npm ci / composer install / pip install -r requirements.txt

echo "==> Ejecutando linter..."
# ej: npm run lint / ./vendor/bin/pint --test

echo "==> Ejecutando tests..."
# ej: npm test / php artisan test / pytest

echo "==> init.sh: entorno OK."
