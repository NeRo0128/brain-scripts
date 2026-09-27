#!/usr/bin/env bash
# dns-lookup: Consulta DNS contra múltiples resolvers públicos.
# Uso: ./dns-lookup.sh <dominio>
# Deps: dig (bind-utils / dnsutils)

set -euo pipefail

if [ $# -lt 1 ] || [ "$1" = "-h" ] || [ "$1" = "--help" ]; then
  echo "Uso: dns-lookup.sh <dominio>"
  echo "  Consulta A, AAAA, CNAME, MX, NS, TXT y compara 4 resolvers."
  exit 0
fi

DOMAIN="$1"

if ! command -v dig >/dev/null; then
  echo "✗ dig no está instalado (paquete: bind-utils o dnsutils)" >&2
  exit 1
fi

# Resolvers públicos.
declare -A RESOLVERS=(
  ["Cloudflare"]="1.1.1.1"
  ["Google"]="8.8.8.8"
  ["Quad9"]="9.9.9.9"
  ["OpenDNS"]="208.67.222.222"
)

echo "▶ DNS Lookup: $DOMAIN"
echo ""

# Records principales.
for rtype in A AAAA CNAME MX NS TXT; do
  out=$(dig +short "$rtype" "$DOMAIN" 2>/dev/null | head -5)
  if [ -n "$out" ]; then
    printf '   %-6s %s\n' "$rtype" "$(echo "$out" | head -1)"
    echo "$out" | tail -n +2 | sed 's/^/          /'
  fi
done
echo ""

# Comparar resolvers para tipo A.
echo "→ Comparando resolvers (registro A):"
for name in "${!RESOLVERS[@]}"; do
  ip="${RESOLVERS[$name]}"
  result=$(dig +short @$ip A "$DOMAIN" 2>/dev/null | head -1)
  printf '   %-12s (%s): %s\n' "$name" "$ip" "${result:-sin respuesta}"
done

echo ""
echo "→ Tiempo de resolución (resolver por defecto):"
dig "$DOMAIN" A 2>/dev/null | grep -E "^;; Query time" | sed 's/^/   /' || true
