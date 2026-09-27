#!/usr/bin/env bash
# disk-usage: Top 10 directorios más grandes en una ruta.
# Uso: ./disk-usage.sh [ruta] [n]
#   ruta por defecto: $HOME
#   n por defecto: 10
# Deps: du, sort, head

set -euo pipefail

TARGET="${1:-$HOME}"
N="${2:-10}"

if [ ! -d "$TARGET" ]; then
  echo "✗ No existe el directorio: $TARGET" >&2
  exit 1
fi

echo "→ Top $N directorios más grandes en $TARGET"
echo ""

du -h --max-depth=1 "$TARGET" 2>/dev/null \
  | sort -rh \
  | head -n "$((N + 1))"
