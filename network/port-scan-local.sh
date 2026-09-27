#!/usr/bin/env bash
# port-scan-local: Lista puertos abiertos en localhost.
# Uso: ./port-scan-local.sh
# Deps: ss (iproute2)

set -euo pipefail

if ! command -v ss >/dev/null; then
  echo "✗ 'ss' no está instalado (paquete: iproute2)" >&2
  exit 1
fi

echo "▶ Puertos abiertos en localhost"
echo ""

# TCP LISTEN.
echo "→ TCP (LISTEN):"
ss -tlnp 2>/dev/null \
  | tail -n +2 \
  | awk '{print $4, $6}' \
  | sort -u \
  | awk -F'[ :]+' '
      {
        addr = $1
        port = $NF
        proc = ""
        for (i = 1; i <= NF; i++) if ($i ~ /users:/) proc = $i
        sub(/.*users:\(\("/, "", proc)
        sub(/".*/, "", proc)
        printf "   %-22s %s\n", addr ":" port, proc
      }' \
  || true
echo ""

# UDP listeners (sin proceso, requiere root para verlos).
echo "→ UDP (listening):"
ss -ulnp 2>/dev/null \
  | tail -n +2 \
  | awk '{print $4}' \
  | sort -u \
  | sed 's/^/   /' \
  || true
echo ""

# Puertos en uso (conexiones establecidas).
echo "→ Conexiones establecidas (count por puerto local):"
ss -tn state established 2>/dev/null \
  | tail -n +2 \
  | awk '{print $3}' \
  | awk -F: '{print $NF}' \
  | sort -n \
  | uniq -c \
  | sort -rn \
  | head -10 \
  | awk '{printf "   %-8s %d conexiones\n", $2, $1}' \
  || true
