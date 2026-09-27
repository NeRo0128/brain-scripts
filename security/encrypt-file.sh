#!/usr/bin/env bash
# encrypt-file: Cifra un archivo con AES-256-CBC (openssl).
# Uso: ./encrypt-file.sh <archivo> [salida]
#   salida por defecto: <archivo>.enc
# Deps: openssl

set -euo pipefail

if [ $# -lt 1 ] || [ "$1" = "-h" ] || [ "$1" = "--help" ]; then
  echo "Uso: encrypt-file.sh <archivo> [salida.enc]"
  echo ""
  echo "El archivo cifrado se puede descifrar con decrypt-file.sh."
  exit 0
fi

SRC="$1"
OUT="${2:-${SRC}.enc}"

if [ ! -f "$SRC" ]; then
  echo "✗ No existe: $SRC" >&2
  exit 1
fi

if ! command -v openssl >/dev/null; then
  echo "✗ openssl no está instalado" >&2
  exit 1
fi

# Aviso de sobreescritura.
if [ -e "$OUT" ]; then
  echo "⚠  El archivo $OUT ya existe."
  read -r -p "¿Sobrescribir? [y/N] " ans
  if [ "$ans" != "y" ] && [ "$ans" != "Y" ]; then
    echo "Cancelado."
    exit 0
  fi
fi

echo "→ Cifrando $SRC → $OUT"
echo ""

# Pedir passphrase dos veces (no se muestra).
read -r -s -p "Passphrase: " PW1
echo ""
read -r -s -p "Confirmar:  " PW2
echo ""

if [ "$PW1" != "$PW2" ]; then
  echo "✗ Las passphrases no coinciden" >&2
  exit 1
fi

if [ -z "$PW1" ]; then
  echo "✗ Passphrase vacía — abortando" >&2
  exit 1
fi

openssl enc -aes-256-cbc -pbkdf2 -iter 100000 -salt \
  -in "$SRC" -out "$OUT" -pass "pass:$PW1"

unset PW1 PW2

SIZE_IN=$(du -h "$SRC" | cut -f1)
SIZE_OUT=$(du -h "$OUT" | cut -f1)

echo ""
echo "✓ Cifrado completado"
echo "   Original:  $SRC ($SIZE_IN)"
echo "   Cifrado:   $OUT ($SIZE_OUT)"
