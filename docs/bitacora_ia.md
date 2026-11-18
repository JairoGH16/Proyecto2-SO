## Sebastián

### S-1 Resolución de error de compilación POSIX (`usleep` vs `nanosleep`) en módulo IPC (Tema 5)

| Campo | Contenido |
| :--- | :--- |
| Fecha - integrante | 11/11/2026 - Sebastián |
| Herramienta | Gemini con Hydrogen |
| Componente | `src/ipc/ipc_collector.c`, `src/ipc/Makefile` |
| Propósito | Resolver advertencia/error de declaración implícita de `usleep()` al compilar con el estándar estricto `-std=c11 -D_POSIX_C_SOURCE=200809L` y diseñar el esquema productor/consumidor con memoria compartida POSIX y *pipes*. |
| Consulta resumida | Se consultó por qué `gcc` rechazaba `usleep()` bajo `_POSIX_C_SOURCE=200809L` en Arch Linux y cómo sustituirlo por una alternativa POSIX vigente para simular carga y reproducir condiciones de carrera entre procesos hijos. |
| Resultado obtenido | Se reemplazó `usleep()` por `nanosleep()` usando `struct timespec` en `<time.h>`, logrando compilación limpia sin advertencias (`-Wall -Wextra`). En las pruebas de 2000 eventos con 4 consumidores, se obtuvo 0 % de pérdida con semáforo (`sem_t`) frente a una pérdida promedio de 1282.4 eventos (64.12 %, $s = 317.15$) sin sincronización. |
| Validado / corregido / descartado | **Corregido:** La primera propuesta usaba `usleep()`, que está obsoleta en POSIX.1-2008; se descartó y corrigió por `nanosleep()`. Además, se ajustó la compilación en `install.sh` para realizarla en `/tmp/arenalos-ipc-build` porque la carpeta compartida `/media/sf_arenalos` restringe permisos de ejecución. |
| Cómo se validó | Compilación con `make` sin *warnings*, 10 ejecuciones comparativas (`--events 2000 --workers 4` con y sin `--no-sync`), rastreo de llamadas al sistema con `strace -f` (`pipe2`, `openat` en `/dev/shm/arenalos_ipc_telemetry`, `mmap(..., MAP_SHARED)`, `clone`, `wait4`) y verificación de ausencia de procesos *zombie* (`Z`) con `ps` tras enviar `SIGTERM`. |

### S-2 Diagnóstico de modos de recuperación (`emergency.target`) y parámetros del kernel en `systemd-boot` (Tema 7)

| Campo | Contenido |
| :--- | :--- |
| Fecha - integrante | 14/11/2026 - Sebastián |
| Herramienta | Gemini con Hydrogen |
| Componente | `docs/tema-07-arranque.md`, `/boot/loader/loader.conf`, `/boot/loader/entries/arenalos-lts.conf`, `install.sh` |
| Propósito | Diagnosticar por qué al probar `systemd.unit=emergency.target` el sistema seguía arrancando en modo gráfico o montando `/` como `rw` en lugar de `ro`, y analizar los cuellos de botella del arranque. |
| Consulta resumida | Se consultó por qué el menú de `systemd-boot` omitía la edición con `timeout 1` y por qué `findmnt /` mostraba `rw` dentro de `emergency.target` en ArenalOS. |
| Resultado obtenido | Se identificó que `timeout 1` en `loader.conf` expiraba antes de confirmar la edición si no se detenía el menú con la barra espaciadora, y que la directiva `options` de `arenalos-lts.conf` incluye `rw` explícitamente, provocando que el `initramfs` monte `/` en lectura/escritura antes de transferir el control a `systemd`. Tras optimizar (`timeout 1` y `systemctl mask NetworkManager-wait-online.service`), el tiempo promedio del SO bajó de **9.461 s** a **7.763 s** (-17.95 %). |
| Validado / corregido / descartado | **Validado y corregido:** Se comprobó que para forzar `/` en solo lectura (`ro`) en emergencia debe sustituirse `rw` por `ro` junto con `systemd.unit=emergency.target` en la línea de edición del bootloader. También se corrigió la lectura de `/boot/loader/entries/*.conf` mediante `sudo cat` directo debido a que la expansión de comodines `*` fallaba sin permisos de lectura previos. |
| Cómo se validó | Arranque interactivo en vivo presionando `e` en `systemd-boot` para `rescue.target` y `emergency.target`, comprobando las unidades activas con `systemctl list-units --type=target --state=active` y `findmnt /`, más 10 mediciones completas (5 antes y 5 después) con `systemd-analyze` y `systemd-analyze critical-chain`. |

### S-3 Depuración de formatos CRLF (`env: 'python3\r'`) y permisos en carpeta compartida para `ipc-activo` y `arranque-info` (Fase 5)

| Campo | Contenido |
| :--- | :--- |
| Fecha - integrante | 15/11/2026 - Sebastián |
| Herramienta | Gemini con Hydrogen |
| Componente | `bin/ipc-activo`, `bin/arranque-info`, `scripts/install-comandos-ipc-arranque.sh` |
| Propósito | Corregir errores de sintaxis en el código extraído de la especificación y resolver el fallo de ejecución `env: 'python3\r': No such file or directory` al transferir scripts creados desde Windows hacia la VM Linux. |
| Consulta resumida | Se consultó el origen del error `env: 'python3\r': No such file or directory` al ejecutar `/usr/local/bin/ipc-activo` y `[Errno 13] Permission denied` al leer desde `/media/sf_arenalos`. |
| Resultado obtenido | Se detectó que los archivos creados en Windows conservaban saltos de línea CRLF (`\r\n`), haciendo que el kernel interpretara `\r` como parte del nombre del binario en el *shebang* `#!/usr/bin/env python3`. Se sanearon todos los scripts a formato LF (`\n`) con `sed -i 's/\r$//'` y se reinstalaron en `/usr/local/bin/`. |
| Validado / corregido / descartado | **Corregido:** Se corrigieron operadores y comillas dañadas en el código base de Python (como `SO_ACCEPTCON = 0x10000` y el conteo de líneas en `/proc/sysvipc/shm` descontando la cabecera `len(f.readlines()) - 1`) y se fijó LF en el editor. |
| Cómo se validó | Ejecución idempotente doble de `scripts/install-comandos-ipc-arranque.sh`, validación de argumentos con `ipc-activo -n 0`, prueba controlada creando un socket Unix (`/tmp/prueba-ipc.sock`), un *pipe*, un segmento System V (`ipcmk -M 4096`) y un objeto POSIX (`/dev/shm/prueba-ipc`), y contraste de `arranque-info` contra `bootctl status`, `/proc/cmdline` y `systemd-analyze time`. |

### S-4 Validación de atajos de teclado XFCE y escape XML para integración (Fase 5)

| Campo | Contenido |
| :--- | :--- |
| Fecha - integrante | 15/11/2026 - Sebastián |
| Herramienta | Gemini con Hydrogen |
| Componente | `dotfiles/xfce/fragmentos/atajos-sebastian.txt`, `docs/cheatsheet-sebastian.md` |
| Propósito | Configurar mediante `xfconf-query` los 3 atajos (`Super+B`, `Super+I`, `Super+A`) sin colisionar con el sistema ni con otros integrantes, y generar los nodos XML escapados para la fusión en la Fase 6. |
| Consulta resumida | Se consultó la sintaxis exacta de `xfconf-query` para mantener abierta `xfce4-terminal` (`--hold`) ejecutando comandos propios y de Capa 2, así como el formato de entidades XML (`&lt;Super&gt;`, `&quot;`) requerido por `xfce4-keyboard-shortcuts.xml`. |
| Resultado obtenido | Se registraron y probaron los atajos `<Super>b` (`arranque-info`), `<Super>i` (`ipc-activo`) y `<Super>a` (`systemd-analyze critical-chain`) y se documentaron en `atajos-sebastian.txt` y `cheatsheet-sebastian.md` sin modificar archivos compartidos. |
| Validado / corregido / descartado | **Validado:** Se verificó que no existieran espacios dentro de `&lt;Super&gt;` ni comillas sin escapar que invalidaran el XML de `xfconf`. |
| Cómo se validó | Prueba interactiva presionando `Super+B`, `Super+I` y `Super+A` en la sesión gráfica XFCE de la VM y verificación de propiedades registradas con `xfconf-query -c xfce4-keyboard-shortcuts -l -v`. |