#!/usr/bin/env bash
# hash-file: Calcula hash de un archivo (múltiples algoritmos).
# Uso: ./hash-file.sh <archivo> [algoritmo]
#   algoritmo por defecto: sha256
#   disponibles: md5 | sha1 | sha256 | sha512 (según disponibilidad)
# Deps: sha256sum, sha512sum, sha1sum, md5sum (coreutils)

set -euo pipefail

if [ $# -lt 1 ] || [ "$1" = "-h" ] || [ "$1" = "--help" ]; then
  echo "Uso: hash-file.sh <archivo> [algoritmo]"
  echo "  algoritmo por defecto: sha256"
  echo "  disponibles: md5 sha1 sha256 sha512"
  exit 0
fi

FILE="$1"
ALGO="${2:-sha256}"

if [ ! -f "$FILE" ]; then
  echo "✗ No existe o no es archivo: $FILE" >&2
  exit 1
fi

# Mapear algoritmo a comando.
case "$ALGO" in
  md5)    CMD="md5sum" ;;
  sha1)   CMD="sha1sum" ;;
  sha256) CMD="sha256sum" ;;
  sha512) CMD="sha512sum" ;;
  *)
    echo "✗ Algoritmo inválido: $ALGO" >&2
    exit 1
    ;;
esac

if ! command -v "$CMD" >/dev/null; then
  echo "✗ $CMD no está instalado" >&2
  exit 1
fi

SIZE=$(du -h "$FILE" | cut -f1)
HASH=$("$CMD" "$FILE" | awk '{print $1}')

echo "▶ Hash: $FILE"
echo "   Tamaño:     $SIZE"
echo "   Algoritmo:  $ALGO"
echo "   Hash:       $HASH"

# Comparación con un hash esperado (si se pasa por stdin/env).
if [ -n "${EXPECTED_HASH:-}" ]; then
  if [ "$HASH" = "$EXPECTED_HASH" ]; then
    echo "   ✓ Coincide con EXPECTED_HASH"
  else
    echo "   ✗ NO coincide con EXPECTED_HASH"
    exit 2
  fi
fi
