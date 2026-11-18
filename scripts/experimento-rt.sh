#!/usr/bin/env bash
# Experimento del Tema 1: un proceso normal (nice 0) contra uno de tiempo real (SCHED_FIFO)
# en el mismo nucleo. Uso: sudo bash experimento-rt.sh SEGUNDOS [PRIORIDAD_RT]
# Ejemplo: sudo bash experimento-rt.sh 10 10
set -euo pipefail

dur="${1:?Uso: sudo bash experimento-rt.sh SEGUNDOS [PRIORIDAD_RT]}"
prio="${2:-10}"

[ "$EUID" -eq 0 ] || { echo "Hace falta root para SCHED_FIFO: use sudo bash experimento-rt.sh ..."; exit 1; }

# Mata los procesos del experimento aunque el script falle o se interrumpa a medias.
normal=""; rt=""
limpiar() {
  kill $normal $rt 2>/dev/null || true
  wait 2>/dev/null || true
}
trap limpiar EXIT
trap 'exit 130' INT TERM

taskset -c 0 sh -c 'while :; do :; done' &
normal=$!
taskset -c 0 chrt -f "$prio" sh -c 'while :; do :; done' &
rt=$!

sleep "$dur"

t_normal=$(sed 's/.*) //' "/proc/$normal/stat" | awk '{print $12 + $13}')
t_rt=$(sed 's/.*) //' "/proc/$rt/stat" | awk '{print $12 + $13}')
pol_rt=$(sed 's/.*) //' "/proc/$rt/stat" | awk '{print $39}')
kill "$normal" "$rt" 2>/dev/null || true
wait 2>/dev/null || true

echo "Politica del proceso RT (campo 41 de stat; 1 = FIFO): $pol_rt"
awk -v a="$t_normal" -v b="$t_rt" 'BEGIN {
  t = a + b
  printf "%-18s %-8s %-8s\n", "PROCESO", "TICKS", "%CPU"
  printf "%-18s %-8d %-8.1f\n", "normal (nice 0)", a, 100*a/t
  printf "%-18s %-8d %-8.1f\n", "tiempo real (FIFO)", b, 100*b/t
}'
cat /proc/sys/kernel/sched_rt_runtime_us /proc/sys/kernel/sched_rt_period_us | paste -sd' ' | awk '{printf "sched_rt_runtime_us=%s sched_rt_period_us=%s\n", $1, $2}'
