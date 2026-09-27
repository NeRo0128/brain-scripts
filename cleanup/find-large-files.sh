#!/usr/bin/env bash
# find-large-files: Encuentra archivos grandes en una ruta.
# Uso: ./find-large-files.sh [ruta] [tamaño-min-MB] [limite]
#   ruta por defecto: $HOME
#   tamaño-min-MB por defecto: 100
#   limite por defecto: 20
# Deps: find, du, sort, head

set -euo pipefail

TARGET="${1:-$HOME}"
MIN_MB="${2:-100}"
LIMIT="${3:-20}"

if [ ! -d "$TARGET" ]; then
  echo "✗ No existe: $TARGET" >&2
  exit 1
fi

echo "→ Archivos > ${MIN_MB}MB en $TARGET (top $LIMIT)"
echo ""

find "$TARGET" -type f -size "+${MIN_MB}M" 2>/dev/null \
  | while read -r f; do
      size=$(du -m "$f" 2>/dev/null | cut -f1)
      printf '%10d MB  %s\n' "$size" "$f"
    done \
  | sort -rn \
  | head -n "$LIMIT" \
  | awk '{ printf "%6s MB  %s\n", $1, $2 }'
