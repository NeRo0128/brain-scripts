#!/usr/bin/env bash
# memory-usage: Uso de RAM + swap + top procesos por memoria.
# Uso: ./memory-usage.sh [top-N]
#   top-N por defecto: 5 (procesos)
# Deps: free, ps, sort

set -euo pipefail

TOP_N="${1:-5}"

if ! command -v free >/dev/null; then
  echo "✗ 'free' no está instalado (procps)" >&2
  exit 1
fi

echo "▶ Memoria"
echo ""
free -h
echo ""

# Cálculo adicional de uso real (sin buff/cache).
TOTAL=$(free -m | awk '/^Mem:/ {print $2}')
USED=$(free -m | awk '/^Mem:/ {print $3}')
AVAIL=$(free -m | awk '/^Mem:/ {print $7}')
PCT=$((USED * 100 / TOTAL))

echo "→ Uso (USED/TOTAL): ${PCT}%  (${USED}MB / ${TOTAL}MB)"
echo "→ Disponible:       ${AVAIL}MB"
echo ""

# Top procesos por RSS.
echo "→ Top $TOP_N procesos por memoria:"
ps -eo pid,ppid,comm,rss --sort=-rss \
  | head -n "$((TOP_N + 1))" \
  | awk 'NR==1 {printf "   %7s %7s %-25s %10s\n", "PID", "PPID", "COMMAND", "RSS(MB)"; next}
         {printf "   %7d %7d %-25s %10.1f\n", $1, $2, $3, $4/1024}'
