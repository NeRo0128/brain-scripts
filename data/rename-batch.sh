#!/usr/bin/env bash
# rename-batch: Renombra archivos en batch usando regex sed.
# Uso: ./rename-batch.sh <regex> <reemplazo> [directorio]
#   directorio por defecto: .
#   Sin --apply: muestra el plan (dry-run).
#   Con --apply: ejecuta los cambios.
# Deps: sed, find

set -euo pipefail

if [ "${1:-}" = "-h" ] || [ "${1:-}" = "--help" ] || [ $# -lt 2 ]; then
  cat <<'EOF'
Uso: rename-batch.sh <regex-sed> <reemplazo> [directorio] [--apply]

Ejemplos:
  # Dry-run: ver qué cambiaría "IMG_" a "photo_"
  rename-batch.sh 'IMG_' 'photo_' ~/Pictures

  # Ejecutar
  rename-batch.sh 'IMG_' 'photo_' ~/Pictures --apply

  # Solo extensión
  rename-batch.sh '\.jpeg$' '.jpg' . --apply
EOF
  exit 0
fi

PATTERN="$1"
REPLACE="$2"
DIR="${3:-.}"
APPLY=false
[ "${4:-}" = "--apply" ] && APPLY=true

if [ ! -d "$DIR" ]; then
  echo "✗ No existe: $DIR" >&2
  exit 1
fi

echo "→ Directorio: $DIR"
echo "→ Patrón:     s/$PATTERN/$REPLACE/"
echo "→ Modo:       $([ "$APPLY" = true ] && echo "APLICAR" || echo "dry-run (usa --apply para ejecutar)")"
echo ""

COUNT=0
while IFS= read -r -d '' f; do
  dirpart=$(dirname "$f")
  base=$(basename "$f")
  new=$(echo "$base" | sed -E "s/$PATTERN/$REPLACE/")

  if [ "$base" = "$new" ]; then
    continue
  fi

  echo "   $base"
  echo "   → $new"
  echo ""

  if $APPLY; then
    if [ -e "$dirpart/$new" ]; then
      echo "   ✗ Ya existe: $dirpart/$new — saltando"
      echo ""
      continue
    fi
    mv -n "$f" "$dirpart/$new"
    echo "   ✓ Renombrado"
    echo ""
  fi

  COUNT=$((COUNT + 1))
done < <(find "$DIR" -maxdepth 1 -type f -print0 2>/dev/null)

if [ "$COUNT" -eq 0 ]; then
  echo "→ Ningún archivo coincide con el patrón"
else
  echo "✓ $COUNT archivos $([ "$APPLY" = true ] && echo "renombrados" || echo "a renombrar")"
fi
