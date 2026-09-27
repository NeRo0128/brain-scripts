#!/usr/bin/env bash
# git-status-all: Muestra el estado de git en todos los repos de una ruta.
# Uso: ./git-status-all.sh [ruta] [--short]
#   ruta por defecto: $HOME/projects
#   --short: resumen (una línea por repo, solo los "sucios")
# Deps: git, find

set -euo pipefail

TARGET="${1:-$HOME/projects}"
SHORT=false
[ "${2:-}" = "--short" ] && SHORT=true

if [ ! -d "$TARGET" ]; then
  echo "✗ No existe: $TARGET" >&2
  exit 1
fi

COUNT=0
DIRTY=0

while IFS= read -r -d '' gitdir; do
  repo=$(dirname "$gitdir")
  COUNT=$((COUNT + 1))

  branch=$(git -C "$repo" branch --show-current 2>/dev/null || echo "(detached)")
  status=$(git -C "$repo" status --porcelain 2>/dev/null)

  if [ -n "$status" ]; then
    DIRTY=$((DIRTY + 1))
    if $SHORT; then
      echo "[$branch] $repo"
    else
      echo ""
      echo "▶ $repo"
      echo "  rama: $branch"
      git -C "$repo" status -sb 2>/dev/null | sed 's/^/  /'
    fi
  elif ! $SHORT; then
    echo ""
    echo "▶ $repo"
    echo "  rama: $branch  ✓ limpio"
  fi
done < <(find "$TARGET" -type d -name ".git" -print0 2>/dev/null)

echo ""
if $SHORT; then
  echo "→ $DIRTY / $COUNT repos con cambios"
else
  echo "→ $DIRTY / $COUNT repos con cambios sin commitear"
fi
