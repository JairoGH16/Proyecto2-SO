#!/usr/bin/env bash
# Integra en ArenalOS lo de los temas 1 y 6: hook de pacman y paquete arenalos-procesos.
# Lo llama install.sh; usa REPO_DIR, TARGET_USER y TARGET_HOME exportadas por el.
set -euo pipefail

: "${REPO_DIR:?Debe llamarse desde install.sh}"
: "${TARGET_USER:?Debe llamarse desde install.sh}"

# 1. Hook propio de pacman
install -Dm644 "$REPO_DIR/pacman/arenalos-explicitos.hook" /etc/pacman.d/hooks/arenalos-explicitos.hook

# 2. Paquete propio: se construye como el usuario normal (makepkg no corre como root)
BUILD_DIR="$(mktemp -d /tmp/arenalos-build.XXXXXX)"
cp "$REPO_DIR/pacman/PKGBUILD" "$REPO_DIR/src/procesos/procesos.py" "$BUILD_DIR/"
chown -R "$TARGET_USER":"$TARGET_USER" "$BUILD_DIR"
sudo -u "$TARGET_USER" bash -c "cd '$BUILD_DIR' && makepkg -f --noconfirm"
pacman -U --noconfirm "$BUILD_DIR"/arenalos-procesos-*.pkg.tar.zst
rm -rf "$BUILD_DIR"
