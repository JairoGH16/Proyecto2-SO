#!/bin/bash
# systemd/arenalos-memlog.sh — Tema 4: snapshot periódico de memoria/swap/zram
#
# Reusa la herramienta del Tema 2 (src/memoria/memoria.py): toma 5 muestras
# separadas por 1 s y las agrega al log. Instalado como
# /usr/local/bin/arenalos-memlog por systemd/install.sh; REPO_DIR lo define
# el unit de systemd (Environment=), no este script.

set -euo pipefail
: "${REPO_DIR:?REPO_DIR no está definido (lo pone el unit de systemd)}"
LOG=/var/log/arenalos-memlog.log

for i in 1 2 3 4 5; do
    python3 "$REPO_DIR/src/memoria/memoria.py" --once >> "$LOG"
    echo >> "$LOG"
    sleep 1
done
