#!/usr/bin/env bash
# user-list: Usuarios del sistema y sus shells.
# Uso: ./user-list.sh [--human-only]
#   --human-only: solo usuarios con UID >= 1000 (excluye sistema)
# Deps: getent, awk

set -euo pipefail

HUMAN_ONLY=false
[ "${1:-}" = "--human-only" ] && HUMAN_ONLY=true

if [ "${1:-}" = "-h" ] || [ "${1:-}" = "--help" ]; then
  echo "Uso: user-list.sh [--human-only]"
  echo "  --human-only: solo UIDs >= 1000"
  exit 0
fi

if ! command -v getent >/dev/null; then
  echo "✗ getent no está instalado (glibc)" >&2
  exit 1
fi

echo "▶ Usuarios del sistema"
$HUMAN_ONLY && echo "   (solo humanos, UID >= 1000)"
echo ""

# Cabecera.
printf '   %-20s %6s %6s %-25s %s\n' "USERNAME" "UID" "GID" "SHELL" "HOME"
echo "   ────────────────────────────────────────────────────────────────────────"

# Iterar usuarios de /etc/passwd (o NSS via getent).
getent passwd | while IFS=: read -r name _ uid gid _ home shell; do
  if $HUMAN_ONLY; then
    # Solo UIDs de usuario real.
    [ "$uid" -lt 1000 ] && continue
    # Saltar nobody, systemd-*, etc.
    case "$name" in
      nobody|systemd-*|messagebus|polkitd) continue ;;
    esac
  fi

  printf '   %-20s %6s %6s %-25s %s\n' "$name" "$uid" "$gid" "$shell" "$home"
done

echo ""
echo "→ Resumen:"
TOTAL=$(getent passwd | wc -l)
HUMANS=$(getent passwd | awk -F: '$3 >= 1000 && $1 != "nobody" {n++} END {print n}')
echo "   Total:    $TOTAL"
echo "   Humanos:  $HUMANS"
echo ""

# Usuarios logueados actualmente.
echo "→ Actualmente logueados:"
who 2>/dev/null | awk '{printf "   %-15s %-10s %s %s %s\n", $1, $2, $3, $4, $5}' || echo "   (comando 'who' no disponible)"
