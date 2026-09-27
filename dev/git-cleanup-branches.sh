#!/usr/bin/env bash
# git-cleanup-branches: Borra branches locales ya mergeadas en main/master.
# Uso: ./git-cleanup-branches.sh [ruta-repo]
# Deps: git

set -euo pipefail

REPO="${1:-.}"

if [ ! -d "$REPO/.git" ]; then
  echo "✗ No es un repo git: $REPO" >&2
  exit 1
fi

cd "$REPO"

MAIN=$(git symbolic-ref refs/remotes/origin/HEAD 2>/dev/null | sed 's@^refs/remotes/origin/@@')
if [ -z "$MAIN" ]; then
  MAIN=main
  git show-ref --verify --quiet "refs/heads/main" || MAIN=master
fi

echo "→ Repo: $(pwd)"
echo "→ Rama principal: $MAIN"
echo ""

echo "→ Branches que se borrarán (ya mergeadas):"
git branch --merged "$MAIN" \
  | grep -v "^\*" \
  | grep -v "  $MAIN$" \
  | sed 's/^/  /'
echo ""

read -r -p "¿Confirmar borrado? [y/N] " ans
if [ "$ans" != "y" ] && [ "$ans" != "Y" ]; then
  echo "Cancelado."
  exit 0
fi

git branch --merged "$MAIN" \
  | grep -v "^\*" \
  | grep -v "  $MAIN$" \
  | xargs -r git branch -d

echo "✓ Limpieza completada"
