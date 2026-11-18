#!/bin/bash
# Imprime una fila CSV: etiqueta,boot_id,n_modulos,mem_modulos_KiB,candidatos_cargados,kernel_s,userspace_s,total_s
et="$1"
n=$(lsmod | tail -n +2 | wc -l)
mem=$(lsmod | awk 'NR>1{s+=$2} END{printf "%.1f", s/1024}')
cand=$(lsmod | grep -cE '^(pcspkr|intel_rapl|intel_pmc|pmt_|intel_vsec|vmw_vmci|vmw_vsock_vmci)')
sa=$(systemd-analyze 2>/dev/null | head -1)
k=$(echo "$sa" | grep -oP '[\d.]+(?=s \(kernel\))'); u=$(echo "$sa" | grep -oP '[\d.]+(?=s \(userspace\))'); t=$(echo "$sa" | grep -oP '= \K[\d.]+(?=s)')
echo "$et,$(cut -c1-8 /proc/sys/kernel/random/boot_id),$n,$mem,$cand,$k,$u,$t"
