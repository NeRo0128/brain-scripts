#!/usr/bin/env bash
# system-report: Reporte completo del sistema (todo en uno).
# Uso: ./system-report.sh
# Deps: las de los otros scripts de monitoring/
#
# Ejecuta los otros scripts de monitoring/ si están disponibles.
# Si no los encuentra, produce un reporte mínimo autocontenido.

set -euo pipefail

# Directorio donde viven los otros scripts (por si se invoca desde fuera).
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

have() { [ -x "$SCRIPT_DIR/$1" ]; }

run_script() {
  local name="$1"
  shift
  if have "$name"; then
    echo "──────────────────────────────────────────────"
    echo "▶ $name"
    echo "──────────────────────────────────────────────"
    "$SCRIPT_DIR/$name" "$@" || echo "   (falló)"
    echo ""
  fi
}

echo ""
echo "╔══════════════════════════════════════════════╗"
echo "║  SYSTEM REPORT                               ║"
echo "║  $(date '+%Y-%m-%d %H:%M:%S')                    ║"
echo "╚══════════════════════════════════════════════╝"
echo ""

# Header del sistema.
if [ -r /etc/os-release ]; then
  # shellcheck disable=SC1091
  . /etc/os-release
  echo "▶ Host:  $(hostname)"
  echo "   OS:   ${PRETTY_NAME:-unknown}"
  echo "   Kernel: $(uname -r)"
  echo "   Arch: $(uname -m)"
  echo ""
fi

run_script "load-average.sh"
run_script "cpu-usage.sh" 1
run_script "memory-usage.sh" 5
run_script "disk-usage.sh" / 5
run_script "top-processes.sh" cpu 5
run_script "network-traffic.sh"

echo "──────────────────────────────────────────────"
echo "→ Fin del reporte"
echo "──────────────────────────────────────────────"
