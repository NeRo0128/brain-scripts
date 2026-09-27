#!/usr/bin/env bash
# docker-cleanup-images: Borra imágenes Docker no usadas.
# Uso: ./docker-cleanup-images.sh [--all]
#   --all   borra TODAS las imágenes no usadas por contenedores (más agresivo)
#           sin flag: solo dangling (sin tag)
# Deps: docker

set -euo pipefail

ALL=false
[ "${1:-}" = "--all" ] && ALL=true

if ! command -v docker >/dev/null; then
  echo "✗ docker no está instalado" >&2
  exit 1
fi

if ! docker info >/dev/null 2>&1; then
  echo "✗ docker daemon no está corriendo" >&2
  exit 1
fi

if $ALL; then
  echo "⚠  Modo agresivo: se borrarán TODAS las imágenes sin contenedor."
  echo ""
  echo "→ Imágenes a borrar:"
  docker images --filter "dangling=false" --format "   {{.Repository}}:{{.Tag}} ({{.Size}})"
  echo ""
  read -r -p "¿Confirmar? [y/N] " ans
  if [ "$ans" != "y" ] && [ "$ans" != "Y" ]; then
    echo "Cancelado."
    exit 0
  fi
  docker image prune -a -f
else
  echo "→ Borrando imágenes dangling (sin tag)..."
  docker image prune -f
fi

echo ""
echo "→ Espacio liberado:"
docker system df
