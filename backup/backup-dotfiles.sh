#!/usr/bin/env bash
# backup-dotfiles: Backup de dotfiles comunes del $HOME.
# Uso: ./backup-dotfiles.sh [destino]
#   destino por defecto: ~/backups
# Deps: tar, date

set -euo pipefail

DEST="${1:-$HOME/backups}"
STAMP=$(date +%Y%m%d_%H%M%S)
OUT="$DEST/dotfiles_$STAMP.tar.gz"

# Archivos y carpetas a incluir (los que existan).
TARGETS=(
  .bashrc
  .bash_aliases
  .bash_profile
  .zshrc
  .zshenv
  .profile
  .gitconfig
  .gitignore_global
  .tmux.conf
  .vimrc
  .inputrc
  .ssh/config
  .config/nvim
  .config/kitty
  .config/alacritty
  .config/ghostty
  .config/niri
  .config/fish
)

# Filtrar solo los que existen.
EXISTING=()
for f in "${TARGETS[@]}"; do
  if [ -e "$HOME/$f" ]; then
    EXISTING+=("$f")
  fi
done

if [ ${#EXISTING[@]} -eq 0 ]; then
  echo "✗ No se encontraron dotfiles comunes en \$HOME" >&2
  exit 1
fi

mkdir -p "$DEST"

echo "→ Archivos a incluir (${#EXISTING[@]}):"
printf '   %s\n' "${EXISTING[@]}"
echo ""

tar -czf "$OUT" -C "$HOME" "${EXISTING[@]}"

SIZE=$(du -h "$OUT" | cut -f1)
echo "✓ Backup completado: $OUT ($SIZE)"
