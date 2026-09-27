#!/usr/bin/env bash
# service-status: Estado de servicios systemd.
# Uso: ./service-status.sh [filtro]
#   Sin args: muestra los failed + running.
#   Con filtro: busca servicios que matcheen.
# Deps: systemctl

set -euo pipefail

if ! command -v systemctl >/dev/null; then
  echo "✗ systemctl no está instalado (¿sistema sin systemd?)" >&2
  exit 1
fi

FILTER="${1:-}"

# ─── Failed ───
echo "→ Servicios FALLIDOS:"
FAILED=$(systemctl list-units --type=service --state=failed --no-legend --no-pager 2>/dev/null || true)
if [ -z "$FAILED" ]; then
  echo "   ✓ Ninguno"
else
  echo "$FAILED" | awk '{print "   ✗ " $1 "  " $4}' | head -20
fi
echo ""

if [ -n "$FILTER" ]; then
  # ─── Búsqueda por filtro ───
  echo "→ Servicios que matchean '$FILTER':"
  systemctl list-units --type=service --all --no-legend --no-pager 2>/dev/null \
    | grep -i "$FILTER" \
    | awk '{printf "   %-40s %-10s %s\n", $1, $3, $4}' \
    | head -20
  echo ""
fi

# ─── Running (top 15) ───
echo "→ Servicios ACTIVOS (top 15 por memoria):"
systemctl list-units --type=service --state=running --no-legend --no-pager 2>/dev/null \
  | awk '{print $1}' \
  | head -15 \
  | while read -r svc; do
      printf '   %-40s\n' "$svc"
    done

echo ""
echo "→ Contadores:"
TOTAL=$(systemctl list-units --type=service --all --no-legend --no-pager 2>/dev/null | wc -l)
RUNNING=$(systemctl list-units --type=service --state=running --no-legend --no-pager 2>/dev/null | wc -l)
FAILED_N=$(systemctl list-units --type=service --state=failed --no-legend --no-pager 2>/dev/null | wc -l)
echo "   Total:    $TOTAL"
echo "   Running:  $RUNNING"
echo "   Failed:   $FAILED_N"
