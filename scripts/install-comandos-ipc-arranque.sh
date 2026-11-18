#!/usr/bin/env bash
# Comandos libres de los Temas 5 y 7. Idempotente.
set -euo pipefail

[ "$(id -u)" -eq 0 ] || { echo "Ejecutar como root (sudo)"; exit 1; }

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(dirname "$DIR")"

install -Dm755 "$REPO_DIR/bin/ipc-activo" /usr/local/bin/ipc-activo
install -Dm755 "$REPO_DIR/bin/arranque-info" /usr/local/bin/arranque-info
echo "Instalados: ipc-activo, arranque-info"