#!/usr/bin/env bash
# decrypt-file: Descifra un archivo cifrado con encrypt-file.sh.
# Uso: ./decrypt-file.sh <archivo.enc> [salida]
#   salida por defecto: <archivo> sin la extensión .enc
# Deps: openssl

set -euo pipefail

if [ $# -lt 1 ] || [ "$1" = "-h" ] || [ "$1" = "--help" ]; then
  echo "Uso: decrypt-file.sh <archivo.enc> [salida]"
  echo ""
  echo "Requiere el mismo algoritmo y passphrase usados al cifrar."
  exit 0
fi

SRC="$1"

if [ ! -f "$SRC" ]; then
  echo "✗ No existe: $SRC" >&2
  exit 1
fi

if ! command -v openssl >/dev/null; then
  echo "✗ openssl no está instalado" >&2
  exit 1
fi

# Determinar salida.
if [ $# -ge 2 ]; then
  OUT="$2"
else
  # Quitar sufijo .enc si existe.
  if [[ "$SRC" == *.enc ]]; then
    OUT="${SRC%.enc}"
  else
    OUT="${SRC}.dec"
  fi
fi

if [ -e "$OUT" ]; then
  echo "⚠  El archivo $OUT ya existe."
  read -r -p "¿Sobrescribir? [y/N] " ans
  if [ "$ans" != "y" ] && [ "$ans" != "Y" ]; then
    echo "Cancelado."
    exit 0
  fi
fi

echo "→ Descifrando $SRC → $OUT"
echo ""

read -r -s -p "Passphrase: " PW
echo ""

if [ -z "$PW" ]; then
  echo "✗ Passphrase vacía — abortando" >&2
  exit 1
fi

if ! openssl enc -d -aes-256-cbc -pbkdf2 -iter 100000 \
    -in "$SRC" -out "$OUT" -pass "pass:$PW" 2>/dev/null; then
  unset PW
  echo "" >&2
  echo "✗ Falló el descifrado (passphrase incorrecta o archivo corrupto)" >&2
  # Limpiar posible archivo a medias.
  [ -f "$OUT" ] && rm -f "$OUT"
  exit 1
fi

unset PW

SIZE_OUT=$(du -h "$OUT" | cut -f1)
echo ""
echo "✓ Descifrado completado: $OUT ($SIZE_OUT)"
