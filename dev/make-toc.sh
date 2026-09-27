#!/usr/bin/env bash
# make-toc: Genera un Table of Contents para un archivo Markdown.
# Uso: ./make-toc.sh archivo.md
# Deps: awk, grep

set -euo pipefail

if [ $# -lt 1 ] || [ "$1" = "-h" ] || [ "$1" = "--help" ]; then
  echo "Uso: make-toc.sh <archivo.md>"
  echo ""
  echo "Ejemplo:"
  echo "  make-toc.sh README.md    # imprime el ToC a stdout"
  exit 0
fi

FILE="$1"

if [ ! -f "$FILE" ]; then
  echo "✗ No existe: $FILE" >&2
  exit 1
fi

echo "## Tabla de contenidos"
echo ""

# Encuentra headers h2..h4.
# Convierte "## Foo Bar" → "  - [Foo Bar](#foo-bar)"
awk '
  /^#{2,4} / {
    # Contar #.
    match($0, /^#+/)
    level = RLENGTH

    # Extraer título (después del espacio).
    title = substr($0, level + 2)

    # Generar anchor: lowercase, espacios → -, quitar no alfanuméricos.
    anchor = tolower(title)
    gsub(/[^a-z0-9 -]/, "", anchor)
    gsub(/ /, "-", anchor)

    # Indentación según nivel (h2 = sin indentar, h3 = 2, h4 = 4).
    indent = ""
    for (i = 3; i <= level; i++) indent = indent "  "

    printf "%s- [%s](#%s)\n", indent, title, anchor
  }
' "$FILE"
