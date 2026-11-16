# Bitácora de uso de IA

Formato del Anexo 3 del enunciado: una entrada por consulta relevante. Cada integrante registra las de los temas de los que es responsable principal.

---

## Esteban

### E-1 · Tema 8 · E/S y dispositivos

| Campo | Contenido |
|---|---|
| Fecha · integrante | 2026-11-10 · Esteban |
| Herramienta | Claude (Anthropic), mediante Claude Code |
| Componente | Tema 8: lista negra de módulos, regla udev, `/proc/interrupts`, GPU/NPU (`udev/`, `docs/tema-08-es-dispositivos.md`) |
| Propósito | Elegir módulos para la lista negra con justificación real, diseñar la regla udev y el experimento de interrupciones, y redactar la ficha |
| Consulta resumida | "Implementa el Tema 8 en mi VM: lista negra justificada, regla udev para mi USB, medición de /proc/interrupts y driver de la GPU, con evidencia medida" |
| Resultado obtenido | Lista negra de 4 grupos de módulos sin hardware en VirtualBox (`pcspkr`, RAPL, PMC, VMCI de VMware); regla udev + servicio plantilla systemd que registra la USB y la monta en solo lectura; scripts de medición (3 arranques por condición y 5 repeticiones por operación de E/S); ficha con resultados |
| Validado / corregido / descartado | **Error de la IA (corregido):** la primera versión de la lista negra usó `blacklist vmw_vmci` + `install vmw_vsock_vmci_transport /bin/false`, suponiendo que eso bastaba. Tras reiniciar, `vmw_vmci` seguía cargado. Con `modprobe -n -v net-pf-40` se vio que modprobe carga **primero las dependencias** y después ejecuta el `install`, y que `blacklist` no aplica a dependencias. Se agregó `install vmw_vmci /bin/false`. **Error de cálculo (corregido):** en la ficha, la IA escribió que con bloques de 1 MiB había "64 veces menos" interrupciones por MiB; recalculado con los datos da unas 190 veces (256.5 contra 1.35). **Corregido:** el script de interrupciones usaba `bc`, que no está instalado en la VM; se reemplazó por `awk` y los tiempos se tomaron de la salida de `dd`. **Descartado:** `i2c_piix4` como candidato, porque en esta VM no genera el error de SMBus que suele justificarlo |
| Cómo se validó | `lsmod` (conteo y memoria) en 3 arranques antes y 3 después; `ls /sys/class/powercap`, `lspci -nn` (ausencia de `15ad:0740`) y `modprobe -n -v` (simulación); `udevadm verify` y `systemd-analyze verify`; conexión real de la USB con `udevadm monitor`, `dmesg -w`, `udevadm test`, `findmnt` y prueba negativa (`touch` → *Read-only file system*); `/sys/block/*/queue/max_sectors_kb` para comprobar el cálculo de 3 IRQ por comando USB. Documentación: `modprobe.d(5)`, `udev(7)`, `systemd.device(5)`, Arch Wiki *Kernel module* y *udev* |

### E-2 · Tema 9 · Protección y seguridad

| Campo | Contenido |
|---|---|
| Fecha · integrante | 2026-11-11 · Esteban |
| Herramienta | Claude (Anthropic), mediante Claude Code |
| Componente | Tema 9: usuarios/grupos, ACL, sudoers, SSH, nftables, nmap (`security/`, `docs/tema-09-seguridad.md`) |
| Propósito | Diseñar las cuentas con privilegio mínimo, las reglas de sudo, SSH y firewall, y las pruebas negativas y de escaneo |
| Consulta resumida | "Implementa el Tema 9 en mi VM sin depender del equipo: privilegio mínimo, sudo por comando, ACL, SSH solo con llaves, firewall drop por defecto y escaneo nmap desde otra VM" |
| Resultado obtenido | 4 cuentas con roles distintos y directorio compartido con setgid y ACL; sudoers con 3 comandos exactos y `NOEXEC`; drop-in de sshd; `nftables.conf` con `policy drop`; instalador que valida cada archivo; una segunda VM sin disco (live de Arch con nmap) en una red interna aislada; 6 escaneos (3 sin firewall, 3 con firewall) |
| Validado / corregido / descartado | **Error de la IA (corregido):** la primera versión de las pruebas de sudo mostraba `exit=0` en todos los casos, porque el código de salida se tomaba mal dentro de una tubería, y usaba "a password is required" como prueba de rechazo, que es indirecta. Se rehízo con `sudo -n -l <comando>` (código 1 = no permitido) y `sudo -l -U <cuenta>`. **Suposición incorrecta (corregida):** la IA supuso que `nftables.service` quedaría `active` después de cargar las reglas; en Arch es `oneshot` sin `RemainAfterExit` y queda `inactive` con el firewall funcionando. Se verificó con `nft list ruleset` y se agregó un drop-in (`RemainAfterExit`, `ExecReload`, `ExecStop`). **Error de la IA (corregido):** `puertos-abiertos` usaba `sort -u` por puerto, que habría ocultado la línea IPv6 cuando el mismo puerto escucha en IPv4 e IPv6. **Descartado:** permitir `journalctl` en sudoers, porque su *pager* permite escapar a una shell de root |
| Cómo se validó | `visudo -cf`, `sshd -t` y `nft -c -f` antes de aplicar; timer de rescate (`systemd-run --on-active=120 nft flush ruleset`) mientras se probaba el firewall; pruebas reales con `runuser -u <cuenta>`; inicios de SSH desde otra máquina (host) con `user`, `root`, `operador` y contraseña, contrastados con `journalctl -u sshd`; `nmap` desde la VM escáner con un servicio de prueba en el 8080; contadores de `nft list ruleset` contrastados con el cálculo 3 × 1024 × 2 = 6144. Documentación: `sudoers(5)`, `sshd_config(5)`, `acl(5)`, `nft(8)`, Arch Wiki *nftables*, *OpenSSH*, *Sudo*, *Access Control Lists*; GTFOBins (escapes por pager) |

### E-3 · Capa 3 · comandos libres `usb-historial` y `puertos-abiertos`

| Campo | Contenido |
|---|---|
| Fecha · integrante | 2026-11-11 · Esteban |
| Herramienta | Claude (Anthropic), mediante Claude Code |
| Componente | Capa 3: `bin/usb-historial`, `bin/puertos-abiertos`, `docs/comandos.md` |
| Propósito | Proponer dos comandos útiles ligados a T8 y T9 que lean interfaces del SO, e implementarlos |
| Consulta resumida | "Haz mis 2 comandos libres: uno de dispositivos y uno de seguridad, leyendo /proc y /sys" |
| Resultado obtenido | `usb-historial` (lee `/sys/bus/usb/devices`, `/sys/block`, `/proc/mounts` y el log de la regla udev) y `puertos-abiertos` (lee `/proc/net/*`, cruza inodos con `/proc/<pid>/fd` y compara con las reglas de nftables) |
| Validado / corregido / descartado | Corregido el `sort -u` de `puertos-abiertos` (ver E-2). Se comprobó la conversión de direcciones hexadecimales de `/proc/net/tcp` comparando la salida con `ss -tlnp` |
| Cómo se validó | Ejecución en la VM con la USB conectada y desconectada; `puertos-abiertos` con firewall activo, sin firewall (`systemctl stop nftables`) y sin root; comparación con `ss -tlnp`, `lsusb -t` y `findmnt`; `bash -n` para la sintaxis. Documentación: `proc(5)` (formato de `/proc/net/tcp`), documentación de sysfs USB del kernel |

### E-4 · Pendientes del equipo después de las fases 1 a 3

| Campo | Contenido |
|---|---|
| Fecha · integrante | 2026-11-15 · Esteban |
| Herramienta | Claude Code (Claude Opus 5.5) |
| Componente | Coordinación de las fases 3 y 4; Tema 9 (`pkglist.txt`) |
| Propósito | Entender qué faltaba por hacer sin duplicar trabajo de los compañeros |
| Consulta resumida | "¿Qué queda pendiente?", con las guías de las fases 1 a 3, el enunciado y la respuesta del equipo sobre el DE (XFCE 4.20, X11, SDDM) |
| Resultado obtenido | Una lista de pendientes. Entre ellos: "`pkglist.txt` está vacío y faltan los paquetes del escritorio (`xfce4`, `sddm`, `xorg-server`)" |
| Validado / corregido / descartado | **Error de la IA (descartado).** La IA revisó la rama local `esteban-fase1-t8-t9` sin traer antes los cambios del remoto. Esa rama salió de `main` antes de que Jairo subiera la Fase 3, así que el archivo vacío era una copia vieja. En `origin/main` el archivo ya tenía la base y el escritorio |
| Cómo se validó | `git fetch --all` y `git show origin/main:pkglist.txt`. Lección: antes de opinar sobre el estado del repositorio hay que actualizar las referencias remotas |

### E-5 · ¿XFCE monta las USB en lectura y escritura? (riesgo para la regla udev del Tema 8)

| Campo | Contenido |
|---|---|
| Fecha · integrante | 2026-11-15 · Esteban |
| Herramienta | Claude Code (Claude Opus 5.5) |
| Componente | Tema 8 · E/S y dispositivos |
| Propósito | Saber si el escritorio elegido afecta la regla udev que monta las USB en solo lectura |
| Consulta resumida | Qué impacto tiene XFCE 4.20 sobre lo ya implementado en los temas 8 y 9 |
| Resultado obtenido | La IA afirmó que XFCE "suele instalarse con `thunar-volman`, `gvfs` y `udisks2`" y que esos paquetes montan las USB en lectura y escritura, lo que pasaría por encima del montaje `ro,nosuid,nodev,noexec` de `udev/arenalos-usb-handler` |
| Validado / corregido / descartado | **Imprecisión de la IA (corregida).** `thunar-volman` sí entra con el grupo `xfce4`, pero `gvfs` (y con él `udisks2`) aparece **solo como dependencia opcional** de Thunar y no se instala. Sin `gvfs` no hay automontaje, así que la regla del Tema 8 no se ve afectada. Queda como verificación recomendada conectar una USB una vez en la sesión gráfica |
| Cómo se validó | `git show origin/main:docs/logs/install-arenalos-sebastian.log \| grep -iE "gvfs\|udisks"`: solo aparece la línea `gvfs: trash support, mounting with udisk and remote filesystems` dentro de las dependencias opcionales |

### E-6 · Paquetes que necesita el Tema 9 en una instalación limpia

| Campo | Contenido |
|---|---|
| Fecha · integrante | 2026-11-15 · Esteban |
| Herramienta | Claude Code (Claude Opus 5.5) |
| Componente | Tema 9 · Protección y seguridad |
| Propósito | Comprobar que `security/install.sh` funciona desde la instalación base de la Fase 3 y no solo en la VM donde se desarrolló |
| Consulta resumida | Si los programas que usa `security/install.sh` (`sshd`, `nft`) quedan instalados con el `pkglist.txt` del equipo |
| Resultado obtenido | `openssh` y `nftables` no están en el `pacstrap` de la Fase 1 ni en `pkglist.txt`; hay que agregarlos en una sección propia de los temas 8 y 9 |
| Validado / corregido / descartado | **Aceptado.** Se agregaron a `pkglist.txt` bajo `# --- Temas 8 y 9 ---` (commit `f1ca3bb`) |
| Cómo se validó | En el log de instalación de Sebastián, `openssh` aparece solo como opcional (`openssh: ssh transport and crypto`) y `nftables` no aparece. Se comparó con la lista del `pacstrap` de la guía de la Fase 1 |

### E-7 · Fase 3: prueba del bootstrap en la VM de Esteban

| Campo | Contenido |
|---|---|
| Fecha · integrante | 2026-11-15 · Esteban |
| Herramienta | Claude Code (Claude Opus 5.5) |
| Componente | Capa 1 · reproducibilidad (`install.sh` y `pkglist.txt` de `main`, log `docs/logs/install-arenalos-esteban.log`) |
| Propósito | Seguir la guía de la Fase 3 desde la parte 3D en la VM propia y comprobar el resultado sin depender solo de lo que se ve en pantalla |
| Consulta resumida | "Haz la Fase 3 en mi VM desde la parte 3D" |
| Resultado obtenido | La IA guardó el estado de T8/T9 en el snapshot `antes-fase3`, restauró `base instalada`, instaló las Guest Additions, configuró la carpeta compartida (apuntando a una copia de `main`, no a la rama con cambios de T8/T9), tomó `pre-instalador`, ejecutó `install.sh` dos veces y tomó `bootstrap` |
| Validado / corregido / descartado | **Error de la IA (corregido):** la IA intentó verificar los atajos con capturas de pantalla de VirtualBox. Con la aceleración 3D activa (requisito del paso 5) las capturas no muestran las ventanas, así que parecía que `Super+Enter` no abría nada bien. Se cambió el método: el estado real se leyó dentro de la VM con `xprop` (`_NET_CLIENT_LIST`, `_NET_CURRENT_DESKTOP`). **Error de la IA (corregido):** para comprobar `Super+Q` revisó si el proceso `xfce4-appfinder` seguía vivo, pero ese programa queda corriendo en segundo plano aunque se cierre su ventana; la prueba correcta es que su ventana desaparezca de `_NET_CLIENT_LIST`. **Corregido:** en la sesión gráfica (`latam`) el texto enviado con el mapeo US cambiaba `/` y `_`; se usó `setxkbmap us` solo para escribir el comando y luego `setxkbmap latam` |
| Cómo se validó | Primera ejecución termina en `== Listo ==`; tras reiniciar aparece SDDM con `Xfce Session`; `ls /usr/share/backgrounds/xfce` → `arenal.jpg`; `localectl status` → `X11 Layout: latam`; `Super+D` abre el launcher, `Super+Q` cierra la ventana activa, `Super+3`/`Super+9` cambian a los escritorios 3 y 9 de 9 (`xprop`); segunda ejecución `there is nothing to do`; `grep -c NoExtract` → `1`; `systemctl is-enabled sddm` → `enabled`; tras cerrar y abrir sesión el fondo y los atajos siguen igual |
