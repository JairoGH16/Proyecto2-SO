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
