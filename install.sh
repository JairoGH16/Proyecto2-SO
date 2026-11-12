#!/usr/bin/env bash
# install.sh — instala y configura ArenalOS (Fase 2: escritorio XFCE).
# Uso: sudo bash install.sh
set -euo pipefail

if [ "$EUID" -ne 0 ] || [ -z "${SUDO_USER:-}" ]; then
  echo "Ejecute desde su usuario con: sudo bash install.sh"
  exit 1
fi

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TARGET_USER="$SUDO_USER"
TARGET_HOME="$(getent passwd "$TARGET_USER" | cut -d: -f6)"

LOG_DIR="$REPO_DIR/docs/logs"
mkdir -p "$LOG_DIR"
exec > >(tee -a "$LOG_DIR/install-$HOSTNAME.log") 2>&1

echo "== ArenalOS install: $(date) en $HOSTNAME =="

# 1. Evitar que pacman restaure los fondos por defecto de XFCE (debe ir antes de instalar xfce4)
linea='NoExtract = usr/share/backgrounds/xfce/*'
if ! grep -qxF "$linea" /etc/pacman.conf; then
  sed -i "/^#NoExtract/a $linea" /etc/pacman.conf
fi

# 2. Paquetes
pacman -Syu --noconfirm
grep -vE '^\s*(#|$)' "$REPO_DIR/pkglist.txt" | pacman -S --needed --noconfirm -

# 3. Fondo: dejar solo el volcan en la carpeta de fondos de XFCE
FONDOS=/usr/share/backgrounds/xfce
mkdir -p "$FONDOS"
find "$FONDOS" -mindepth 1 ! -name arenal.jpg -delete
install -Dm644 "$REPO_DIR/dotfiles/wallpapers/arenal.jpg" "$FONDOS/arenal.jpg"

# 4. Teclado latinoamericano para la sesión gráfica (escribe /etc/X11/xorg.conf.d/00-keyboard.conf)
localectl set-x11-keymap latam

# 5. Configuración de XFCE (atajos, workspaces, fondo) en el home del usuario
ORIGEN="$REPO_DIR/dotfiles/xfce/xfconf/xfce-perchannel-xml"
DESTINO="$TARGET_HOME/.config/xfce4/xfconf/xfce-perchannel-xml"
install -d -o "$TARGET_USER" -g "$TARGET_USER" "$DESTINO"
cp -f "$ORIGEN"/*.xml "$DESTINO"/
chown -R "$TARGET_USER:$TARGET_USER" "$TARGET_HOME/.config"

# 6. Pantalla de login
systemctl enable sddm

# 7. Sesión por defecto de SDDM: XFCE en X11 (no la experimental de Wayland)
install -d /var/lib/sddm
cat > /var/lib/sddm/state.conf <<EOF
[Last]
Session=/usr/share/xsessions/xfce.desktop
User=$TARGET_USER
EOF
chown -R sddm:sddm /var/lib/sddm

echo "== Listo =="
