#!/usr/bin/env bash
# hardware-info: Resumen del hardware (CPU, RAM, disco, GPU, etc.).
# Uso: ./hardware-info.sh
# Deps: /proc, lscpu (opcional), lspci (opcional), lsblk (opcional)

set -euo pipefail

echo "▶ Hardware"
echo ""

# ─── CPU ───
echo "→ CPU:"
if [ -r /proc/cpuinfo ]; then
  MODEL=$(awk -F: '/^model name/ {print $2; exit}' /proc/cpuinfo | sed 's/^ *//')
  CORES=$(grep -c '^processor' /proc/cpuinfo)
  [ -n "$MODEL" ] && echo "   Modelo:   $MODEL"
  echo "   Núcleos:  $CORES"

  if command -v lscpu >/dev/null; then
    MHZ=$(lscpu | awk -F: '/CPU MHz/ {print $2; exit}' | sed 's/^ *//')
    CACHE=$(lscpu | awk -F: '/L3 cache/ {print $2; exit}' | sed 's/^ *//')
    [ -n "$MHZ" ] && echo "   Freq:     ${MHZ} MHz"
    [ -n "$CACHE" ] && echo "   L3 cache: $CACHE"
  fi
fi
echo ""

# ─── RAM ───
echo "→ Memoria:"
if command -v free >/dev/null; then
  TOTAL=$(free -h | awk '/^Mem:/ {print $2}')
  echo "   Total RAM: $TOTAL"
fi
if [ -r /proc/meminfo ]; then
  SWAP=$(awk '/^SwapTotal/ {printf "%.1f GB", $2/1024/1024}' /proc/meminfo)
  echo "   Swap:      $SWAP"
fi
echo ""

# ─── Discos ───
echo "→ Discos:"
if command -v lsblk >/dev/null; then
  lsblk -d -o NAME,SIZE,TYPE,MODEL 2>/dev/null | head -10 | sed 's/^/   /'
elif command -v df >/dev/null; then
  df -h -x tmpfs -x devtmpfs 2>/dev/null | head -10 | sed 's/^/   /'
fi
echo ""

# ─── GPU ───
echo "→ GPU:"
if command -v lspci >/dev/null; then
  GPUS=$(lspci 2>/dev/null | grep -iE 'vga|3d|display' || true)
  if [ -n "$GPUS" ]; then
    echo "$GPUS" | sed 's/^/   /'
  else
    echo "   (no detectada vía lspci)"
  fi
else
  # Fallback: /sys.
  if [ -d /sys/class/drm ]; then
    for card in /sys/class/drm/card*/device/vendor; do
      [ -r "$card" ] || continue
      vendor=$(cat "$card" 2>/dev/null)
      echo "   Vendor ID: $vendor"
    done
  else
    echo "   (lspci no instalado)"
  fi
fi
echo ""

# ─── Batería (laptops) ───
if [ -d /sys/class/power_supply ]; then
  for bat in /sys/class/power_supply/BAT*; do
    [ -d "$bat" ] || continue
    name=$(basename "$bat")
    if [ -r "$bat/capacity" ]; then
      cap=$(cat "$bat/capacity")
      status=$(cat "$bat/status" 2>/dev/null || echo "?")
      echo "→ Batería $name: ${cap}% (${status})"
    fi
  done
fi
