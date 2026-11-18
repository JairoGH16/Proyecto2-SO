#!/usr/bin/env bash
# Comando obligatorio de la Capa 3: midistro-info y sus módulos (uno por integrante). Idempotente.
set -euo pipefail
[ "$(id -u)" -eq 0 ] || { echo "Ejecutar como root (sudo)"; exit 1; }
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="${REPO_DIR:-$(dirname "$DIR")}"
LIB=/usr/local/lib/midistro-info

install -Dm755 "$REPO_DIR/bin/midistro-info" /usr/local/bin/midistro-info

# Se borran los módulos viejos para que no quede uno renombrado o eliminado del repo
install -d "$LIB"
rm -f "$LIB"/modulo_*.py
install -m644 "$REPO_DIR"/src/midistro-info/modulo_*.py "$LIB"/
echo "Instalado: midistro-info ($(ls "$LIB" | wc -l) módulos en $LIB)"
