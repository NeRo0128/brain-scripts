#!/usr/bin/env bash
# load-average: Load average + uptime + interpretación.
# Uso: ./load-average.sh
# Deps: /proc/loadavg, /proc/uptime

set -euo pipefail

if [ ! -r /proc/loadavg ]; then
  echo "✗ /proc/loadavg no accesible" >&2
  exit 1
fi

CORES=$(nproc 2>/dev/null || grep -c '^processor' /proc/cpuinfo)

read -r L1 L5 L15 _ <<< "$(cat /proc/loadavg)"

# Uptime legible.
if [ -r /proc/uptime ]; then
  UP=$(awk '{print int($1)}' /proc/uptime)
  DAYS=$((UP / 86400))
  HOURS=$(((UP % 86400) / 3600))
  MINS=$(((UP % 3600) / 60))
  if [ "$DAYS" -gt 0 ]; then
    UP_STR="${DAYS}d ${HOURS}h ${MINS}m"
  elif [ "$HOURS" -gt 0 ]; then
    UP_STR="${HOURS}h ${MINS}m"
  else
    UP_STR="${MINS}m"
  fi
else
  UP_STR="?"
fi

echo "▶ Load Average"
echo "   Núcleos:  $CORES"
echo "   Uptime:   $UP_STR"
echo ""
echo "   1 min:    $L1"
echo "   5 min:    $L5"
echo "   15 min:   $L15"
echo ""

# Interpretación: load / cores.
interpret() {
  local load="$1"
  local pct
  pct=$(awk -v l="$load" -v c="$CORES" 'BEGIN { printf "%d", (l / c) * 100 }')
  if [ "$pct" -lt 50 ]; then
    echo "OK (${pct}% de capacidad)"
  elif [ "$pct" -lt 80 ]; then
    echo "Moderado (${pct}%)"
  elif [ "$pct" -lt 120 ]; then
    echo "Alto (${pct}%)"
  else
    echo "Saturado (${pct}%)"
  fi
}

echo "→ Estado (load / núcleos):"
echo "   1 min:    $(interpret "$L1")"
echo "   5 min:    $(interpret "$L5")"
echo "   15 min:   $(interpret "$L15")"
