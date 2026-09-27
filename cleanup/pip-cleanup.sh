#!/usr/bin/env bash
# pip-cleanup: Limpia la caché de pip.
# Uso: ./pip-cleanup.sh
# Deps: pip3 (o pip)

set -euo pipefail

# Detectar pip.
PIP=""
if command -v pip3 >/dev/null; then
  PIP=pip3
elif command -v pip >/dev/null; then
  PIP=pip
else
  echo "✗ pip no está instalado" >&2
  exit 1
fi

CACHE_DIR=$("$PIP" cache dir 2>/dev/null || echo "")

if [ -z "$CACHE_DIR" ] || [ ! -d "$CACHE_DIR" ]; then
  echo "✗ No se pudo localizar el cache de $PIP" >&2
  exit 1
fi

SIZE_BEFORE=$(du -sh "$CACHE_DIR" 2>/dev/null | cut -f1)
echo "→ pip: $PIP"
echo "→ Cache: $CACHE_DIR"
echo "→ Tamaño antes: $SIZE_BEFORE"
echo ""

echo "→ Limpiando..."
"$PIP" cache purge

SIZE_AFTER=$(du -sh "$CACHE_DIR" 2>/dev/null | cut -f1)
echo ""
echo "✓ Cache limpiada"
echo "   Antes: $SIZE_BEFORE"
echo "   Ahora: $SIZE_AFTER"
