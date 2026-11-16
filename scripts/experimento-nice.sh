#!/usr/bin/env bash
# Experimento del Tema 1: procesos CPU-bound en el mismo nucleo con distinto nice.
# Uso: bash experimento-nice.sh SEGUNDOS NICE1 NICE2 [NICE3 ...]
# Ejemplo: bash experimento-nice.sh 30 0 10
set -euo pipefail

dur="${1:?Uso: experimento-nice.sh SEGUNDOS NICE1 NICE2 [...]}"
shift
[ "$#" -ge 2 ] || { echo "Hacen falta al menos dos valores de nice"; exit 1; }

# Pesos del kernel (sched_prio_to_weight), indice = nice + 20
PESOS=(88761 71755 56483 46273 36291 29154 23254 18705 14949 11916
       9548 7620 6100 4904 3906 3121 2501 1991 1586 1277
       1024 820 655 526 423 335 272 215 172 137
       110 87 70 56 45 36 29 23 18 15)

pids=(); nices=()
for n in "$@"; do
  taskset -c 0 nice -n "$n" sh -c 'while :; do :; done' &
  pids+=($!); nices+=("$n")
done

sleep "$dur"

ticks=(); pesos=(); total=0; peso_total=0
for i in "${!pids[@]}"; do
  t=$(sed 's/.*) //' "/proc/${pids[$i]}/stat" | awk '{print $12 + $13}')
  n="${nices[$i]}"
  w="${PESOS[$((n + 20))]}"
  ticks+=("$t"); pesos+=("$w")
  total=$((total + t)); peso_total=$((peso_total + w))
done
kill "${pids[@]}" 2>/dev/null || true
wait 2>/dev/null || true

printf '%-6s %-10s %-10s %-10s\n' NICE TICKS "%MEDIDO" "%ESPERADO"
for i in "${!pids[@]}"; do
  awk -v n="${nices[$i]}" -v t="${ticks[$i]}" -v tot="$total" \
      -v w="${pesos[$i]}" -v wt="$peso_total" \
      'BEGIN {printf "%-6s %-10s %-10.1f %-10.1f\n", n, t, 100*t/tot, 100*w/wt}'
done
