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
BLACKLIST=/etc/modprobe.d/arenalos-blacklist.conf
put 644 "$DIR/arenalos-blacklist.conf" "$BLACKLIST" || true   # put devuelve 1 si no hubo cambios
# El hook "modconf" de mkinitcpio copia /etc/modprobe.d al initramfs. Se regenera
# solo si la lista negra es más nueva que algún initramfs: cubre el caso en que
# cambió y también el de una corrida anterior interrumpida antes de regenerarlo.
regenerar=0
for img in /boot/initramfs-*.img; do
    if [ ! -e "$img" ] || [ "$BLACKLIST" -nt "$img" ]; then
        regenerar=1
    fi
done
if [ "$regenerar" = 1 ]; then
    mkinitcpio -P >/dev/null   # oculta el detalle de la construcción; los errores van a stderr
    echo "  initramfs regenerado"
else
    echo "  initramfs al día"
fi

echo "[T8] Regla udev + servicio + script de la USB"
put 755 "$DIR/arenalos-usb-handler" /usr/local/lib/arenalos/arenalos-usb-handler || true
put 644 "$DIR/arenalos-usb@.service" /etc/systemd/system/arenalos-usb@.service || true
put 644 "$DIR/99-arenalos-usb.rules" /etc/udev/rules.d/99-arenalos-usb.rules || true

systemctl daemon-reload
udevadm control --reload-rules
echo "[T8] Listo"
