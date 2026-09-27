#!/usr/bin/env bash
# backup-docker-volumes: Exporta cada volumen Docker a un .tar.gz.
# Uso: ./backup-docker-volumes.sh [destino]
#   destino por defecto: ~/backups/docker-volumes
# Deps: docker, date, gzip

set -euo pipefail

DEST="${1:-$HOME/backups/docker-volumes}"
STAMP=$(date +%Y%m%d_%H%M%S)

if ! command -v docker >/dev/null; then
  echo "✗ docker no está instalado" >&2
  exit 1
fi

if ! docker info >/dev/null 2>&1; then
  echo "✗ docker daemon no está corriendo" >&2
  exit 1
fi

mkdir -p "$DEST"

VOLUMES=$(docker volume ls -q)
if [ -z "$VOLUMES" ]; then
  echo "→ No hay volúmenes Docker"
  exit 0
fi

echo "→ Exportando volúmenes Docker a $DEST"
echo ""

for vol in $VOLUMES; do
  OUT="$DEST/${vol}_${STAMP}.tar.gz"
  echo "   → $vol"
  docker run --rm \
    -v "$vol:/data:ro" \
    -v "$DEST:/backup" \
    alpine \
    tar -czf "/backup/$(basename "$OUT")" -C /data . \
    >/dev/null 2>&1
  SIZE=$(du -h "$OUT" 2>/dev/null | cut -f1 || echo "?")
  echo "     ✓ $OUT ($SIZE)"
done

echo ""
echo "✓ Volúmenes exportados: $(echo "$VOLUMES" | wc -l)"
