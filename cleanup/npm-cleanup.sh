#!/usr/bin/env bash
# npm-cleanup: Limpia la caché de npm.
# Uso: ./npm-cleanup.sh
# Deps: npm

set -euo pipefail

if ! command -v npm >/dev/null; then
  echo "✗ npm no está instalado" >&2
  exit 1
fi

CACHE_DIR=$(npm config get cache 2>/dev/null || echo "")

if [ -z "$CACHE_DIR" ] || [ ! -d "$CACHE_DIR" ]; then
  echo "✗ No se pudo localizar el cache de npm" >&2
  exit 1
fi

SIZE_BEFORE=$(du -sh "$CACHE_DIR" 2>/dev/null | cut -f1)
echo "→ Cache: $CACHE_DIR"
echo "→ Tamaño antes: $SIZE_BEFORE"
echo ""

echo "→ Limpiando..."
npm cache clean --force

SIZE_AFTER=$(du -sh "$CACHE_DIR" 2>/dev/null | cut -f1)
echo ""
echo "✓ Cache limpiada"
echo "   Antes: $SIZE_BEFORE"
echo "   Ahora: $SIZE_AFTER"
