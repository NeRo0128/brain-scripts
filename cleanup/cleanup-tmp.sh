#!/usr/bin/env bash
# cleanup-tmp: Borra archivos viejos de /tmp y ~/.cache.
# Uso: ./cleanup-tmp.sh [dias]
#   dias por defecto: 7 (solo archivos más viejos que N días)
# ⚠  Solo borra archivos que pertenezcan al usuario actual.
# ⚠  Requiere confirmación antes de borrar.
# Deps: find

set -euo pipefail

DAYS="${1:-7}"

if ! [[ "$DAYS" =~ ^[0-9]+$ ]]; then
  echo "✗ Días inválidos: $DAYS" >&2
  exit 1
fi

TARGETS=("/tmp" "$HOME/.cache")

echo "→ Buscando archivos > $DAYS días en:"
printf '   %s\n' "${TARGETS[@]}"
echo ""

TOTAL=0
for dir in "${TARGETS[@]}"; do
  [ -d "$dir" ] || continue
  count=$(find "$dir" -type f -user "$(id -u)" -mtime "+$DAYS" 2>/dev/null | wc -l)
  echo "   $dir: $count archivos"
  TOTAL=$((TOTAL + count))
done

if [ "$TOTAL" -eq 0 ]; then
  echo ""
  echo "✓ Nada que limpiar"
  exit 0
fi

echo ""
echo "⚠  Se borrarán $TOTAL archivos de TU usuario (nunca de otros)."
read -r -p "¿Confirmar? [y/N] " ans
if [ "$ans" != "y" ] && [ "$ans" != "Y" ]; then
  echo "Cancelado."
  exit 0
fi

DELETED=0
for dir in "${TARGETS[@]}"; do
  [ -d "$dir" ] || continue
  while IFS= read -r -d '' f; do
    if rm -f "$f" 2>/dev/null; then
      DELETED=$((DELETED + 1))
    fi
  done < <(find "$dir" -type f -user "$(id -u)" -mtime "+$DAYS" -print0 2>/dev/null)
done

echo ""
echo "✓ $DELETED archivos borrados"
