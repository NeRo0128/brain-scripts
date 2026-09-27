#!/usr/bin/env bash
# deps-check: Verifica que los binarios requeridos estén en PATH.
# Uso: ./deps-check.sh bin1 bin2 bin3 ...
#   Sin args: verifica la lista por defecto.
# Deps: command

set -euo pipefail

DEFAULT_DEPS=(
  git curl wget jq tar gzip openssl
  docker docker-compose
  go python3 node npm
)

if [ "${1:-}" = "-h" ] || [ "${1:-}" = "--help" ]; then
  echo "Uso: deps-check.sh [bin1 bin2 ...]"
  echo "  Sin args: verifica una lista común."
  exit 0
fi

if [ $# -gt 0 ]; then
  DEPS=("$@")
else
  DEPS=("${DEFAULT_DEPS[@]}")
fi

echo "→ Verificando ${#DEPS[@]} binarios"
echo ""

OK=0
MISSING=0
declare -a MISSING_LIST=()

for bin in "${DEPS[@]}"; do
  if path=$(command -v "$bin" 2>/dev/null); then
    printf '   ✓ %-18s %s\n' "$bin" "$path"
    OK=$((OK + 1))
  else
    printf '   ✗ %-18s (no encontrado)\n' "$bin"
    MISSING=$((MISSING + 1))
    MISSING_LIST+=("$bin")
  fi
done

echo ""
echo "→ Presentes: $OK / ${#DEPS[@]}"

if [ "$MISSING" -gt 0 ]; then
  echo "→ Faltan:    $MISSING"
  echo ""
  echo "   Instalar en Arch:  sudo pacman -S ${MISSING_LIST[*]}"
  echo "   Instalar en Debian: sudo apt install ${MISSING_LIST[*]}"
  exit 1
fi

echo "✓ Todos los binarios disponibles"
