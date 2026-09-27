#!/usr/bin/env bash
# top-processes: Top N procesos por CPU o RAM.
# Uso: ./top-processes.sh [cpu|mem] [n]
#   modo por defecto: cpu
#   n por defecto: 10
# Deps: ps, sort

set -euo pipefail

MODE="${1:-cpu}"
N="${2:-10}"

if [ "$MODE" != "cpu" ] && [ "$MODE" != "mem" ]; then
  echo "✗ Modo inválido: $MODE (usa 'cpu' o 'mem')" >&2
  exit 1
fi

if ! [[ "$N" =~ ^[0-9]+$ ]] || [ "$N" -lt 1 ]; then
  echo "✗ N inválido: $N" >&2
  exit 1
fi

case "$MODE" in
  cpu)
    echo "→ Top $N procesos por CPU"
    echo ""
    ps -eo pid,ppid,user,%cpu,%mem,comm --sort=-%cpu \
      | head -n "$((N + 1))" \
      | awk 'NR==1 {printf "   %7s %7s %-12s %6s %6s %s\n", "PID", "PPID", "USER", "%CPU", "%MEM", "COMMAND"; next}
             {printf "   %7d %7d %-12s %6s %6s %s\n", $1, $2, $3, $4, $5, $6}'
    ;;
  mem)
    echo "→ Top $N procesos por RAM"
    echo ""
    ps -eo pid,ppid,user,%cpu,%mem,rss,comm --sort=-%mem \
      | head -n "$((N + 1))" \
      | awk 'NR==1 {printf "   %7s %7s %-12s %6s %6s %10s %s\n", "PID", "PPID", "USER", "%CPU", "%MEM", "RSS(MB)", "COMMAND"; next}
             {printf "   %7d %7d %-12s %6s %6s %10.1f %s\n", $1, $2, $3, $4, $5, $6/1024, $7}'
    ;;
esac
