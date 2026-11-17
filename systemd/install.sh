#!/bin/bash
# systemd/install.sh — instala el Tema 4 (Gestión de servicios) de ArenalOS
# Responsable: Rafael (apoyo: Esteban)
#
# arenalos-memlog: cada 2 min (vía timer), toma 5 muestras de
# src/memoria/memoria.py (Tema 2) separadas por 1 s y las agrega a
# /var/log/arenalos-memlog.log. Limitado con CPUQuota/MemoryMax; con
# Restart=on-failure se recupera solo si se le mata a mitad de corrida.
#
# Idempotente. Uso: sudo ./systemd/install.sh

set -euo pipefail
[ "$(id -u)" -eq 0 ] || { echo "Ejecutar como root (sudo)"; exit 1; }
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(dirname "$DIR")"

echo "[T4] 1/3 Script (/usr/local/bin/arenalos-memlog)"
install -Dm755 "$DIR/arenalos-memlog.sh" /usr/local/bin/arenalos-memlog

echo "[T4] 2/3 Unit de servicio (REPO_DIR=$REPO_DIR)"
cat > /etc/systemd/system/arenalos-memlog.service <<EOF
[Unit]
Description=Snapshot periodico de memoria/swap/zram (Tema 2 -> Tema 4)
After=local-fs.target
Wants=local-fs.target

[Service]
Type=oneshot
Environment=REPO_DIR=$REPO_DIR
ExecStart=/usr/local/bin/arenalos-memlog
Restart=on-failure
RestartSec=2
CPUQuota=20%
MemoryMax=128M
EOF

echo "[T4] 3/3 Timer"
install -Dm644 "$DIR/arenalos-memlog.timer" /etc/systemd/system/arenalos-memlog.timer

systemctl daemon-reload
systemctl enable --now arenalos-memlog.timer

echo "[T4] Listo"
