#!/usr/bin/env bash
# git-gc-all: Corre `git gc` en todos los repos de una ruta.
# Uso: ./git-gc-all.sh [ruta] [--aggressive]
#   ruta por defecto: $HOME/projects
# Deps: git, find

set -euo pipefail

TARGET="${1:-$HOME/projects}"
AGGRESSIVE=false
[ "${2:-}" = "--aggressive" ] && AGGRESSIVE=true

if [ ! -d "$TARGET" ]; then
  echo "✗ No existe: $TARGET" >&2
  exit 1
fi

echo "→ Buscando repos git en $TARGET"
if $AGGRESSIVE; then
  echo "   Modo: --aggressive (más lento, mejor compresión)"
fi
echo ""

COUNT=0
while IFS= read -r -d '' gitdir; do
  repo=$(dirname "$gitdir")
  echo "   → $repo"
  if $AGGRESSIVE; then
    git -C "$repo" gc --aggressive --prune=now >/dev/null 2>&1
  else
    git -C "$repo" gc --prune=now >/dev/null 2>&1
  fi
  COUNT=$((COUNT + 1))
done < <(find "$TARGET" -type d -name ".git" -print0 2>/dev/null)

echo ""
echo "✓ $COUNT repos procesados"
