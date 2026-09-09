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

# Trazabilidad RF→test: cada requisito EARS de una feature en curso debe aparecer citado
# por su id en algún test. Es lo que convierte el punto 3 del reviewer en algo objetivo.
echo "==> Comprobando trazabilidad RF→test..."
if [ -z "$RUTAS_TESTS" ]; then
  echo "    (RUTAS_TESTS vacío: check saltado)"
else
  sin_test=""
  for req in specs/*/requirements.md; do
    [ -f "$req" ] || continue
    feature=$(basename "$(dirname "$req")")
    [ "$feature" = "_template" ] && continue
    while read -r num; do
      [ -n "$num" ] || continue
      # Acepta RF-3, RF_3 y RF3: en Python el id vive en el nombre de la función
      # (test_RF3_...) y ahí el guion no es legal.
      if ! grep -rqE "RF[-_]?${num}([^0-9]|\$)" $RUTAS_TESTS 2>/dev/null; then
        sin_test="$sin_test\n  - $feature: RF-$num"
      fi
    done < <(grep -oE 'RF-[0-9]+' "$req" | grep -oE '[0-9]+' | sort -un)
  done
  if [ -n "$sin_test" ]; then
    fallo "requisitos sin ningún test que los cite por id:$(printf "%b" "$sin_test")
       Convención: el nombre del test incluye el id (ej. test_RF3_… / it('RF-3: …'))."
  fi
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
