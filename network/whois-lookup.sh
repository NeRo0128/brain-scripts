#!/usr/bin/env bash
# whois-lookup: Whois de un dominio o IP, con salida resumida.
# Uso: ./whois-lookup.sh <dominio|ip>
# Deps: whois

set -euo pipefail

if [ $# -lt 1 ] || [ "$1" = "-h" ] || [ "$1" = "--help" ]; then
  echo "Uso: whois-lookup.sh <dominio|ip>"
  exit 0
fi

TARGET="$1"

if ! command -v whois >/dev/null; then
  echo "✗ whois no está instalado" >&2
  exit 1
fi

echo "▶ Whois: $TARGET"
echo ""

RAW=$(whois "$TARGET" 2>/dev/null || true)

if [ -z "$RAW" ]; then
  echo "✗ Sin respuesta de whois" >&2
  exit 1
fi

# Extraer campos clave (varios TLDs usan distintos nombres).
extract_field() {
  local pattern="$1"
  echo "$RAW" | grep -iE "^$pattern" | head -1 | sed 's/^[^:]*:[[:space:]]*//'
}

# Crear función "extrae el primero que exista".
first_of() {
  for p in "$@"; do
    v=$(extract_field "$p")
    if [ -n "$v" ]; then
      echo "$v"
      return
    fi
  done
}

REGISTRAR=$(first_of "Registrar:" "Sponsoring Registrar:" "registrar:")
CREATED=$(first_of "Creation Date:" "Created On:" "created:" "Domain Registration Date:")
UPDATED=$(first_of "Updated Date:" "Last Updated On:" "last-modified:")
EXPIRES=$(first_of "Registry Expiry Date:" "Expiration Date:" "Expiry Date:" "paid-till:")
STATUS=$(first_of "Domain Status:" "Status:")
NAMESERVERS=$(echo "$RAW" | grep -iE "Name Server:" | awk '{print $NF}' | head -5)

echo "→ Registrador:  ${REGISTRAR:-?}"
echo "→ Creado:       ${CREATED:-?}"
echo "→ Actualizado:  ${UPDATED:-?}"
echo "→ Expira:       ${EXPIRES:-?}"
echo "→ Estado:       ${STATUS:-?}"
echo ""

if [ -n "$NAMESERVERS" ]; then
  echo "→ Name Servers:"
  echo "$NAMESERVERS" | sed 's/^/   /'
fi

# Si es IP, mostrar también el bloque de red.
if [[ "$TARGET" =~ ^[0-9.]+$ ]]; then
  echo ""
  echo "→ Rango de red:"
  echo "$RAW" | grep -iE "^(NetRange|CIDR|NetName|OrgName):" | sed 's/^/   /'
fi
