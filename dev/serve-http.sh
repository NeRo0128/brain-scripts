#!/usr/bin/env bash
# serve-http: Servidor HTTP simple en un puerto, desde un directorio.
# Uso: ./serve-http.sh [puerto] [directorio]
#   puerto por defecto: 8000
#   directorio por defecto: .
# Deps: python3 (stdlib)

set -euo pipefail

PORT="${1:-8000}"
DIR="${2:-.}"

if [ "${1:-}" = "-h" ] || [ "${1:-}" = "--help" ]; then
  echo "Uso: serve-http.sh [puerto] [directorio]"
  echo "  puerto por defecto: 8000"
  echo "  directorio por defecto: ."
  exit 0
fi

if ! [[ "$PORT" =~ ^[0-9]+$ ]] || [ "$PORT" -lt 1 ] || [ "$PORT" -gt 65535 ]; then
  echo "✗ Puerto inválido: $PORT" >&2
  exit 1
fi

if [ ! -d "$DIR" ]; then
  echo "✗ No existe el directorio: $DIR" >&2
  exit 1
fi

if ! command -v python3 >/dev/null; then
  echo "✗ python3 no está instalado" >&2
  exit 1
fi

# Aviso si el puerto parece ocupado.
if command -v ss >/dev/null && ss -tln 2>/dev/null | grep -q ":$PORT "; then
  echo "⚠  Puerto $PORT parece ocupado:" >&2
  ss -tlnp 2>/dev/null | grep ":$PORT " >&2
  echo ""
fi

# IP local (best-effort, puede fallar en sistemas sin ip).
IP=$(ip route get 1.1.1.1 2>/dev/null | awk '{for(i=1;i<=NF;i++) if($i=="src") print $(i+1)}' | head -1)
[ -z "$IP" ] && IP="localhost"

echo "→ Sirviendo $DIR"
echo "→ Local:   http://localhost:$PORT/"
echo "→ Red:     http://$IP:$PORT/"
echo "→ Ctrl+C para detener"
echo ""

cd "$DIR"
exec python3 -m http.server "$PORT"
