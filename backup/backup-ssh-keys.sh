#!/usr/bin/env bash
# backup-ssh-keys: Backup cifrado de ~/.ssh.
# Uso: ./backup-ssh-keys.sh [destino]
#   destino por defecto: ~/backups
# Deps: tar, openssl, date

set -euo pipefail

DEST="${1:-$HOME/backups}"
SRC="$HOME/.ssh"
STAMP=$(date +%Y%m%d_%H%M%S)
OUT="$DEST/ssh_$STAMP.tar.gz.enc"

if [ ! -d "$SRC" ]; then
  echo "✗ No existe $SRC" >&2
  exit 1
fi

if ! command -v openssl >/dev/null; then
  echo "✗ openssl no está instalado (necesario para cifrar)" >&2
  exit 1
fi

mkdir -p "$DEST"

echo "⚠  Este backup contiene claves SSH privadas."
echo "   Se cifrará con AES-256-CBC + PBKDF2."
echo ""

# Pedir passphrase (no se muestra en pantalla).
read -r -s -p "Passphrase para cifrar: " PASSPHRASE
echo ""
read -r -s -p "Confirmar passphrase:   " PASSPHRASE2
echo ""

if [ "$PASSPHRASE" != "$PASSPHRASE2" ]; then
  echo "✗ Las passphrases no coinciden" >&2
  exit 1
fi

if [ -z "$PASSPHRASE" ]; then
  echo "✗ Passphrase vacía — abortando" >&2
  exit 1
fi

# Tar → cifrar en streaming → archivo.
tar -czf - -C "$HOME" .ssh \
  | openssl enc -aes-256-cbc -pbkdf2 -iter 100000 -salt \
      -out "$OUT" -pass "pass:$PASSPHRASE"

unset PASSPHRASE PASSPHRASE2

SIZE=$(du -h "$OUT" | cut -f1)
echo "✓ Backup cifrado: $OUT ($SIZE)"
echo ""
echo "Para restaurar:"
echo "  openssl enc -d -aes-256-cbc -pbkdf2 -iter 100000 -in $OUT | tar -xzf - -C \$HOME"
