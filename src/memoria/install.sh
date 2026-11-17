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

echo "[T2] 1/3 Swapfile ($SWAPSIZE_MB MiB)"
if [ ! -f "$SWAPFILE" ]; then
    fallocate -l "${SWAPSIZE_MB}M" "$SWAPFILE"
    chmod 600 "$SWAPFILE"
    mkswap "$SWAPFILE" >/dev/null
    echo "  creado"
else
    echo "  ya existe"
fi
if ! grep -q "^$SWAPFILE " /etc/fstab; then
    echo "$SWAPFILE none swap defaults,pri=10 0 0" >> /etc/fstab
    echo "  agregado a fstab (pri=10)"
else
    echo "  ya está en fstab"
fi
swapon -p 10 "$SWAPFILE" 2>/dev/null || echo "  ya estaba activo (prioridad se fija al reiniciar, vía fstab)"

echo "[T2] 2/3 zram-generator"
pacman -S --needed --noconfirm zram-generator >/dev/null
if ! cmp -s "$DIR/zram-generator.conf" /etc/systemd/zram-generator.conf 2>/dev/null; then
    install -Dm644 "$DIR/zram-generator.conf" /etc/systemd/zram-generator.conf
    echo "  configuración actualizada"
else
    echo "  sin cambios"
fi
systemctl daemon-reload
# systemctl acepta "/dev/zram0" como alias del .device y lo da por éxito
# sin tocar el swap; hay que reiniciar el servicio de zram-generator por nombre.
systemctl restart systemd-zram-setup@zram0.service

echo "[T2] 3/3 Verificación"
swapon --show
echo "[T2] Listo"
