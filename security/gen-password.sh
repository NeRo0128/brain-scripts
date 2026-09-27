#!/usr/bin/env bash
# gen-password: Genera password aleatorio seguro.
# Uso: ./gen-password.sh [longitud]
#   longitud por defecto: 24
# Deps: openssl o /dev/urandom

set -euo pipefail

LEN="${1:-24}"

if ! [[ "$LEN" =~ ^[0-9]+$ ]] || [ "$LEN" -lt 8 ]; then
  echo "✗ Longitud inválida (mínimo 8): $LEN" >&2
  exit 1
fi

if command -v openssl >/dev/null; then
  BYTES=$(( (LEN * 3 / 4) + 1 ))
  PW=$(openssl rand -base64 "$BYTES" | tr -d '\n=+/' | head -c "$LEN")
else
  PW=$(LC_ALL=C tr -dc 'A-Za-z0-9!@#$%^&*' < /dev/urandom | head -c "$LEN")
fi

echo "$PW"
