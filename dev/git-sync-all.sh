#!/usr/bin/env bash
# git-sync-all: Fetch + pull en todos los repos de una ruta.
# Uso: ./git-sync-all.sh [ruta] [--fetch-only]
#   ruta por defecto: $HOME/projects
#   --fetch-only: solo fetch, no pull (más seguro)
# Deps: git, find

set -euo pipefail

TARGET="${1:-$HOME/projects}"
FETCH_ONLY=false
[ "${2:-}" = "--fetch-only" ] && FETCH_ONLY=true

if [ ! -d "$TARGET" ]; then
  echo "✗ No existe: $TARGET" >&2
  exit 1
fi

echo "→ Ruta: $TARGET"
echo "→ Modo: $([ "$FETCH_ONLY" = true ] && echo "solo fetch" || echo "fetch + pull")"
echo ""

OK=0
FAIL=0
SKIP=0

while IFS= read -r -d '' gitdir; do
  repo=$(dirname "$gitdir")

  # Saltar si tiene cambios sin commitear.
  if [ -n "$(git -C "$repo" status --porcelain 2>/dev/null)" ]; then
    echo "   ⊘ $repo (working tree sucio, saltando)"
    SKIP=$((SKIP + 1))
    continue
  fi

  echo "   → $repo"
  if ! git -C "$repo" fetch --quiet 2>/dev/null; then
    echo "     ✗ fetch falló"
    FAIL=$((FAIL + 1))
    continue
  fi

  if ! $FETCH_ONLY; then
    branch=$(git -C "$repo" branch --show-current 2>/dev/null)
    if [ -n "$branch" ] && git -C "$repo" rev-parse --abbrev-ref "@{u}" >/dev/null 2>&1; then
      git -C "$repo" pull --quiet --ff-only 2>/dev/null || true
    fi
  fi

  OK=$((OK + 1))
done < <(find "$TARGET" -type d -name ".git" -print0 2>/dev/null)

echo ""
echo "✓ OK: $OK  |  ✗ Falló: $FAIL  |  ⊘ Saltados: $SKIP"
