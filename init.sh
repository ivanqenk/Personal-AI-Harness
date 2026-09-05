#!/usr/bin/env bash
# init.sh — verificación de entorno + tests.
# Todos los agentes (leader, implementer, reviewer) deben ejecutar este script
# y confirmar que termina en verde antes de darse por terminados.
#
# Personaliza los comandos de abajo para el stack real del proyecto.

set -euo pipefail

echo "==> Verificando entorno..."
# ej: comprobar versión de node/php/python, dependencias instaladas, .env presente, etc.
# command -v node >/dev/null || { echo "Falta node"; exit 1; }

echo "==> Instalando/verificando dependencias..."
# ej: npm ci / composer install / pip install -r requirements.txt

echo "==> Ejecutando linter..."
# ej: npm run lint / ./vendor/bin/pint --test

echo "==> Ejecutando tests..."
# ej: npm test / php artisan test / pytest

echo "==> init.sh: entorno OK."
