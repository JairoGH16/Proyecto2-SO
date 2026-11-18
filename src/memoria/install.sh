#!/bin/bash
# src/memoria/install.sh — instala el Tema 2 (Memoria) de ArenalOS
# Responsable: Rafael (apoyo: Jairo)
#
# Idempotente. Crea el swapfile y activa zram-generator con prioridad
# distinta para que el kernel prefiera zram (comprimido, en RAM) antes
# de tocar el swapfile en disco:
#   zram0 (swap-priority=100) > swapfile (pri=10 en fstab)
#
# Uso: sudo ./src/memoria/install.sh

set -euo pipefail
[ "$(id -u)" -eq 0 ] || { echo "Ejecutar como root (sudo)"; exit 1; }
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

SWAPFILE=/swapfile
SWAPSIZE_MB=4096
ZRAM_PRIO=100
SWAPFILE_PRIO=10

# Prioridad con la que está activo un swap, o vacío si no está activo.
prioridad_swap() {
    swapon --show=NAME,PRIO --noheadings --raw | awk -v n="$1" '$1 == n { print $2 }'
}

# Si se actualizó el kernel durante esta corrida, el que está en ejecución ya no
# tiene sus módulos en disco y modprobe no puede cargar zram hasta reiniciar.
modulos_disponibles() {
    [ -d "/usr/lib/modules/$(uname -r)" ]
}

echo "[T2] 1/3 Swapfile ($SWAPSIZE_MB MiB)"
if [ ! -f "$SWAPFILE" ]; then
    fallocate -l "${SWAPSIZE_MB}M" "$SWAPFILE"
    chmod 600 "$SWAPFILE"
    mkswap "$SWAPFILE" >/dev/null   # solo se oculta el resumen; los errores salen por stderr
    echo "  creado"
elif ! swaplabel "$SWAPFILE" >/dev/null 2>&1; then
    # Quedó creado pero sin firma de swap (corrida interrumpida entre fallocate y mkswap).
    # swaplabel devuelve error justamente cuando no hay firma, por eso se descarta su salida.
    chmod 600 "$SWAPFILE"
    mkswap "$SWAPFILE" >/dev/null
    echo "  existía sin formato de swap: formateado"
else
    echo "  ya existe"
fi
if ! grep -q "^$SWAPFILE " /etc/fstab; then
    echo "$SWAPFILE none swap defaults,pri=$SWAPFILE_PRIO 0 0" >> /etc/fstab
    echo "  agregado a fstab (pri=$SWAPFILE_PRIO)"
else
    echo "  ya está en fstab"
fi
prio="$(prioridad_swap "$SWAPFILE")"
if [ -z "$prio" ]; then
    swapon -p "$SWAPFILE_PRIO" "$SWAPFILE"
    echo "  activado (pri=$SWAPFILE_PRIO)"
elif [ "$prio" != "$SWAPFILE_PRIO" ]; then
    swapoff "$SWAPFILE"
    swapon -p "$SWAPFILE_PRIO" "$SWAPFILE"
    echo "  reactivado con pri=$SWAPFILE_PRIO (tenía $prio)"
else
    echo "  ya estaba activo (pri=$SWAPFILE_PRIO)"
fi

echo "[T2] 2/3 zram-generator"
pacman -S --needed --noconfirm zram-generator >/dev/null   # el paquete ya viene en pkglist.txt
conf_cambiada=0
if ! cmp -s "$DIR/zram-generator.conf" /etc/systemd/zram-generator.conf; then
    install -Dm644 "$DIR/zram-generator.conf" /etc/systemd/zram-generator.conf
    conf_cambiada=1
    echo "  configuración actualizada"
else
    echo "  configuración sin cambios"
fi
# El módulo zram se carga en cada arranque (sin esto, en una instalación limpia
# systemd-zram-setup@zram0 falla porque /dev/zram0 no existe).
if [ ! -f /etc/modules-load.d/zram.conf ] || [ "$(cat /etc/modules-load.d/zram.conf)" != zram ]; then
    install -d /etc/modules-load.d
    echo zram > /etc/modules-load.d/zram.conf
    echo "  /etc/modules-load.d/zram.conf creado"
fi
systemctl daemon-reload

zram_omitido=0
if [ "$(prioridad_swap /dev/zram0)" = "$ZRAM_PRIO" ] && [ "$conf_cambiada" = 0 ]; then
    echo "  zram0 ya activo con la configuración actual"
elif ! modulos_disponibles; then
    zram_omitido=1
    echo "  AVISO: el kernel en ejecución ($(uname -r)) se actualizó y sus módulos ya no están;"
    echo "         zram queda configurado y se activará al reiniciar y volver a ejecutar install.sh"
else
    modprobe zram
    # Dejar zram0 limpio: si quedó a medias (con disksize ya asignado por un intento
    # anterior), el kernel no deja cambiar el algoritmo de compresión (EBUSY).
    if [ -n "$(prioridad_swap /dev/zram0)" ]; then
        swapoff /dev/zram0
    fi
    if [ -e /sys/block/zram0/reset ]; then
        echo 1 > /sys/block/zram0/reset
    fi
    # systemctl acepta "/dev/zram0" como alias del .device y lo da por éxito
    # sin tocar el swap; hay que reiniciar el servicio de zram-generator por nombre.
    systemctl restart systemd-zram-setup@zram0.service
    echo "  zram0 configurado"
fi

echo "[T2] 3/3 Verificación"
swapon --show
error=0
if [ "$(prioridad_swap "$SWAPFILE")" != "$SWAPFILE_PRIO" ]; then
    echo "  ERROR: $SWAPFILE no está activo con prioridad $SWAPFILE_PRIO" >&2
    error=1
fi
if [ "$zram_omitido" = 0 ] && [ "$(prioridad_swap /dev/zram0)" != "$ZRAM_PRIO" ]; then
    echo "  ERROR: /dev/zram0 no está activo como swap con prioridad $ZRAM_PRIO." >&2
    echo "         Revise: systemctl status systemd-zram-setup@zram0.service" >&2
    error=1
fi
[ "$error" = 0 ] || exit 1
echo "[T2] Listo"
