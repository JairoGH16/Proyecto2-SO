# Bitácora de uso de IA

Formato del Anexo 3 del enunciado: una entrada por consulta relevante. Cada integrante registra las de los temas de los que es responsable principal.

---

## Rafael

### R-1 · Fase 1 · Instalación manual

| Campo | Contenido |
|---|---|
| Fecha · integrante | 2026-11-17 · Rafael |
| Herramienta | Claude (Anthropic), mediante Claude Code |
| Componente | Instalación manual de Arch en `ArenalOS-Rafael` (VirtualBox, UEFI, 40 GB); `docs/logs/rafael/`, `docs/logs/install-arenalos-rafael.log` |
| Propósito | Crear la VM, instalar Arch a mano siguiendo `docs/instalacion.md`, y correr `install.sh` dos veces para confirmar idempotencia (Fase 3) |
| Consulta resumida | "Dame el paso a paso de la Fase 1 con un disco de 40 GB" y, durante la instalación, ayuda en vivo con los errores de consola |
| Resultado obtenido | VM creada por `VBoxManage` (disco 40 GB en vez de los 20 GB de Jairo); instalación completa con systemd-boot; evidencia (`lsblk -f`, `fstab`, `bootctl status`, `journalctl --list-boots`); `install.sh` corrido dos veces sin diferencias en la segunda corrida |
| Validado / corregido / descartado | **Error del usuario detectado por la IA (corregido):** al cargar `loadkeys la-latin1` con un teclado físico US, los comandos empezaron a escribirse mal (`timedatectlñ`, `ping 'c 3`); se volvió a `KEYMAP=us` en `/etc/vconsole.conf` y `localectl set-x11-keymap us` para la sesión gráfica. **Problema de instalación detectado (corregido):** tras `arch-chroot`, `/boot` estaba vacío porque `pacstrap` no había instalado `linux-lts`, `sudo`, `networkmanager` ni `nano` (coincide con la ventana en que el teclado aún estaba mal mapeado); se reinstalaron con `pacman -S` dentro del chroot y el initramfs se generó automáticamente como parte de ese post-transaction hook |
| Cómo se validó | `ls /boot` (antes vacío, después con `vmlinuz-linux-lts` e `initramfs-linux-lts.img`); `pacman -Ql linux-lts` para confirmar que el paquete sí quedó instalado; `bootctl status` tras el primer arranque mostrando la entrada `arenalos-lts.conf` con el UUID correcto de `/dev/sda3` |

### R-2 · Tema 2 · Memoria

| Campo | Contenido |
|---|---|
| Fecha · integrante | 2026-11-17 · Rafael |
| Herramienta | Claude (Anthropic), mediante Claude Code |
| Componente | Tema 2: swapfile + zram, monitor en tiempo real y experimento de presión (`src/memoria/`, `scripts/experimento-memoria.sh`, `docs/tema-02-memoria.md`) |
| Propósito | Configurar swap con prioridades justificadas, escribir la herramienta de monitoreo y diseñar/correr el experimento con y sin zram |
| Consulta resumida | "Implementa el Tema 2 en mi VM: swapfile + zram con prioridades, un monitor en tiempo real y el experimento de stress-ng, con evidencia medida" |
| Resultado obtenido | `/swapfile` (4 GiB, prioridad 10) + `zram0` (ram/2, zstd, prioridad 100) vía `src/memoria/install.sh`; `memoria.py` (memoria física, swap por dispositivo, ratio de compresión de zram, fallos de página por proceso); dos corridas de `stress-ng --vm` (con y sin zram) con `vmstat`, `free`, `swapon --show` y `dmesg` antes/después |
| Validado / corregido / descartado | **Error de la IA (corregido):** el instalador usaba `systemctl start /dev/zram0 \|\| systemctl restart systemd-zram-setup@zram0.service` esperando que la primera orden fallara y disparara la segunda. `systemctl` acepta rutas de dispositivo y las resuelve a su unidad `.device`, que ya existía, así que la primera orden "tenía éxito" sin tocar el swap y la segunda nunca se ejecutaba; `swapon --show` seguía sin listar zram después de correr `install.sh`. Se corrigió llamando directamente a `systemctl restart systemd-zram-setup@zram0.service`. **Error de la IA (corregido):** el primer script del experimento pasaba `--vm-bytes 1536M` con `--vm 4` creyendo que era por worker; la propia ayuda de `stress-ng` dice que `--vm-bytes` es el total repartido entre workers, así que la carga real fue de solo 1,5 GB (muy por debajo de la RAM) y no se generó presión real (`swapon --show` en 0 B antes y después). Se corrigió a `--vm-bytes 7G` como total, lo que sí forzó swap real y una diferencia medible entre las corridas con y sin zram |
| Cómo se validó | `swapon --show` y `systemctl status systemd-zram-setup@zram0.service` / `dev-zram0.swap` tras cada cambio, antes y después de cada corrida; `journalctl -u systemd-zram-setup@zram0.service` para confirmar el formateo real de `/dev/zram0`; comparación directa de los dos logs del experimento (`docs/logs/mediciones/experimento-memoria-{con,sin}-zram.log`): con zram, `stress-ng` completó 7168 bogo-ops; sin zram, el propio `stress-ng` reportó 0 bogo-ops y una advertencia de datos no confiables, evidencia de que la primera corrida corregida sí estaba generando presión real |
