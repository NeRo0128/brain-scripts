#!/usr/bin/env bash
# boot-time: Análisis de tiempo de arranque.
# Uso: ./boot-time.sh [--blame]
#   --blame: muestra los servicios que más tardaron (systemd-analyze blame)
# Deps: systemd-analyze (si está disponible) o fallback a /proc/uptime

set -euo pipefail

BLAME=false
[ "${1:-}" = "--blame" ] && BLAME=true

if [ "${1:-}" = "-h" ] || [ "$1" = "--help" ]; then
  echo "Uso: boot-time.sh [--blame]"
  echo "  --blame: top 10 servicios que más tardaron en arrancar"
  exit 0
fi

echo "▶ Boot Time"
echo ""

if command -v systemd-analyze >/dev/null; then
  # Tiempo total de arranque.
  echo "→ Tiempo total:"
  systemd-analyze 2>/dev/null | sed 's/^/   /'
  echo ""

  # Desglose (firmware, loader, kernel, userspace).
  if systemd-analyze time 2>/dev/null | grep -q .; then
    echo "→ Desglose:"
    systemd-analyze time 2>/dev/null \
      | grep -E "firmware|loader|kernel|userspace" \
      | sed 's/^/   /'
    echo ""
  fi

  # Cadena crítica (qué bloqueó el boot).
  if systemd-analyze critical-chain 2>/dev/null | grep -q .; then
    echo "→ Cadena crítica (top 10):"
    systemd-analyze critical-chain 2>/dev/null | head -10 | sed 's/^/   /'
    echo ""
  fi

  # Blame (opcional).
  if $BLAME; then
    echo "→ Top 10 servicios más lentos:"
    systemd-analyze blame 2>/dev/null | head -10 | sed 's/^/   /'
    echo ""
  fi

else
  echo "⚠  systemd-analyze no disponible (¿sistema sin systemd?)"
  echo ""

  # Fallback: uptime simple.
  if [ -r /proc/uptime ]; then
    UP=$(awk '{print int($1)}' /proc/uptime)
    echo "→ Uptime actual: ${UP}s ($((UP / 3600))h $(((UP % 3600) / 60))m)"
    echo "   (El tiempo de arranque real requiere systemd-analyze)"
  fi
fi

# Info extra: fecha del boot.
if [ -r /proc/stat ]; then
  BOOT_EPOCH=$(awk '/^btime/ {print $2}' /proc/stat)
  if [ -n "$BOOT_EPOCH" ]; then
    echo ""
    echo "→ Última vez arrancado:"
    date -d "@$BOOT_EPOCH" '+   %Y-%m-%d %H:%M:%S' 2>/dev/null \
      || date -r "$BOOT_EPOCH" '+   %Y-%m-%d %H:%M:%S' 2>/dev/null \
      || echo "   (epoch: $BOOT_EPOCH)"
  fi
fi
