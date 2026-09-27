#!/usr/bin/env bash
# ssl-cert-check: Verifica la expiración del certificado SSL de un host.
# Uso: ./ssl-cert-check.sh <host>[:puerto]
#   puerto por defecto: 443
# Deps: openssl

set -euo pipefail

if [ $# -lt 1 ] || [ "$1" = "-h" ] || [ "$1" = "--help" ]; then
  echo "Uso: ssl-cert-check.sh <host>[:puerto]"
  echo "  Ejemplo: ssl-cert-check.sh github.com"
  echo "           ssl-cert-check.sh example.com:8443"
  exit 0
fi

TARGET="$1"

# Parsear host:puerto.
if [[ "$TARGET" == *:* ]]; then
  HOST="${TARGET%%:*}"
  PORT="${TARGET##*:}"
else
  HOST="$TARGET"
  PORT=443
fi

if ! command -v openssl >/dev/null; then
  echo "✗ openssl no está instalado" >&2
  exit 1
fi

echo "▶ SSL Certificado: $HOST:$PORT"
echo ""

# Obtener el certificado.
CERT=$(echo | timeout 10 openssl s_client \
  -servername "$HOST" \
  -connect "$HOST:$PORT" \
  2>/dev/null \
  | openssl x509 -noout -dates -subject -issuer -ext subjectAltName 2>/dev/null)

if [ -z "$CERT" ]; then
  echo "✗ No se pudo obtener el certificado" >&2
  exit 1
fi

# Extraer datos.
SUBJECT=$(echo "$CERT" | grep '^subject=' | sed 's/subject=//')
ISSUER=$(echo "$CERT" | grep '^issuer=' | sed 's/issuer=//')
NOT_BEFORE=$(echo "$CERT" | grep '^notBefore=' | sed 's/notBefore=//')
NOT_AFTER=$(echo "$CERT" | grep '^notAfter=' | sed 's/notAfter=//')

echo "→ Emisor:"
echo "   $ISSUER"
echo ""
echo "→ Sujeto:"
echo "   $SUBJECT"
echo ""
echo "→ Validez:"
echo "   Desde: $NOT_BEFORE"
echo "   Hasta: $NOT_AFTER"
echo ""

# Días restantes.
if command -v date >/dev/null; then
  EXPIRY_EPOCH=$(date -d "$NOT_AFTER" +%s 2>/dev/null || date -j -f "%b %d %T %Y %Z" "$NOT_AFTER" +%s 2>/dev/null || echo "")
  NOW_EPOCH=$(date +%s)

  if [ -n "$EXPIRY_EPOCH" ]; then
    DAYS=$(( (EXPIRY_EPOCH - NOW_EPOCH) / 86400 ))
    echo "→ Días restantes: $DAYS"

    if [ "$DAYS" -lt 0 ]; then
      echo "   ⛔ EXPIRADO hace $((DAYS * -1)) días"
      exit 2
    elif [ "$DAYS" -lt 7 ]; then
      echo "   ⛔ Crítico (menos de 1 semana)"
      exit 2
    elif [ "$DAYS" -lt 30 ]; then
      echo "   ⚠  Próximo a expirar (menos de 30 días)"
      exit 1
    else
      echo "   ✓ OK"
    fi
  fi
fi

# SANs (dominios alternativos).
SANS=$(echo "$CERT" | grep -A1 'X509v3 Subject Alternative Name' | tail -1 | sed 's/^ *//')
if [ -n "$SANS" ]; then
  echo ""
  echo "→ Dominios alternativos (SANs):"
  echo "$SANS" | tr ',' '\n' | sed 's/DNS://g' | sed 's/^ */   /' | head -10
fi
