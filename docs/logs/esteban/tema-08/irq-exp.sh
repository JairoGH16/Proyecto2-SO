#!/bin/bash
# Experimento /proc/interrupts: delta de IRQ 20 (xhci USB3) e IRQ 21 (ahci SATA) por operacion
irq() { awk -v n="$1:" '$1==n{s=0; for(i=2;i<=NF;i++) if($i ~ /^[0-9]+$/) s+=$i; else break; print s}' /proc/interrupts; }
run() { # run <etiqueta> <rep> <comando>
  local et=$1 rep=$2; shift 2
  sync; echo 3 > /proc/sys/vm/drop_caches
  local a20=$(irq 20) a21=$(irq 21) t0=$(date +%s.%N)
  out=$(eval "$@" 2>&1 | tail -1)
  local t1=$(date +%s.%N) b20=$(irq 20) b21=$(irq 21)
  printf '%s,%d,%d,%d,%.2f,"%s"\n' "$et" "$rep" $((b20-a20)) $((b21-a21)) "$(awk -v a=$t0 -v b=$t1 'BEGIN{print b-a}')" "$out"
}
echo "operacion,rep,delta_irq20_xhci,delta_irq21_ahci,segundos,salida_dd"
for r in 1 2 3 4 5; do
  run reposo_5s $r "sleep 5"
  run sata_escritura_256MiB_bs1M $r "dd if=/dev/zero of=/root/t8-io.img bs=1M count=256 oflag=direct"
  run sata_escritura_64MiB_bs4k $r "dd if=/dev/zero of=/root/t8-io.img bs=4k count=16384 oflag=direct"
  run usb_lectura_256MiB_bs1M $r "dd if=/dev/sdb of=/dev/null bs=1M count=256 skip=$(( (r-1)*256 )) iflag=direct"
  run usb_lectura_32MiB_bs4k $r "dd if=/dev/sdb of=/dev/null bs=4k count=8192 skip=$(( (r-1)*8192 + 400000 )) iflag=direct"
done
rm -f /root/t8-io.img
