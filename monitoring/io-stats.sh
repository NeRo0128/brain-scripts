#!/usr/bin/env bash
# io-stats: Estadísticas de I/O por dispositivo de bloque.
# Uso: ./io-stats.sh [intervalo] [repeticiones]
#   intervalo por defecto: 1
#   repeticiones por defecto: 1
# Deps: iostat (sysstat) — o fallback a /proc/diskstats

set -euo pipefail

INTERVAL="${1:-1}"
COUNT="${2:-1}"

if command -v iostat >/dev/null; then
  echo "▶ iostat (intervalo=${INTERVAL}s, repeticiones=${COUNT})"
  echo ""
  # -x = extendido, -d = solo discos (sin CPU).
  iostat -xd "$INTERVAL" "$COUNT"
  exit 0
fi

# Fallback: /proc/diskstats.
echo "⚠  iostat no está instalado (paquete: sysstat)"
echo "→ Fallback a /proc/diskstats"
echo ""

if [ ! -r /proc/diskstats ]; then
  echo "✗ /proc/diskstats no accesible" >&2
  exit 1
fi

printf '%-18s %15s %15s\n' "DEVICE" "READS(sectors)" "WRITES(sectors)"
echo "─────────────────────────────────────────────────────"

# Campos: major minor name reads_completed reads_merged sectors_read ...
awk '
  $3 !~ /^(loop|ram|dm-)/ {
    printf "%-18s %15d %15d\n", $3, $6, $10
  }
' /proc/diskstats
