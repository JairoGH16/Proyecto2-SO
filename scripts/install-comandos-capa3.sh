#!/usr/bin/env bash
# Comandos libres de la Capa 3 del Tema 1: cambios-contexto (paquete) y presion-cpu (copia).
set -euo pipefail
: "${REPO_DIR:?falta REPO_DIR}"
: "${TARGET_USER:?falta TARGET_USER}"

install -Dm755 "$REPO_DIR/bin/presion-cpu" /usr/local/bin/presion-cpu

BUILD_DIR="$(mktemp -d /tmp/arenalos-build.XXXXXX)"
trap 'rm -rf "$BUILD_DIR"' EXIT
cp "$REPO_DIR/pacman/cambios-contexto/PKGBUILD" "$REPO_DIR/bin/cambios-contexto" "$BUILD_DIR/"
chown -R "$TARGET_USER:$TARGET_USER" "$BUILD_DIR"
sudo -u "$TARGET_USER" bash -c "cd '$BUILD_DIR' && makepkg -f --noconfirm"
pacman -U --noconfirm "$BUILD_DIR"/arenalos-cambios-contexto-*.pkg.tar.zst
