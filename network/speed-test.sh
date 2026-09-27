#!/usr/bin/env bash
# speed-test: Test simple de velocidad de descarga (sin speedtest-cli).
# Uso: ./speed-test.sh [tamaño-MB] [url]
#   tamaño-MB por defecto: 10
#   url por defecto: Cloudflare
# Deps: curl

set -euo pipefail

SIZE_MB="${1:-10}"
URL="${2:-https://speed.cloudflare.com/__down?bytes=$((SIZE_MB * 1024 * 1024))}"

if [ "${1:-}" = "-h" ] || [ "${1:-}" = "--help" ]; then
  echo "Uso: speed-test.sh [tamaño-MB] [url]"
  echo "  tamaño-MB por defecto: 10"
  echo "  url por defecto: Cloudflare speed"
  exit 0
fi

if ! command -v curl >/dev/null; then
  echo "✗ curl no está instalado" >&2
  exit 1
fi

echo "→ Test de descarga"
echo "   Tamaño: ${SIZE_MB} MB"
echo "   URL:    $URL"
echo ""

# Descarga a /dev/null y mide velocidad.
RESULT=$(curl -fsSL --max-time 60 -o /dev/null -w \
  "time_total=%{time_total}\nsize_download=%{size_download}\nspeed_download=%{speed_download}\n" \
  "$URL" 2>/dev/null || true)

if [ -z "$RESULT" ]; then
  echo "✗ El test falló" >&2
  exit 1
fi

TIME=$(echo "$RESULT" | awk -F= '/time_total/ {print $2}')
SIZE=$(echo "$RESULT" | awk -F= '/size_download/ {print $2}')
SPEED_BPS=$(echo "$RESULT" | awk -F= '/speed_download/ {print $2}')

# Formatear velocidad.
SPEED_MBPS=$(awk -v s="$SPEED_BPS" 'BEGIN { printf "%.2f", s * 8 / 1000000 }')
SPEED_MBS=$(awk -v s="$SPEED_BPS" 'BEGIN { printf "%.2f", s / 1048576 }')
SIZE_MB_ACTUAL=$(awk -v s="$SIZE" 'BEGIN { printf "%.2f", s / 1048576 }')

echo "→ Resultados:"
printf '   Descargado:  %s MB\n' "$SIZE_MB_ACTUAL"
printf '   Tiempo:      %s s\n' "$TIME"
echo ""
printf '   Velocidad:   %s MB/s\n' "$SPEED_MBS"
printf '                %s Mbps\n' "$SPEED_MBPS"

# Interpretación.
CLASS=$(awk -v m="$SPEED_MBPS" 'BEGIN {
  if (m < 10) print "lenta"
  else if (m < 50) print "básica"
  else if (m < 200) print "buena"
  else if (m < 500) print "rápida"
  else print "muy rápida"
}')
echo ""
echo "   Categoría: $CLASS"
