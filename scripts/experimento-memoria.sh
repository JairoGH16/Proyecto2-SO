#!/bin/bash
# scripts/experimento-memoria.sh — Tema 2: presión de memoria con stress-ng --vm
#
# Fuerza una carga de memoria mayor que la RAM disponible y registra:
# vmstat (si/so = páginas que entran/salen de swap), free antes/después,
# swapon --show, mm_stat de zram y cualquier evento de OOM killer en dmesg.
#
# Uso: sudo ./scripts/experimento-memoria.sh <etiqueta>
#   etiqueta: identifica la corrida en el nombre del log, p.ej. con-zram o sin-zram

set -euo pipefail
[ "$(id -u)" -eq 0 ] || { echo "Ejecutar como root (sudo)"; exit 1; }
ETIQUETA="${1:?Uso: $0 <etiqueta>  (p.ej. con-zram, sin-zram)}"

DURACION=60
WORKERS=4
BYTES_TOTAL=7G   # --vm-bytes es el TOTAL repartido entre workers, no por worker;
                 # 7G entre 4 workers queda por encima de los ~3.9G de RAM de la VM

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
LOG="$REPO_DIR/docs/logs/mediciones/experimento-memoria-$ETIQUETA.log"
mkdir -p "$(dirname "$LOG")"
VMSTAT_TMP="$(mktemp)"

{
echo "== Experimento de memoria ($ETIQUETA) == $(date)"
echo "Carga: $WORKERS workers, $BYTES_TOTAL en total, durante ${DURACION}s"
echo
echo "-- Antes --"
free -m
swapon --show
python3 "$REPO_DIR/src/memoria/memoria.py" --once
} | tee "$LOG"

vmstat 1 $((DURACION + 2)) > "$VMSTAT_TMP" &
VMSTAT_PID=$!

{
echo
echo "-- stress-ng --"
stress-ng --vm "$WORKERS" --vm-bytes "$BYTES_TOTAL" --vm-method all \
    --timeout "${DURACION}s" --metrics
} | tee -a "$LOG"

sleep 2
kill "$VMSTAT_PID" 2>/dev/null || true
wait "$VMSTAT_PID" 2>/dev/null || true

{
echo
echo "-- vmstat (1 muestra/seg, columnas si/so = swap-in/swap-out) --"
cat "$VMSTAT_TMP"
rm -f "$VMSTAT_TMP"

echo
echo "-- Después --"
free -m
swapon --show
python3 "$REPO_DIR/src/memoria/memoria.py" --once

echo
echo "-- zram mm_stat (orig_size compr_size mem_used_total mem_limit mem_used_max same_pages ...) --"
cat /sys/block/zram0/mm_stat 2>/dev/null || echo "zram0 no activo"

echo
echo "-- dmesg: eventos de OOM killer --"
dmesg | grep -iE "oom|killed process" || echo "sin eventos OOM"

echo
echo "== Fin ($ETIQUETA) =="
} | tee -a "$LOG"
