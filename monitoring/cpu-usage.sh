#!/usr/bin/env bash
# cpu-usage: Snapshot de uso de CPU (medido sobre un intervalo).
# Uso: ./cpu-usage.sh [segundos]
#   segundos por defecto: 1
# Deps: (ninguna — usa /proc/stat directamente)

set -euo pipefail

INTERVAL="${1:-1}"

if ! [[ "$INTERVAL" =~ ^[0-9]+$ ]] || [ "$INTERVAL" -lt 1 ]; then
  echo "✗ Intervalo inválido: $INTERVAL" >&2
  exit 1
fi

if [ ! -r /proc/stat ]; then
  echo "✗ /proc/stat no es accesible (¿estás en Linux?)" >&2
  exit 1
fi

read_cpu() {
  # user nice system idle iowait irq softirq steal
  awk '/^cpu / {print $2,$3,$4,$5,$6,$7,$8,$9}' /proc/stat
}

T1=$(read_cpu)
sleep "$INTERVAL"
T2=$(read_cpu)

# Calcular delta total y delta busy.
read -r u1 n1 s1 i1 w1 q1 sq1 st1 <<< "$T1"
read -r u2 n2 s2 i2 w2 q2 sq2 st2 <<< "$T2"

IDLE1=$((i1 + w1))
IDLE2=$((i2 + w2))
TOTAL1=$((u1 + n1 + s1 + i1 + w1 + q1 + sq1 + st1))
TOTAL2=$((u2 + n2 + s2 + i2 + w2 + q2 + sq2 + st2))

DTOTAL=$((TOTAL2 - TOTAL1))
DIDLE=$((IDLE2 - IDLE1))
DBUSY=$((DTOTAL - DIDLE))

if [ "$DTOTAL" -le 0 ]; then
  echo "✗ No se pudo medir (delta=0)" >&2
  exit 1
fi

PCT=$(( DBUSY * 100 / DTOTAL ))
CORES=$(nproc 2>/dev/null || grep -c '^processor' /proc/cpuinfo)

echo "▶ CPU Usage ($INTERVAL s)"
echo "   Uso:    $PCT %"
echo "   Núcleos: $CORES"

# Barra visual simple.
FILLED=$((PCT * 20 / 100))
BAR=$(printf '#%.0s' $(seq 1 "$FILLED" 2>/dev/null) || true)
EMPTY=$(printf '.%.0s' $(seq 1 "$((20 - FILLED))" 2>/dev/null) || true)
echo "   [$BAR$EMPTY]"
