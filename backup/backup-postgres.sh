#!/usr/bin/env bash
# backup-postgres: Backup de todas las bases PostgreSQL accesibles.
# Uso: ./backup-postgres.sh [destino]
#   destino por defecto: ~/backups/postgres
# Variables de entorno (opcionales):
#   PGUSER (default: postgres)
#   PGHOST (default: localhost)
#   PGPASSWORD (si no se usa ~/.pgpass)
# Deps: pg_dump, gzip, psql, date

set -euo pipefail

DEST="${1:-$HOME/backups/postgres}"
STAMP=$(date +%Y%m%d_%H%M%S)
USER="${PGUSER:-postgres}"
HOST="${PGHOST:-localhost}"

if ! command -v pg_dump >/dev/null; then
  echo "✗ pg_dump no está instalado" >&2
  exit 1
fi

export PGUSER="$USER"
export PGHOST="$HOST"

# Probar conexión.
if ! psql -l >/dev/null 2>&1; then
  echo "✗ No se pudo conectar a PostgreSQL en $HOST como $USER" >&2
  echo "   Configura ~/.pgpass o exporta PGUSER/PGPASSWORD" >&2
  exit 1
fi

mkdir -p "$DEST"

# Listar DBs de usuario (excluir template*, postgres).
DBS=$(psql -At -c "SELECT datname FROM pg_database WHERE datistemplate = false AND datname NOT IN ('postgres')")

if [ -z "$DBS" ]; then
  echo "→ No hay bases de datos de usuario"
  exit 0
fi

echo "→ Backing up a $DEST"
echo ""

for db in $DBS; do
  OUT="$DEST/${db}_${STAMP}.sql.gz"
  echo "   → $db"
  pg_dump --clean --if-exists --no-owner "$db" | gzip > "$OUT"
  SIZE=$(du -h "$OUT" | cut -f1)
  echo "     ✓ $OUT ($SIZE)"
done

echo ""
echo "✓ Backups completados: $(echo "$DBS" | wc -l) DBs"
