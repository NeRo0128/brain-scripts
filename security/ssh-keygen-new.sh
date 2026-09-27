#!/usr/bin/env bash
# ssh-keygen-new: Genera un par de claves SSH ed25519 (o RSA).
# Uso: ./ssh-keygen-new.sh <nombre> [comentario]
#   nombre:      se guarda en ~/.ssh/<nombre> y ~/.ssh/<nombre>.pub
#   comentario:  por defecto "user@host"
# Deps: ssh-keygen

set -euo pipefail

if [ $# -lt 1 ] || [ "$1" = "-h" ] || [ "$1" = "--help" ]; then
  echo "Uso: ssh-keygen-new.sh <nombre> [comentario]"
  echo ""
  echo "Ejemplos:"
  echo "  ssh-keygen-new.sh github"
  echo "  ssh-keygen-new.sh work 'me@work-laptop'"
  exit 0
fi

NAME="$1"
COMMENT="${2:-$(whoami)@$(hostname)}"

if ! command -v ssh-keygen >/dev/null; then
  echo "✗ ssh-keygen no está instalado" >&2
  exit 1
fi

# Directorio ~/.ssh.
SSH_DIR="$HOME/.ssh"
KEY_PATH="$SSH_DIR/$NAME"

if [ ! -d "$SSH_DIR" ]; then
  echo "→ Creando $SSH_DIR (modo 700)"
  mkdir -p "$SSH_DIR"
  chmod 700 "$SSH_DIR"
fi

if [ -e "$KEY_PATH" ] || [ -e "$KEY_PATH.pub" ]; then
  echo "✗ Ya existe: $KEY_PATH o $KEY_PATH.pub" >&2
  echo "   Elige otro nombre o borra las claves existentes manualmente." >&2
  exit 1
fi

echo "→ Generando clave ed25519"
echo "   Path:       $KEY_PATH"
echo "   Comentario: $COMMENT"
echo ""

# Pedir passphrase (opcional, en blanco = sin passphrase).
read -r -s -p "Passphrase (vacío = sin passphrase): " PW
echo ""

if [ -n "$PW" ]; then
  ssh-keygen -t ed25519 -f "$KEY_PATH" -N "$PW" -C "$COMMENT" >/dev/null
  unset PW
else
  ssh-keygen -t ed25519 -f "$KEY_PATH" -N "" -C "$COMMENT" >/dev/null
  echo "⚠  Clave sin passphrase. Considera añadir una después con:"
  echo "   ssh-keygen -p -f $KEY_PATH"
fi

# Verificar permisos (ssh-keygen los pone bien, pero por si acaso).
chmod 600 "$KEY_PATH"
chmod 644 "$KEY_PATH.pub"

echo ""
echo "✓ Clave generada:"
echo "   Privada: $KEY_PATH"
echo "   Pública: $KEY_PATH.pub"
echo ""
echo "→ Clave pública (para pegar en GitHub/GitLab/servidor):"
echo ""
cat "$KEY_PATH.pub"
echo ""
echo "→ Fingerprint:"
ssh-keygen -lf "$KEY_PATH.pub"
echo ""
echo "→ Próximos pasos:"
echo "   1. Copia la clave pública al servicio destino."
echo "   2. Añade a ~/.ssh/config si quieres alias:"
echo "        Host github.com"
echo "          IdentityFile $KEY_PATH"
