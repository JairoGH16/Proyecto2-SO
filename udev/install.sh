#!/bin/bash
# udev/install.sh — instala el Tema 8 (E/S y dispositivos) de ArenalOS
# Responsable: Esteban
#
# Idempotente: se puede ejecutar varias veces sin romper nada. Lo llama el
# install.sh principal del repositorio; también se puede ejecutar solo:
#     sudo ./udev/install.sh
#
# Los archivos se COPIAN a /etc y /usr/local (no se enlazan con ln -s) porque
# udev y modprobe los leen muy temprano en el arranque, antes de que /home
# (donde vive el repositorio) esté montado.

set -euo pipefail

[ "$(id -u)" -eq 0 ] || { echo "Ejecutar como root (sudo)"; exit 1; }

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Copia el archivo solo si cambió; devuelve 0 si hubo cambio.
put() {  # put <modo> <origen> <destino>
    if ! cmp -s "$2" "$3"; then
        install -Dm"$1" "$2" "$3"
        echo "  actualizado: $3"
        return 0
    fi
    echo "  sin cambios: $3"
    return 1
}

echo "[T8] Lista negra de módulos"
if put 644 "$DIR/arenalos-blacklist.conf" /etc/modprobe.d/arenalos-blacklist.conf; then
    # El hook "modconf" de mkinitcpio copia /etc/modprobe.d al initramfs
    mkinitcpio -P >/dev/null && echo "  initramfs regenerado"
fi

echo "[T8] Regla udev + servicio + script de la USB"
put 755 "$DIR/arenalos-usb-handler" /usr/local/lib/arenalos/arenalos-usb-handler || true
put 644 "$DIR/arenalos-usb@.service" /etc/systemd/system/arenalos-usb@.service || true
put 644 "$DIR/99-arenalos-usb.rules" /etc/udev/rules.d/99-arenalos-usb.rules || true

systemctl daemon-reload
udevadm control --reload-rules
echo "[T8] Listo"
