# Bitácora de uso de IA

Formato del Anexo 3 del enunciado: una entrada por consulta relevante. Cada integrante registra las de los temas de los que es responsable principal.

---

## Jairo

### J-1 · Fase 0 · Reparto de temas

| Campo | Contenido |
|---|---|
| Fecha · integrante | 2026-10-05 · Jairo |
| Herramienta | OpenCode |
| Componente | Organización del equipo (Fase 0) |
| Propósito | Repartir los 8 temas de la Capa 2 al azar entre los integrantes |
| Consulta resumida | Repartir los 8 temas al azar, 2 por persona, según la plantilla de `responsabilidades.md` |
| Resultado obtenido | Temas repartidos, 2 para cada uno |
| Validado / corregido / descartado | Validado |
| Cómo se validó | Los temas repartidos eran los correctos |

### J-2 · Fase 1 · Decisiones previas a la instalación

| Campo | Contenido |
|---|---|
| Fecha · integrante | 2026-11-09 · Jairo |
| Herramienta | Claude (Anthropic) |
| Componente | Capa 1 · Instalación manual de Arch (decisiones) |
| Propósito | Entender y comparar las opciones de cada decisión antes de instalar |
| Consulta resumida | Listar las decisiones de la Fase 1 con ventajas y desventajas, y responderlas una por una preguntando lo que no entendía (hostname, kernel lts, pacstrap, tamaño de la raíz) |
| Resultado obtenido | Tabla de 16 decisiones, estimación de 9 a 13 GB para la raíz y dos archivos de respaldo con lo elegido y lo descartado |
| Validado / corregido / descartado | **Descarté** la recomendación inicial de la IA de usar ESP y raíz únicas: elegí ESP de 1 GiB, `/home` de 4 GiB y raíz al final. Elegí VirtualBox, disco de 20 GB, `linux-lts`, el nombre ArenalOS y un hostname por integrante |
| Cómo se validó | Comparé las opciones con A.2 y A.3 del enunciado y contrasté la estimación de la raíz con mi disco (se revisa con `df -h` al final) |

### J-3 · Fase 1 · Guía, ejecución y bitácora de instalación

| Campo | Contenido |
|---|---|
| Fecha · integrante | 2026-11-10 · Jairo |
| Herramienta | Claude (Anthropic) |
| Componente | Capa 1 · Instalación manual de Arch, `docs/instalacion.md` |
| Propósito | Obtener el paso a paso de la instalación, resolver los problemas al ejecutarlo y redactar la bitácora de instalación |
| Consulta resumida | Pedí la guía en un documento aparte, preguntas sobre los comandos que no entendía (consola, nano, `bootctl`, `fdisk`) y la redacción de `instalacion.md` |
| Resultado obtenido | Guía de 31 pasos con su porqué, evidencia en cuatro capturas por integrante y un borrador de `docs/instalacion.md` con una sección de problemas |
| Validado / corregido / descartado | **Errores de la IA corregidos:** el asistente de VirtualBox no tiene la casilla "Pre-Allocate Full Size"; la lista de orden de arranque sale deshabilitada con EFI; el paso 22 esperaba `initramfs-linux-lts-fallback.img`, que mi sistema no generó; su consejo de subir con Shift + Re Pág no funcionó y se cambió por `less`. El borrador decía que no hubo problemas y agregué el mío (los caracteres no se veían hasta dar Enter, se resolvió reabriendo la VM). Descarté capturas que el enunciado no pide |
| Cómo se validó | Ejecuté los pasos en mi VM y comparé la guía con la pantalla; revisé la evidencia contra A.3 del enunciado |

### J-4 · Fase 2 · Opciones de escritorio y guía

| Campo | Contenido |
|---|---|
| Fecha · integrante | 2026-11-10 · Jairo |
| Herramienta | Claude (Anthropic) |
| Componente | Capa 1 · Entorno gráfico (decisiones y guía de la Fase 2) |
| Propósito | Comparar escritorio, servidor gráfico, login y WM de referencia, y obtener la guía de la fase |
| Consulta resumida | Listar las decisiones con ventajas y desventajas, responderlas una por una y pedir la guía en cuatro partes |
| Resultado obtenido | Candidatos XFCE, KDE Plasma e i3 (referencia), X11 para XFCE e i3, SDDM provisional, y una guía de 28 pasos |
| Validado / corregido / descartado | Descarté GNOME y Hyprland (recursos, Wayland), dwm (se configura recompilando, difícil de reproducir) y bspwm, openbox y Sway; elegí i3. **Errores de la IA corregidos:** el teclado latinoamericano debía ir antes de los atajos, y la guía solo ponía `sudo` en el `touch` de la carpeta compartida, aunque hasta el `ls` daba `Permission denied` |
| Cómo se validó | Comparé con A.5 del enunciado; comprobé con `pacman -Ss plasma-x11` (sin resultados) que KDE Plasma 6.8 es solo Wayland; seguí la guía en mi VM |

### J-5 · Fase 2 · Medición y justificación del escritorio

| Campo | Contenido |
|---|---|
| Fecha · integrante | 2026-11-11 · Jairo |
| Herramienta | Claude (Anthropic) |
| Componente | Capa 1 · `scripts/medir-escritorio.sh`, `docs/justificacion-de-escritorio.md` |
| Propósito | Medir el consumo de cada candidato de forma igual y reproducible, y justificar la elección con datos |
| Consulta resumida | Pedí un método y un script de medición, pasé las salidas y capturas, y pedí la justificación; decidí las piezas definitivas (terminal, launcher, barra y login) |
| Resultado obtenido | XFCE 539 MB, 140 procesos, 288 MB de PSS; KDE 832 MB, 171, 652 MB; i3 426 MB, 120, 197 MB. Elegí `xfce4-terminal`, `xfce4-appfinder`, la barra de XFCE y SDDM |
| Validado / corregido / descartado | **Errores de la IA corregidos:** el método usaba `smem`, que no está en los repos oficiales (se calculó el PSS desde `/proc/*/smaps_rollup`); el script guardaba logs en una carpeta con mi nombre (pasó a una carpeta común). Descarté las tres mediciones por candidato (una sola, tras un arranque de calentamiento) y pedí que la justificación no dijera "descartado por riesgo", solo por recursos o dificultad de reproducir. Descarté polybar y tint2 |
| Cómo se validó | Comparé cada cifra con `medicion-xfce.txt`, `medicion-kde.txt` y `medicion-i3.txt`; contrasté mi medición a mano con la del script (535 contra 539 MB) para estimar el ruido |

### J-6 · Fase 2 · Atajos, teclado, fondo y herramientas de la VM

| Campo | Contenido |
|---|---|
| Fecha · integrante | 2026-11-11 · Jairo |
| Herramienta | Claude (Anthropic) |
| Componente | Capa 3 · atajos obligatorios; teclado y fondo de pantalla (foto del volcán, CC BY-SA 4.0) |
| Propósito | Configurar los 4 atajos, el teclado latinoamericano y el fondo, y entender cómo pasar archivos y texto a la VM |
| Consulta resumida | Pregunté de dónde salían los 9 workspaces y cómo crear los atajos, pedí una foto con licencia libre del Arenal y cómo ponerla de fondo, y por qué fallaban los permisos de la carpeta compartida |
| Resultado obtenido | `setxkbmap latam` y `localectl set-x11-keymap latam`, 9 workspaces y 4 atajos con `xfconf-query`; foto de Rhododendrites reducida a 1920 px en `/usr/share/backgrounds/xfce/arenal.jpg` con `NoExtract` en `pacman.conf`; archivos por carpeta compartida y texto por portapapeles |
| Validado / corregido / descartado | **Errores de la IA corregidos:** la arroba es AltGr + Q, no + 2; el bucle del fondo solo cambiaba propiedades existentes y no había ninguna (se creó con `-n -t string`); el fondo salió negro porque el archivo copiado con `sudo` era de root; la foto descargada era la original de 20 MB y hubo que reducirla con ImageMagick (lo desinstalé después). Descarté dejar los fondos por defecto y la foto en `~/Pictures` |
| Cómo se validó | `localectl status` y escribir ñ y @; `xfconf-query -lv` con `grep -i super` y probé los 4 atajos; `ls -lh` y `file` (578 KB, 1920x1061); vi el fondo en pantalla; revisé la licencia CC BY-SA 4.0 |

### J-7 · Fase 3 · Bootstrap (`pkglist.txt` e `install.sh`)

| Campo | Contenido |
|---|---|
| Fecha · integrante | 2026-11-11 · Jairo |
| Herramienta | Claude (Anthropic) |
| Componente | Capa 1 · `pkglist.txt`, `install.sh`, snapshot `pre-instalador` |
| Propósito | Organizar la fase, escribir y probar el instalador que repite la Fase 2, y elegir el snapshot desde el que probarlo |
| Consulta resumida | Pregunté cuánto dura la fase y dónde va el `install.sh`; pedí la guía y la ajusté; pegué los errores de la prueba; pregunté qué snapshot servía como base limpia. Respondí a un compañero con propuestas: XFCE con X11, puerto 22 y Python 3 |
| Resultado obtenido | Guía de 16 pasos; `pkglist.txt` de 9 paquetes; `install.sh` de siete bloques (NoExtract, paquetes, fondo, teclado, XML de XFCE, SDDM y sesión X11), con un log por máquina; snapshot nuevo `pre-instalador` |
| Validado / corregido / descartado | **Errores de la IA corregidos:** el bloque del paso 7 es el texto de un archivo, no comandos; `hostname` no existe en Arch (se usó `$HOSTNAME`); SDDM ofrecía la sesión Wayland (se escribió `/var/lib/sddm/state.conf` con X11); "limpio" era un nombre inventado y `base grafica` no servía de base. La IA dividió el instalador en `install.d/` y modificó la guía sin que se lo pidiera: se descartó. Dejé las propuestas del puerto y del lenguaje como pendientes del equipo |
| Cómo se validó | `sudo cat` de los archivos en la VM; ejecuté el instalador, reinicié y vi el login; revisé el árbol de snapshots de VirtualBox |

### J-8 · Fase 4 · Organización y Tema 1 (Procesos y planificación)

| Campo | Contenido |
|---|---|
| Fecha · integrante | 2026-11-15 · Jairo |
| Herramienta | Claude (Anthropic) |
| Componente | Tema 1 · `src/procesos/procesos.py`, `scripts/experimento-nice.sh`, `scripts/experimento-rt.sh`, `docs/tema-01-procesos.md` |
| Propósito | Obtener la guía de mis dos temas, listar procesos desde `/proc`, medir el reparto de CPU con nice y tiempo real, y redactar la ficha |
| Consulta resumida | Pedí la guía con una sola rama (`jairo-fase4-t1-t6`) y Python; pegué las salidas de las pruebas y experimentos; pedí la ficha con referencias verificadas contra los PDF de los libros |
| Resultado obtenido | Con nice 0 y 10: 90,3 % y 9,7 %; con 0, 5 y 10: 69,8 %, 22,8 % y 7,5 %; con `SCHED_FIFO` frente a un proceso normal: 95,1 % y 4,9 %, igual al límite del kernel (950000 de 1000000 µs). Ficha con Silberschatz cap. 5 y Tanenbaum y Bos cap. 2 |
| Validado / corregido / descartado | **Errores de la IA corregidos:** la guía decía `Errno 1` en las dos pruebas negativas y `nice -5` dio `Errno 13` (EACCES); omitía el `Permission denied` sin `sudo` en la carpeta compartida; propuso una rama por tema y una de integración (dejé una sola); y citó referencias que no se pudieron verificar (OSTEP cap. 9 y Silberschatz 9.ª ed. cap. 6), que descarté |
| Cómo se validó | Calculé los porcentajes con los pesos del kernel (1024, 335 y 110); comparé el listado con `ps`; repetí cada experimento 3 veces; comprobé los títulos de sección en los PDF y las tablas contra `docs/logs/tema-01/` |

### J-9 · Fase 4 · Tema 6 (Gestión de paquetes)

| Campo | Contenido |
|---|---|
| Fecha · integrante | 2026-11-15 · Jairo |
| Herramienta | Claude (Anthropic) |
| Componente | Tema 6 · `pacman/arenalos-explicitos.hook`, `pacman/PKGBUILD` (paquete `arenalos-procesos`) |
| Propósito | Documentar la base de datos, firmas, dependencias y hooks de pacman, probar un hook propio y empaquetar la herramienta del Tema 1 |
| Consulta resumida | Pegué las salidas de la exploración, de `pactree` y de instalar `tree`; pregunté si el hook no debía ir en `install.sh`, de dónde toma el PKGBUILD su archivo fuente y por qué `python` y `xorg-xrandr` salían como no instalados |
| Resultado obtenido | 409 paquetes, `SigLevel = Required DatabaseOptional`, árboles de `sudo` y `nano`; el hook llevó la lista de explícitos de 30 a 31 y de 31 a 30, a 0,049 s por ejecución; paquete 1.0-1 (any, depende de python) con `Validated By: None`; `python` y `xorg-xrandr` son dependencias de otros paquetes y `xfce4` es un grupo |
| Validado / corregido / descartado | **Errores de la IA corregidos:** la guía no advertía el aviso de gpg sin `sudo`; afirmó cosas sobre una clave del llavero que no se podían saber con `head -8`; supuso que reinstalar `tree` dispararía el hook (no lo hizo, es Upgrade); esperaba una segunda lista vacía con una etiqueta engañosa; un comando traía una palabra mal escrita. Pedí que el hook se instalara con el instalador y no a mano |
| Cómo se validó | Revisé `/var/log/pacman.log` y `explicitos.txt` antes y después de cada transacción; `pacman -Qi`, `-Ql` y `-Qo` sobre el paquete, y `pacman -Qi python xorg-xrandr` |

### J-10 · Fase 5 · Capa 3 del Tema 1 (comandos y atajos)

| Campo | Contenido |
|---|---|
| Fecha · integrante | 2026-11-16 · Jairo |
| Herramienta | Claude (Anthropic) |
| Componente | Tema 1 · `bin/cambios-contexto`, `bin/presion-cpu`, atajos Super+T, Super+C y Super+O, `docs/cheatsheet-jairo.md` |
| Propósito | Obtener la guía de la fase solo para mis temas, crear dos comandos libres que muestren la competencia por la CPU leyendo `/proc`, y tres atajos de XFCE |
| Consulta resumida | Pedí una guía independiente de los demás integrantes (sin `midistro-info`, que pasa a la Fase 6); pegué la salida de las pruebas; pregunté si los archivos llevaban `.py`, cómo se usan los comandos, y por qué las terminales de los atajos no aceptan texto |
| Resultado obtenido | Guía de 22 pasos; con dos procesos `sh` fijados a la CPU 0, `cambios-contexto` mostró unos 162 cambios involuntarios por segundo (100 % involuntarios) y `presion-cpu` mostró cpu0 al 100 %, carga de 0,55 y PSI some de 70,27 % frente a 0,70 % en reposo. Atajos creados con `xfconf-query` (terminales con `--hold`) |
| Validado / corregido / descartado | **Errores de la IA corregidos:** la primera versión era una sola guía que dependía de que otros integrantes integraran su parte (la cambié por guías independientes); la prueba se ejecutaba antes de crear los archivos y dio `No such file or directory`; no decía que los comandos son scripts de Python sin extensión; la tabla de la cheatsheet venía en partes y sin alinear; no avisaba que las terminales no son interactivas. La IA no pudo cambiar los títulos publicados de las guías |
| Cómo se validó | Repetí la prueba con los archivos creados y comprobé el resultado esperado (dos procesos compitiendo por una CPU); guardé las salidas en `docs/logs/capa3/`; presioné los tres atajos y los recreé tras restaurar `pre-instalador` |

### J-11 · Fase 5 · Tema 6 (paquete de la Capa 3) y licencia

| Campo | Contenido |
|---|---|
| Fecha · integrante | 2026-11-16 · Jairo |
| Herramienta | Claude (Anthropic) |
| Componente | Tema 6 · `pacman/cambios-contexto/PKGBUILD`, `scripts/install-comandos-capa3.sh`, `docs/tema-06-paquetes.md`; decisión de licencia |
| Propósito | Empaquetar un comando de la Capa 3 con el método de la Fase 4, conectarlo a `install.sh`, actualizar la ficha y decidir si el proyecto lleva licencia |
| Consulta resumida | Pegué la salida de `makepkg`, de la instalación y del log, y pedí el paso de la ficha completo para copiar y pegar; pregunté qué licencia conviene si no quiero que vendan el software y qué pasa si no pongo ninguna |
| Resultado obtenido | Paquete `arenalos-cambios-contexto` 1.0-1 (any, depende de python): 2,41 KiB, explícito, `Validated By: None`, `Packager: Unknown Packager`; al instalarlo corrió el hook de la Fase 4. Sobre licencias: ninguna licencia OSI impide vender; sin licencia quedan todos los derechos reservados |
| Validado / corregido / descartado | **Error de la IA corregido:** el paso de la ficha solo describía qué agregar, sin el texto (pedí reescribirlo con las cifras reales); el 0,00 MiB de pacman era redondeo. **Descarté** poner licencia por ahora (la guía proponía MIT con pasos condicionales; los quité y el tema pasó a los apuntes para después del proyecto); el PKGBUILD queda con `license=('custom')` |
| Cómo se validó | `pacman -Qi`, `-Ql` y `-Qo`, con la salida en `docs/logs/tema-06/paquete-capa3.txt`; revisé el enunciado, que no pide licencia en ninguna rúbrica |

### J-12 · Bootstrap · Prueba del instalador con los Temas 1 y 6

| Campo | Contenido |
|---|---|
| Fecha · integrante | 2026-11-16 · Jairo |
| Herramienta | Claude (Anthropic) |
| Componente | Bootstrap · `install.sh`, `scripts/install-procesos-paquetes.sh`, `scripts/install-comandos-capa3.sh`, `docs/tema-06-paquetes.md` |
| Propósito | Comprobar que el hook, el paquete y los comandos se instalan solos desde una base limpia y que el instalador se puede repetir |
| Consulta resumida | Restauré `pre-instalador`, ejecuté `install.sh` dos veces y pegué las verificaciones y el final del log; pregunté para qué instalar dos veces, para qué recrear los atajos y para qué el `rm -rf ~/pruebas` final |
| Resultado obtenido | `cambios-contexto` en `/usr/bin` y `presion-cpu` en `/usr/local/bin`; `explicitos.txt` pasó de 32 a 33 líneas (`arenalos-procesos`, `base-devel`, `pacman-contrib` y `python` más el paquete nuevo); el log de la segunda ejecución terminó en `== Listo ==` y el hook no corrió al reinstalar. El experimento de nice sobre el sistema integrado volvió a dar 90,3 % y 9,7 % |
| Validado / corregido / descartado | **Errores de la IA corregidos:** `tail` sin `sudo` daba `Permission denied`; la guía no quitaba `tree` antes del snapshot; esperaba 30 líneas (salieron 32) y suponía que `python` era dependencia (desde la base limpia es explícito); dejó marcadores (`<su log de la instalación>`, `NOMBRE`) que escritos literalmente dieron `syntax error` y `No such file or directory` (se puso `install-arenalos-jairo.log`); el `rm -rf ~/pruebas` era innecesario porque restaurar el snapshot ya lo elimina. En la ficha quité una frase sobre el tiempo de `makepkg` que no se midió |
| Cómo se validó | Ejecuté el instalador dos veces desde el snapshot, revisé el log con `sudo tail`, comprobé con `grep -x tree` que salió de la lista y comparé cada cifra de la ficha con `docs/logs/tema-06/` |

### J-13 · Extras · Panel, aplicaciones por defecto, SDDM y reloj (fuera de la evaluación)

| Campo | Contenido |
|---|---|
| Fecha · integrante | 2026-11-16 · Jairo |
| Herramienta | Claude (Anthropic) |
| Componente | Extras de escritorio · `pkglist.txt`, `scripts/install-extras.sh`, `install.sh`, `dotfiles/xfce/xfconf/xfce-perchannel-xml/xfce4-panel.xml` |
| Propósito | Dejar el escritorio más cómodo y reproducible: lista de ventanas abiertas, aplicaciones por defecto, navegador, fondo del volcán en el login y hora y fecha centradas |
| Consulta resumida | Pregunté si XFCE cierra al minimizar y pedí un panel tipo Ubuntu, reproductor, visor de fotos y navegador por defecto, la foto del volcán en SDDM y la hora y fecha en el centro del escritorio y del bloqueo, todo en una guía corta de cajas para pegar y sin comandos de git. Después pegué los problemas: el plugin del panel no aparecía, `Permission denied` en la carpeta compartida y VLC sin decodificar H.264; y pedí papelera, editor de texto y LibreOffice |
| Resultado obtenido | Paquetes `firefox`, `vlc`, `vlc-plugin-ffmpeg`, `ristretto`, `xfce4-docklike-plugin`, `xfce4-screensaver` y `conky` bajo `# --- Extras del escritorio ---`; el script genera las aplicaciones por defecto (Thunar, VLC, Ristretto, Firefox), el fondo de SDDM con la misma foto y el reloj de Conky; el panel con Docklike se armó una vez y se guarda en dotfiles. Brave se descartó por ser solo del AUR. `gvfs` (papelera), `mousepad` y `libreoffice-fresh` quedaron pedidos a `pkglist.txt` (por confirmar) |
| Validado / corregido / descartado | **Errores de la IA corregidos:** la guía traía comandos de git y los quité; agregó los paquetes y la llamada en la sección de "Temas 1 y 6" (pasaron a su propio encabezado, con un bloque que se puede repetir); agregó `libreoffice-fresh-es` sin pedirlo y lo quité; instaló `vlc` sin el plugin de ffmpeg (faltaba `vlc-plugin-ffmpeg`); ante el `Permission denied` propuso primero el grupo `vboxsf` y volver a montar la carpeta, y la causa real era `/media` con permisos 750 (se resolvió con `chmod 755 /media`, también pedido a `install.sh`) |
| Cómo se validó | `xdg-mime query default` para cinco tipos de archivo, `pacman -Q` y `xfce4-panel -r` para el plugin, `namei -l /media/sf_arenalos` para hallar la causa de los permisos, y restaurar el snapshot y correr `install.sh` para comprobar el panel, la hora y la fecha en el escritorio y en el bloqueo, y el fondo del login |

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
