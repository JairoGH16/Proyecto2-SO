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

### R-3 · Capa 3 · comandos libres `riesgo-oom` y `servicios-limites`

| Campo | Contenido |
|---|---|
| Fecha · integrante | 2026-11-17 · Rafael |
| Herramienta | Claude (Anthropic), mediante Claude Code |
| Componente | `bin/riesgo-oom`, `bin/servicios-limites`, `scripts/install-comandos-memoria-servicios.sh`, `docs/comandos-rafael.md`, `docs/logs/capa3/` |
| Propósito | Implementar y probar los dos comandos libres de la guía de Fase 5 (Temas 2 y 4), e instalarlos en la VM |
| Consulta resumida | Seguir la guía provista (`Guía Fase 5 · Rafael`), que ya traía el código completo de ambos comandos; correr el instalador dos veces y las tres pruebas de `riesgo-oom` más la prueba de `servicios-limites` con un servicio transitorio |
| Resultado obtenido | Instalador idempotente (segunda corrida sin cambios); `riesgo-oom` mostró el `oom_score_adj=200` de fábrica en los procesos de sesión y el `oom_score_adj=1000` que `stress-ng` se pone a sí mismo; `servicios-limites` mostró `nr_throttled` subiendo de 83 a 84 en un servicio transitorio limitado a 20 % de CPU, y desapareció de la lista por defecto al detenerlo |
| Validado / corregido / descartado | Sin errores de la IA en este bloque: el código de la guía (ya probado por el equipo) corrió tal cual, sin necesidad de corregir nada. Los dos hallazgos arriba (ADJ=200 por defecto, ADJ=1000 de `stress-ng`) no eran esperados por mí de antemano, pero no son errores — son comportamiento real del kernel/`stress-ng` que terminó documentado en `docs/comandos-rafael.md` |
| Cómo se validó | Ejecución real en la VM de las tres escenas de `riesgo-oom` (reposo, con `stress-ng --vm`, con `oom_score_adj=500` manual) y de `servicios-limites` antes/durante/después de un `systemd-run --unit=prueba-limites -p CPUQuota=20% -p MemoryMax=128M`; salida completa guardada en `docs/logs/capa3/` |

### R-4 · Capa 3 · atajos, prueba final y pull requests

| Campo | Contenido |
|---|---|
| Fecha · integrante | 2026-11-17 · Rafael |
| Herramienta | Claude (Anthropic), mediante Claude Code |
| Componente | `dotfiles/xfce/fragmentos/atajos-rafael.txt`, `docs/cheatsheet-rafael.md`, snapshot `Fase 5 Rafael`, PRs #2 y #3 |
| Propósito | Crear los 3 atajos (Super+Y, Super+S, Super+K) vía `xfconf-query`, verificarlos en la sesión gráfica, tomar el snapshot final y abrir los pull requests |
| Consulta resumida | Pedir los comandos `xfconf-query` exactos, verificar cada atajo con una captura, y luego abrir los PR de `rafael-fase1-t2-t4` y `rafael-fase5-capa3` hacia `main` |
| Resultado obtenido | 3 atajos funcionando (confirmado por captura: `memoria --top 15`, `servicios-limites -a`, `riesgo-oom -n 15`); snapshot `Fase 5 Rafael` creado; PR #2 y PR #3 abiertos hacia `main` |
| Validado / corregido / descartado | No hubo error de la IA propiamente dicho, pero sí dos hallazgos de proceso reales: (1) uno de los tres comandos `xfconf-query` se pegó partido en dos líneas en la terminal de la VM y falló con `Option parsing failed: Missing argument for -s` — no era un error en el comando (el mismo texto, pegado como una sola línea, funcionó); (2) la guía esperaba restaurar "el snapshot de la Fase 4", pero nunca se tomó uno — solo existía `Base Instalada`, de antes de instalar XFCE/Tema 2/Tema 4. Se decidió no restaurar nada y hacer la prueba final sobre el estado actual, ya con la idempotencia demostrada repetidas veces a lo largo de la Fase 4 |
| Cómo se validó | Captura de pantalla de cada atajo abriendo su terminal con la salida esperada; `xfconf-query -c xfce4-keyboard-shortcuts -l -v | grep -i super` confirmando las tres propiedades; `systemctl list-units 'prueba-*'` vacío antes del snapshot; `VBoxManage snapshot ... list` confirmando el snapshot creado |
