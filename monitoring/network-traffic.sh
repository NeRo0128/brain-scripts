#!/usr/bin/env bash
# network-traffic: Tráfico RX/TX por interfaz de red.
# Uso: ./network-traffic.sh [interfaz]
#   sin arg: muestra todas las interfaces activas (excepto lo)
# Deps: ip, awk

set -euo pipefail

IFACE="${1:-}"

if [ ! -d /sys/class/net ]; then
  echo "✗ /sys/class/net no accesible" >&2
  exit 1
fi

format_bytes() {
  local b="$1"
  awk -v b="$b" 'BEGIN {
    split("B KB MB GB TB", u, " ")
    i = 1
    while (b >= 1024 && i < 5) { b /= 1024; i++ }
    printf "%.2f %s", b, u[i]
  }'
}

show_iface() {
  local iface="$1"
  local base="/sys/class/net/$iface/statistics"

  [ -d "$base" ] || return 1

  local rx_bytes tx_bytes rx_packets tx_packets rx_errs tx_errs
  rx_bytes=$(cat "$base/rx_bytes")
  tx_bytes=$(cat "$base/tx_bytes")
  rx_packets=$(cat "$base/rx_packets")
  tx_packets=$(cat "$base/tx_packets")
  rx_errs=$(cat "$base/rx_errors")
  tx_errs=$(cat "$base/tx_errors")

  local state
  state=$(cat "/sys/class/net/$iface/operstate" 2>/dev/null || echo "?")

  printf '▶ %s (%s)\n' "$iface" "$state"
  printf '   RX:  %12s   %10d pkts   %5d errs\n' \
    "$(format_bytes "$rx_bytes")" "$rx_packets" "$rx_errs"
  printf '   TX:  %12s   %10d pkts   %5d errs\n' \
    "$(format_bytes "$tx_bytes")" "$tx_packets" "$tx_errs"
  echo ""
}

if [ -n "$IFACE" ]; then
  if [ ! -d "/sys/class/net/$IFACE" ]; then
    echo "✗ Interfaz no existe: $IFACE" >&2
    exit 1
  fi
  show_iface "$IFACE"
else
  for d in /sys/class/net/*; do
    name=$(basename "$d")
    [ "$name" = "lo" ] && continue
    show_iface "$name"
  done
fi
