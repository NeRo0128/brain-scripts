#!/usr/bin/env bash
# check-connectivity: Verifica conectividad a hosts comunes.
# Uso: ./check-connectivity.sh [host1 host2 ...]
#   Sin args: verifica Google, Cloudflare, GitHub.
# Deps: ping

set -euo pipefail

DEFAULT_HOSTS=("1.1.1.1" "8.8.8.8" "github.com")

if [ "${1:-}" = "-h" ] || [ "${1:-}" = "--help" ]; then
  echo "Uso: check-connectivity.sh [host1 host2 ...]"
  echo "  Sin args: 1.1.1.1, 8.8.8.8, github.com"
  exit 0
fi

if ! command -v ping >/dev/null; then
  echo "✗ ping no está instalado" >&2
  exit 1
fi

HOSTS=("${@:-${DEFAULT_HOSTS[@]}}")
[ $# -eq 0 ] && HOSTS=("${DEFAULT_HOSTS[@]}")

echo "→ Verificando conectividad a ${#HOSTS[@]} hosts"
echo ""

OK=0
FAIL=0

for host in "${HOSTS[@]}"; do
  printf '   → %-20s ' "$host"

  # -c 1: 1 paquete, -W 2: timeout 2s.
  if ping -c 1 -W 2 "$host" >/dev/null 2>&1; then
    # Extraer latencia.
    rtt=$(ping -c 1 -W 2 "$host" 2>/dev/null \
      | awk -F'time=' '/time=/ {print $2}' \
      | awk '{print $1}' \
      | head -1)
    printf '✓  %s ms\n' "${rtt:-?}"
    OK=$((OK + 1))
  else
    printf '✗  sin respuesta\n'
    FAIL=$((FAIL + 1))
  fi
done

echo ""
echo "✓ OK: $OK  |  ✗ Falló: $FAIL"

if [ "$OK" -eq 0 ]; then
  echo ""
  echo "⚠  Sin conectividad. ¿Está arriba la interfaz de red?"
  exit 1
fi
