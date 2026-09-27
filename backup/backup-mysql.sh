#!/usr/bin/env bash
# backup-mysql: Backup de todas las bases MySQL/MariaDB accesibles.
# Uso: ./backup-mysql.sh [destino]
#   destino por defecto: ~/backups/mysql
# Variables de entorno (opcionales):
#   MYSQL_USER (default: root)
#   MYSQL_PASSWORD (si no se usa ~/.my.cnf)
#   MYSQL_HOST (default: localhost)
# Deps: mysqldump, gzip, date

set -euo pipefail

DEST="${1:-$HOME/backups/mysql}"
STAMP=$(date +%Y%m%d_%H%M%S)
USER="${MYSQL_USER:-root}"
HOST="${MYSQL_HOST:-localhost}"

if ! command -v mysqldump >/dev/null; then
  echo "✗ mysqldump no está instalado" >&2
  exit 1
fi

# Detectar credenciales: env var tiene prioridad; si no, asumimos ~/.my.cnf.
MYSQL_ARGS=(-h "$HOST" -u "$USER")
if [ -n "${MYSQL_PASSWORD:-}" ]; then
  export MYSQL_PWD="$MYSQL_PASSWORD"
fi

# Probar conexión.
if ! mysql "${MYSQL_ARGS[@]}" -e "SELECT 1" >/dev/null 2>&1; then
  echo "✗ No se pudo conectar a MySQL en $HOST como $USER" >&2
  echo "   Configura ~/.my.cnf o exporta MYSQL_USER/MYSQL_PASSWORD" >&2
  exit 1
fi

mkdir -p "$DEST"

# Listar DBs de usuario (excluir las del sistema).
DBS=$(mysql "${MYSQL_ARGS[@]}" -N -e "SHOW DATABASES" \
  | grep -Ev '^(information_schema|performance_schema|mysql|sys)$')

if [ -z "$DBS" ]; then
  echo "→ No hay bases de datos de usuario"
  exit 0
fi

echo "→ Backing up a $DEST"
echo ""

for db in $DBS; do
  OUT="$DEST/${db}_${STAMP}.sql.gz"
  echo "   → $db"
  mysqldump "${MYSQL_ARGS[@]}" \
    --single-transaction \
    --routines \
    --triggers \
    --events \
    "$db" | gzip > "$OUT"
  SIZE=$(du -h "$OUT" | cut -f1)
  echo "     ✓ $OUT ($SIZE)"
done

echo ""
echo "✓ Backups completados: $(echo "$DBS" | wc -l) DBs"
