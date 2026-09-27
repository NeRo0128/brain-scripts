#!/usr/bin/env bash
# dedupe-files: Encuentra y (opcionalmente) borra archivos duplicados por hash.
# Uso: ./dedupe-files.sh [ruta] [--delete]
#   ruta por defecto: .
#   --delete: borra duplicados (conserva el primero encontrado)
# Deps: find, sha256sum (o shasum)

set -euo pipefail

TARGET="${1:-.}"
DELETE=false
[ "${2:-}" = "--delete" ] && DELETE=true

if [ ! -d "$TARGET" ]; then
  echo "✗ No existe: $TARGET" >&2
  exit 1
fi

# Detectar herramienta de hash.
HASH_CMD=""
if command -v sha256sum >/dev/null; then
  HASH_CMD="sha256sum"
elif command -v shasum >/dev/null; then
  HASH_CMD="shasum -a 256"
else
  echo "✗ Necesitas sha256sum o shasum" >&2
  exit 1
fi

echo "→ Ruta: $TARGET"
echo "→ Modo: $([ "$DELETE" = true ] && echo "BORRAR duplicados" || echo "solo reportar")"
echo ""

# Calcular hashes (solo archivos regulares, no symlinks).
TMP=$(mktemp)
trap 'rm -f "$TMP"' EXIT

# shellcheck disable=SC2086
find "$TARGET" -type f -print0 2>/dev/null \
  | xargs -0 -r $HASH_CMD 2>/dev/null \
  | sort > "$TMP"

# Detectar hashes repetidos.
DUP_HASHES=$(awk '{print $1}' "$TMP" | uniq -d)

if [ -z "$DUP_HASHES" ]; then
  echo "✓ No se encontraron duplicados"
  exit 0
fi

TOTAL_SAVED=0
while IFS= read -r hash; do
  [ -z "$hash" ] && continue
  # Archivos con ese hash (el campo 2+ es el path).
  mapfile -t files < <(grep "^$hash " "$TMP" | sed 's/^[a-f0-9]*  //')

  echo "→ Grupo ($hash):"
  printf '   %s\n' "${files[@]}"
  echo ""

  if $DELETE; then
    # Conservar el primero, borrar el resto.
    for ((i = 1; i < ${#files[@]}; i++)); do
      size=$(du -k "${files[i]}" 2>/dev/null | cut -f1)
      if rm -f "${files[i]}"; then
        TOTAL_SAVED=$((TOTAL_SAVED + size))
        echo "   ✓ Borrado: ${files[i]}"
      fi
    done
  fi
done <<< "$DUP_HASHES"

echo ""
if $DELETE; then
  echo "✓ Espacio liberado: ${TOTAL_SAVED}KB"
else
  echo "→ Ejecuta con --delete para borrar los duplicados (se conserva el primero)"
fi
