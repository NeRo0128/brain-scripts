#!/usr/bin/env bash
# project-scan: Detecta el stack de un directorio (lenguajes, deps, tamaño).
# Uso: ./project-scan.sh [ruta]
#   ruta por defecto: .
# Deps: find, du, wc, ls

set -euo pipefail

TARGET="${1:-.}"

if [ ! -d "$TARGET" ]; then
  echo "✗ No existe: $TARGET" >&2
  exit 1
fi

cd "$TARGET"

echo "▶ Proyecto: $(pwd)"
echo ""

# Marcadores de stack.
declare -a MARKERS=(
  "package.json:NODE"
  "go.mod:GO"
  "Cargo.toml:RUST"
  "pyproject.toml:PYTHON"
  "requirements.txt:PYTHON"
  "setup.py:PYTHON"
  "Gemfile:RUBY"
  "composer.json:PHP"
  "pom.xml:JAVA"
  "build.gradle:JAVA"
  "build.gradle.kts:JAVA-KOTLIN"
  "Makefile:MAKE"
  "Dockerfile:DOCKER"
  "docker-compose.yml:DOCKER-COMPOSE"
  "compose.yaml:DOCKER-COMPOSE"
  "CMakeLists.txt:CMAKE"
)

echo "→ Stack detectado:"
FOUND=0
for m in "${MARKERS[@]}"; do
  file="${m%%:*}"
  label="${m##*:}"
  if [ -f "$file" ]; then
    echo "   ✓ $label ($file)"
    FOUND=$((FOUND + 1))
  fi
done
[ "$FOUND" -eq 0 ] && echo "   (ninguno conocido)"
echo ""

# Conteo de archivos por extensión (top 10).
echo "→ Archivos por extensión (top 10):"
find . -type f -not -path "./.git/*" -not -path "./node_modules/*" \
       -not -path "./vendor/*" -not -path "./target/*" 2>/dev/null \
  | sed 's/.*\.//' \
  | sort \
  | uniq -c \
  | sort -rn \
  | head -10 \
  | awk '{ printf "   %6d  .%s\n", $1, $2 }'
echo ""

# Tamaño total (sin .git).
SIZE=$(du -sh --exclude=.git . 2>/dev/null | cut -f1)
echo "→ Tamaño total (sin .git): $SIZE"
echo ""

# Último commit si es repo git.
if [ -d .git ]; then
  LAST=$(git log -1 --format="%h  %ar  %s" 2>/dev/null || echo "?")
  BRANCH=$(git branch --show-current 2>/dev/null || echo "?")
  echo "→ Último commit:"
  echo "   [$BRANCH] $LAST"
fi
