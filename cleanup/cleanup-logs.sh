#!/usr/bin/env bash
# cleanup-logs: Comprime logs viejos y borra los muy antiguos.
# Uso: ./cleanup-logs.sh [directorio] [dias-comprimir] [dias-borrar]
#   directorio por defecto: /var/log
#   dias-comprimir por defecto: 7
#   dias-borrar por defecto: 30
# ⚠  /var/log suele requerir sudo. El script lo detecta y avisa.
# Deps: find, gzip

set -euo pipefail

DIR="${1:-/var/log}"
COMPRESS_DAYS="${2:-7}"
DELETE_DAYS="${3:-30}"

if [ ! -d "$DIR" ]; then
  echo "✗ No existe el directorio: $DIR" >&2
  exit 1
fi

# Avisar si hace falta sudo.
SUDO=""
if [ ! -w "$DIR" ]; then
  echo "⚠  Sin permisos de escritura en $DIR"
  echo "   Se usará sudo. Puede pedir contraseña varias veces."
  SUDO="sudo"
  if ! sudo -n true 2>/dev/null; then
    echo "→ Autenticando sudo por adelantado..."
    sudo -v
  fi
fi

echo "→ Directorio: $DIR"
echo "→ Comprimir logs > $COMPRESS_DAYS días"
echo "→ Borrar logs    > $DELETE_DAYS días"
echo ""

# 1. Comprimir logs viejos sin comprimir.
echo "→ Comprimiendo..."
COUNT_C=0
while IFS= read -r -d '' f; do
  $SUDO gzip "$f"
  COUNT_C=$((COUNT_C + 1))
done < <(find "$DIR" -type f -name "*.log" -mtime "+$COMPRESS_DAYS" -print0 2>/dev/null)
echo "   ✓ $COUNT_C archivos comprimidos"

# 2. Borrar logs comprimidos muy viejos.
echo "→ Borrando..."
COUNT_D=0
while IFS= read -r -d '' f; do
  $SUDO rm -f "$f"
  COUNT_D=$((COUNT_D + 1))
done < <(find "$DIR" -type f \( -name "*.log.gz" -o -name "*.log.[0-9]*" \) -mtime "+$DELETE_DAYS" -print0 2>/dev/null)
echo "   ✓ $COUNT_D archivos borrados"

echo ""
echo "✓ Limpieza completada"
