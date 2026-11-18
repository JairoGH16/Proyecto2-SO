#!/usr/bin/env bash
# install.sh — instala y configura ArenalOS: escritorio XFCE, temas de la Capa 2 y comandos de la Capa 3.
# Uso: sudo bash install.sh
#
# Se puede ejecutar varias veces: cada paso comprueba el estado antes de cambiarlo.
# Si un paso falla, el mensaje dice cuál fue; basta con corregir la causa y volver
# a ejecutarlo, y los pasos que ya estaban hechos no cambian nada.
set -Eeuo pipefail

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

# --- Pasos con nombre y reporte del que falla ---
PASO_ACTUAL="preparación"
KERNEL_ACTUALIZADO=0

paso() {  # paso <nombre> <función>
  PASO_ACTUAL="$1"
  echo
  echo "== Paso: $1 =="
  "$2"
}

al_fallar() {
  local codigo=$?
  trap - ERR
  echo
  echo "ERROR: falló el paso \"$PASO_ACTUAL\" (línea $1, código $codigo)."
  echo "Corrija la causa indicada arriba y vuelva a ejecutar: sudo bash $REPO_DIR/install.sh"
  echo "Los pasos que ya se completaron no se repiten ni cambian nada."
  exit "$codigo"
}
trap 'al_fallar $LINENO' ERR

# --- Comprobaciones previas: no tocan nada del sistema ---

comprobar_red() {
  # getent consulta el DNS igual que pacman; curl confirma que hay salida a internet.
  if ! getent hosts archlinux.org >/dev/null; then
    echo "ERROR: no hay red: no se puede resolver archlinux.org."
    echo "Revise la conexión de la VM (por ejemplo: nmcli general status, ping -c 3 archlinux.org) y vuelva a ejecutar."
    exit 1
  fi
  # Solo interesa si responde: la página descargada se descarta.
  if ! curl -fsS --max-time 15 -o /dev/null https://archlinux.org; then
    echo "ERROR: no hay salida a internet: archlinux.org no responde."
    echo "Revise la conexión de la VM y vuelva a ejecutar."
    exit 1
  fi
  echo "Red: OK"
}

esperar_pacman() {
  # Espera a que termine otro pacman (por ejemplo, una corrida anterior todavía activa).
  # El bloqueo solo se borra si quedó huérfano: nunca con un pacman corriendo.
  local lock=/var/lib/pacman/db.lck espera=0 limite=120
  [ -e "$lock" ] || return 0
  while pgrep -x pacman >/dev/null; do
    if [ "$espera" -ge "$limite" ]; then
      echo "ERROR: otro pacman sigue corriendo después de ${limite} s (bloqueo $lock)."
      echo "Espere a que termine o ciérrelo, y vuelva a ejecutar install.sh."
      exit 1
    fi
    if [ "$espera" -eq 0 ]; then
      echo "Otro pacman está corriendo; esperando hasta ${limite} s..."
    fi
    sleep 5
    espera=$((espera + 5))
  done
  if [ -e "$lock" ]; then
    echo "AVISO: $lock quedó huérfano (no hay ningún pacman corriendo); se elimina."
    rm -f "$lock"
  fi
}

# --- Escritorio (Fases 2 y 3) ---

paso_noextract() {
  # Evitar que pacman restaure los fondos por defecto de XFCE (debe ir antes de instalar xfce4)
  local linea='NoExtract = usr/share/backgrounds/xfce/*'
  if ! grep -qxF "$linea" /etc/pacman.conf; then
    sed -i "/^#NoExtract/a $linea" /etc/pacman.conf
  fi
}

paso_paquetes() {
  esperar_pacman
  pacman -Syu --noconfirm
  # Si pacman -Syu actualizó el kernel, el que está en ejecución ya no tiene sus
  # módulos en /usr/lib/modules: lo que necesite modprobe se completa tras reiniciar.
  if [ ! -d "/usr/lib/modules/$(uname -r)" ]; then
    KERNEL_ACTUALIZADO=1
    echo "AVISO: se actualizó el kernel (en ejecución: $(uname -r)). Los pasos que cargan"
    echo "       módulos quedan configurados y se completan al reiniciar y volver a ejecutar."
  fi
  esperar_pacman
  grep -vE '^\s*(#|$)' "$REPO_DIR/pkglist.txt" | pacman -S --needed --noconfirm -
}

paso_fondo() {
  # Dejar solo el volcán en la carpeta de fondos de XFCE
  local FONDOS=/usr/share/backgrounds/xfce
  mkdir -p "$FONDOS"
  find "$FONDOS" -mindepth 1 ! -name arenal.jpg -delete
  install -Dm644 "$REPO_DIR/dotfiles/wallpapers/arenal.jpg" "$FONDOS/arenal.jpg"
}

paso_teclado() {
  # Teclado latinoamericano para la sesión gráfica (escribe /etc/X11/xorg.conf.d/00-keyboard.conf)
  localectl set-x11-keymap latam
}

paso_xfce() {
  # Configuración de XFCE (atajos, workspaces, fondo, panel) en el home del usuario
  local ORIGEN="$REPO_DIR/dotfiles/xfce/xfconf/xfce-perchannel-xml"
  local DESTINO="$TARGET_HOME/.config/xfce4/xfconf/xfce-perchannel-xml"
  install -d -o "$TARGET_USER" -g "$TARGET_USER" "$DESTINO"
  cp -f "$ORIGEN"/*.xml "$DESTINO"/
  chown -R "$TARGET_USER:$TARGET_USER" "$TARGET_HOME/.config"
  # Carpeta compartida de VirtualBox: /media debe poder atravesarse para que el usuario normal
  # entre a /media/sf_arenalos (el grupo vboxsf no basta si /media está en 750)
  chmod 755 /media
}

paso_sddm() {
  # Pantalla de login, con XFCE en X11 como sesión por defecto (no la experimental de Wayland)
  systemctl enable sddm
  install -d /var/lib/sddm
  cat > /var/lib/sddm/state.conf <<EOF
[Last]
Session=/usr/share/xsessions/xfce.desktop
User=$TARGET_USER
EOF
  chown -R sddm:sddm /var/lib/sddm
}

# --- Temas de la Capa 2 ---

paso_temas_1_6() {  # Jairo: hook de pacman y paquete arenalos-procesos
  bash "$REPO_DIR/scripts/install-procesos-paquetes.sh"
}

paso_tema_2() {  # Rafael: swapfile + zram-generator (memoria)
  bash "$REPO_DIR/src/memoria/install.sh"
}

paso_tema_4() {  # Rafael: servicio arenalos-memlog (gestión de servicios)
  bash "$REPO_DIR/systemd/install.sh"
}

paso_temas_5_7() {  # Sebastián
  # Tema 5: compilar la herramienta de concurrencia e IPC. Se compila en /tmp porque
  # la carpeta compartida de VirtualBox no deja ejecutar. Solo se recompila si
  # cambió el código fuente o el binario no está instalado.
  if [ -f "$REPO_DIR/src/ipc/Makefile" ]; then
    local sello=/usr/local/lib/arenalos/ipc_collector.sha256 suma
    suma="$(cat "$REPO_DIR/src/ipc/Makefile" "$REPO_DIR"/src/ipc/*.c | sha256sum)"
    if [ -x /usr/local/bin/ipc_collector ] && [ -f "$sello" ] && [ "$(cat "$sello")" = "$suma" ]; then
      echo "ipc_collector ya compilado e instalado"
    else
      rm -rf /tmp/arenalos-ipc-build
      cp -r "$REPO_DIR/src/ipc" /tmp/arenalos-ipc-build
      make -C /tmp/arenalos-ipc-build
      install -Dm755 /tmp/arenalos-ipc-build/ipc_collector /usr/local/bin/ipc_collector
      rm -rf /tmp/arenalos-ipc-build
      install -d "$(dirname "$sello")"
      echo "$suma" > "$sello"
    fi
  fi

  # Tema 7: optimización del proceso de arranque
  if [ -f /boot/loader/loader.conf ]; then
    sed -i 's/^timeout 3/timeout 1/' /boot/loader/loader.conf
  fi
  systemctl mask NetworkManager-wait-online.service
}

paso_tema_8() {  # Esteban: lista negra de módulos y regla udev de las USB
  bash "$REPO_DIR/udev/install.sh"
}

paso_tema_9() {  # Esteban: usuarios, sudoers, SSH endurecido y firewall
  # La cuenta administradora es quien corre install.sh (queda en arenalos-ssh).
  ADMIN_USER="$TARGET_USER" bash "$REPO_DIR/security/install.sh"
}

# --- Capa 3 y extras ---

paso_capa_3() {  # comandos libres de cada integrante y midistro-info
  bash "$REPO_DIR/scripts/install-comandos-capa3.sh"
  bash "$REPO_DIR/scripts/install-comandos-memoria-servicios.sh"
  bash "$REPO_DIR/scripts/install-comandos-ipc-arranque.sh"
  bash "$REPO_DIR/scripts/install-comandos-seguridad-dispositivos.sh"
  bash "$REPO_DIR/scripts/install-midistro-info.sh"
}

paso_extras() {  # Jairo: aplicaciones por defecto, fondo de SDDM y reloj
  bash "$REPO_DIR/scripts/install-extras.sh"
}

# --- Ejecución ---

PASO_ACTUAL="comprobar la red"
comprobar_red
export REPO_DIR TARGET_USER TARGET_HOME

paso "1. NoExtract de los fondos de XFCE" paso_noextract
paso "2. Paquetes" paso_paquetes
paso "3. Fondo" paso_fondo
paso "4. Teclado" paso_teclado
paso "5. Configuración de XFCE" paso_xfce
paso "6-7. Pantalla de login y sesión" paso_sddm
paso "Temas 1 y 6" paso_temas_1_6
paso "Tema 2" paso_tema_2
paso "Tema 4" paso_tema_4
paso "Temas 5 y 7" paso_temas_5_7
paso "Tema 8" paso_tema_8
paso "Tema 9" paso_tema_9
paso "Capa 3" paso_capa_3
paso "Extras del escritorio" paso_extras

echo
echo "== Listo =="
if [ "$KERNEL_ACTUALIZADO" = 1 ]; then
  echo
  echo "############################################################################"
  echo "AVISO: se actualizó el kernel. Reinicie y vuelva a ejecutar"
  echo "       sudo bash install.sh para completar zram y lo demás."
  echo "############################################################################"
fi
