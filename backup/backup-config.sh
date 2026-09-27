#!/usr/bin/env bash
# backup-config: Backup de ~/.config a un destino con timestamp.
# Uso: ./backup-config.sh [destino]
#   destino por defecto: ~/backups
# Deps: tar, date

set -euo pipefail

DEST="${1:-$HOME/backups}"
SRC="$HOME/.config"
STAMP=$(date +%Y%m%d_%H%M%S)
OUT="$DEST/config_$STAMP.tar.gz"

if [ ! -d "$SRC" ]; then
  echo "✗ No existe $SRC" >&2
  exit 1
fi

mkdir -p "$DEST"

echo "→ Backing up $SRC → $OUT"
tar -czf "$OUT" -C "$HOME" .config

SIZE=$(du -h "$OUT" | cut -f1)
echo "✓ Backup completado: $OUT ($SIZE)"
