#!/usr/bin/env bash
# Comandos libres de los Temas 8 y 9 (Esteban): usb-historial y puertos-abiertos. Idempotente.
# udev/install.sh y security/install.sh no los copian al PATH, y los atajos
# Super+U y Super+Shift+P los llaman por nombre.
set -euo pipefail
[ "$(id -u)" -eq 0 ] || { echo "Ejecutar como root (sudo)"; exit 1; }
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="${REPO_DIR:-$(dirname "$DIR")}"

install -Dm755 "$REPO_DIR/bin/usb-historial" /usr/local/bin/usb-historial
install -Dm755 "$REPO_DIR/bin/puertos-abiertos" /usr/local/bin/puertos-abiertos
echo "Instalados: usb-historial, puertos-abiertos"
