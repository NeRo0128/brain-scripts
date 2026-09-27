#!/usr/bin/env bash
# gen-uuid: Genera UUID v4 aleatorios.
# Uso: ./gen-uuid.sh [cantidad]
#   cantidad por defecto: 1
# Deps: uuidgen (util-linux) o fallback a /proc/sys/kernel/random/uuid

set -euo pipefail

COUNT="${1:-1}"

if ! [[ "$COUNT" =~ ^[0-9]+$ ]] || [ "$COUNT" -lt 1 ]; then
  echo "✗ Cantidad inválida: $COUNT" >&2
  exit 1
fi

gen_one() {
  if command -v uuidgen >/dev/null; then
    uuidgen | tr '[:upper:]' '[:lower:]'
  elif [ -r /proc/sys/kernel/random/uuid ]; then
    cat /proc/sys/kernel/random/uuid
  else
    # Fallback: openssl rand + formato UUID v4.
    openssl rand -hex 16 \
      | sed -E 's/^(.{8})(.{4})(.{4})(.{4})(.{12})$/\1-\2-4\3-a\4-\5/'
  fi
}

for _ in $(seq 1 "$COUNT"); do
  gen_one
done
