#!/usr/bin/env bash
# docker-prune: Limpia recursos Docker no usados.
# Uso: ./docker-prune.sh [-a]
#   -a   también limpia volúmenes (peligroso)
# Deps: docker

set -euo pipefail

if ! command -v docker >/dev/null; then
  echo "✗ docker no está instalado" >&2
  exit 1
fi

if ! docker info >/dev/null 2>&1; then
  echo "✗ docker daemon no está corriendo" >&2
  exit 1
fi

echo "→ Antes:"
docker system df
echo ""

echo "→ Limpiando contenedores parados, redes e imágenes dangling..."
docker system prune -f

if [ "${1:-}" = "-a" ]; then
  echo ""
  echo "→ Limpiando volúmenes NO usados (-a)..."
  docker volume prune -f
fi

echo ""
echo "→ Después:"
docker system df
echo "✓ Limpieza completada"
