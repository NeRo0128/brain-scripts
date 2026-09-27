#!/usr/bin/env bash
# public-ip: Muestra la IP pública y datos del ISP.
# Uso: ./public-ip.sh [--json]
# Deps: curl

set -euo pipefail

JSON_MODE=false
[ "${1:-}" = "--json" ] && JSON_MODE=true

if ! command -v curl >/dev/null; then
  echo "✗ curl no está instalado" >&2
  exit 1
fi

# Probar varios servicios en orden (por si uno falla).
SERVICES=(
  "https://ifconfig.me/ip"
  "https://api.ipify.org"
  "https://icanhazip.com"
  "https://ipinfo.io/ip"
)

IP=""
for svc in "${SERVICES[@]}"; do
  IP=$(curl -fsSL --max-time 5 "$svc" 2>/dev/null | tr -d '[:space:]' || true)
  if [ -n "$IP" ]; then
    break
  fi
done

if [ -z "$IP" ]; then
  echo "✗ No se pudo obtener la IP pública" >&2
  exit 1
fi

if $JSON_MODE; then
  # Detalles desde ipinfo.io (puede limitar).
  curl -fsSL --max-time 5 "https://ipinfo.io/$IP/json" 2>/dev/null \
    || echo "{\"ip\": \"$IP\"}"
  exit 0
fi

echo "▶ IP Pública"
echo "   IP: $IP"
echo ""

# Datos adicionales (best-effort).
DETAILS=$(curl -fsSL --max-time 5 "https://ipinfo.io/$IP/json" 2>/dev/null || true)
if [ -n "$DETAILS" ]; then
  if command -v jq >/dev/null; then
    echo "→ Detalles:"
    echo "$DETAILS" | jq -r '
      "   Ciudad:   \(.city // "?")",
      "   Región:   \(.region // "?")",
      "   País:     \(.country // "?")",
      "   ISP/Org:  \(.org // "?")",
      "   Zona:     \(.timezone // "?")"
    ' 2>/dev/null || true
  else
    echo "→ Detalles crudos (instala jq para formatear):"
    echo "$DETAILS" | head -5 | sed 's/^/   /'
  fi
fi
