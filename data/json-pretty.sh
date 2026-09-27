#!/usr/bin/env bash
# json-pretty: Pretty print de JSON (archivo o stdin).
# Uso: ./json-pretty.sh [archivo.json]
#   Sin arg → lee de stdin.
# Deps: jq

set -euo pipefail

if ! command -v jq >/dev/null; then
  echo "✗ jq no está instalado" >&2
  exit 1
fi

if [ "${1:-}" = "-h" ] || [ "${1:-}" = "--help" ]; then
  echo "Uso: json-pretty.sh [archivo.json]"
  echo "  Sin arg: lee de stdin."
  echo "  Ejemplo: echo '{\"a\":1}' | json-pretty.sh"
  exit 0
fi

if [ -n "${1:-}" ]; then
  if [ ! -f "$1" ]; then
    echo "✗ No existe: $1" >&2
    exit 1
  fi
  jq '.' "$1"
else
  # jq detecta TTY por sí solo; forzamos lectura por si acaso.
  jq '.'
fi
