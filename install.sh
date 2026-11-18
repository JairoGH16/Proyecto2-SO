#!/usr/bin/env bash
# install.sh — instala y configura ArenalOS: escritorio XFCE, temas de la Capa 2 y comandos de la Capa 3.
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

# Carpeta compartida de VirtualBox: /media debe poder atravesarse para que el usuario normal
# entre a /media/sf_arenalos (el grupo vboxsf no basta si /media está en 750)
chmod 755 /media

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

# --- Temas 1 y 6 (Jairo): hook de pacman y paquete arenalos-procesos ---
export REPO_DIR TARGET_USER TARGET_HOME
bash "$REPO_DIR/scripts/install-procesos-paquetes.sh"

# --- Tema 2 (Rafael): swapfile + zram-generator (memoria) ---
bash "$REPO_DIR/src/memoria/install.sh"

# --- Tema 4 (Rafael): servicio arenalos-memlog (gestión de servicios) ---
bash "$REPO_DIR/systemd/install.sh"

# --- Temas 5 y 7 (Sebastián) ---
# Tema 5: compilar la herramienta de concurrencia e IPC. Se compila en /tmp porque
# la carpeta compartida de VirtualBox no deja ejecutar.
if [ -f "$REPO_DIR/src/ipc/Makefile" ]; then
  rm -rf /tmp/arenalos-ipc-build
  cp -r "$REPO_DIR/src/ipc" /tmp/arenalos-ipc-build
  make -C /tmp/arenalos-ipc-build
  install -Dm755 /tmp/arenalos-ipc-build/ipc_collector /usr/local/bin/ipc_collector
  rm -rf /tmp/arenalos-ipc-build
fi

# Tema 7: optimización del proceso de arranque
if [ -f /boot/loader/loader.conf ]; then
  sed -i 's/^timeout 3/timeout 1/' /boot/loader/loader.conf
fi
systemctl mask NetworkManager-wait-online.service 2>/dev/null || true

# --- Tema 8 (Esteban): lista negra de módulos y regla udev de las USB ---
bash "$REPO_DIR/udev/install.sh"

# --- Tema 9 (Esteban): usuarios, sudoers, SSH endurecido y firewall ---
# La cuenta administradora es quien corre install.sh (queda en arenalos-ssh).
ADMIN_USER="$TARGET_USER" bash "$REPO_DIR/security/install.sh"

# --- Capa 3: comandos libres de cada integrante y midistro-info ---
bash "$REPO_DIR/scripts/install-comandos-capa3.sh"
bash "$REPO_DIR/scripts/install-comandos-memoria-servicios.sh"
bash "$REPO_DIR/scripts/install-comandos-ipc-arranque.sh"
bash "$REPO_DIR/scripts/install-comandos-seguridad-dispositivos.sh"
bash "$REPO_DIR/scripts/install-midistro-info.sh"

# --- Extras del escritorio (Jairo) ---
bash "$REPO_DIR/scripts/install-extras.sh"

echo "== Listo =="
