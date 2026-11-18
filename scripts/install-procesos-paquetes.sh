#!/usr/bin/env bash
# Integra en ArenalOS lo de los temas 1 y 6: hook de pacman y paquete arenalos-procesos.
# Lo llama install.sh; usa REPO_DIR, TARGET_USER y TARGET_HOME exportadas por el.
set -euo pipefail

: "${REPO_DIR:?Debe llamarse desde install.sh}"
: "${TARGET_USER:?Debe llamarse desde install.sh}"

# 1. Hook propio de pacman
install -Dm644 "$REPO_DIR/pacman/arenalos-explicitos.hook" /etc/pacman.d/hooks/arenalos-explicitos.hook

# 2. Paquete propio: se construye como el usuario normal (makepkg no corre como root).
#    Solo se reconstruye si cambió la versión del PKGBUILD o el contenido del script.
version="$(awk -F= '/^pkgver=/ {v=$2} /^pkgrel=/ {r=$2} END {print v "-" r}' "$REPO_DIR/pacman/PKGBUILD")"
# pacman -Q falla cuando el paquete no está instalado; ese caso es "versión vacía".
instalada="$(pacman -Q arenalos-procesos 2>/dev/null | awk '{print $2}' || true)"
if [ "$instalada" = "$version" ] && cmp -s "$REPO_DIR/src/procesos/procesos.py" /usr/bin/arenalos-procesos; then
    echo "arenalos-procesos $version ya instalado y al día"
else
    BUILD_DIR="$(mktemp -d /tmp/arenalos-build.XXXXXX)"
    trap 'rm -rf "$BUILD_DIR"' EXIT
    cp "$REPO_DIR/pacman/PKGBUILD" "$REPO_DIR/src/procesos/procesos.py" "$BUILD_DIR/"
    chown -R "$TARGET_USER":"$TARGET_USER" "$BUILD_DIR"
    sudo -u "$TARGET_USER" bash -c "cd '$BUILD_DIR' && makepkg -f --noconfirm"
    pacman -U --noconfirm "$BUILD_DIR"/arenalos-procesos-*.pkg.tar.zst
fi
