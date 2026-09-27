#!/usr/bin/env bash
# kernel-info: Información del kernel y la distribución.
# Uso: ./kernel-info.sh
# Deps: uname, /etc/os-release

set -euo pipefail

echo "▶ Kernel & Sistema"
echo ""

# Datos del kernel.
echo "→ Kernel:"
echo "   Release:   $(uname -r)"
echo "   Versión:   $(uname -v)"
echo "   Arquitectura: $(uname -m)"
echo "   Hostname:  $(uname -n)"
echo ""

# Distro.
if [ -r /etc/os-release ]; then
  # shellcheck disable=SC1091
  . /etc/os-release
  echo "→ Distribución:"
  echo "   Nombre:    ${PRETTY_NAME:-unknown}"
  echo "   ID:        ${ID:-?}"
  echo "   Versión:   ${VERSION_ID:-?}"
  [ -n "${HOME_URL:-}" ] && echo "   Home:      $HOME_URL"
  echo ""
fi

# Info extra útil.
if [ -r /proc/version ]; then
  echo "→ /proc/version:"
  cat /proc/version | sed 's/^/   /'
  echo ""
fi

# Fecha de compilación del kernel (útil para saber si está viejo).
if command -v modinfo >/dev/null && [ -d /lib/modules/$(uname -r) ]; then
  BUILT=$(modinfo -F vermagic "$(ls /lib/modules/$(uname -r)/kernel/*/*.ko* 2>/dev/null | head -1)" 2>/dev/null || echo "")
  [ -n "$BUILT" ] && echo "→ Módulos: $BUILT"
fi

# Uptime.
if [ -r /proc/uptime ]; then
  UP=$(awk '{print int($1)}' /proc/uptime)
  DAYS=$((UP / 86400))
  HOURS=$(((UP % 86400) / 3600))
  MINS=$(((UP % 3600) / 60))
  if [ "$DAYS" -gt 0 ]; then
    echo "→ Uptime: ${DAYS}d ${HOURS}h ${MINS}m"
  elif [ "$HOURS" -gt 0 ]; then
    echo "→ Uptime: ${HOURS}h ${MINS}m"
  else
    echo "→ Uptime: ${MINS}m"
  fi
fi
