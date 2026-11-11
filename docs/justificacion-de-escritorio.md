# Justificación del escritorio de ArenalOS

ArenalOS usa **XFCE 4.20 sobre X11** como entorno gráfico. Este documento explica por qué se eligió, con datos medidos, frente a dos alternativas: KDE Plasma y i3.

## 1. Candidatos

Se compararon tres opciones con perfiles distintos. Las tres se instalaron desde el mismo punto de partida (ver sección 2) y se iniciaron en su sesión por defecto, sin personalizar.

| Candidato | Tipo | Servidor gráfico | Paquetes instalados |
|---|---|---|---|
| **XFCE** | Escritorio completo y liviano | X11 | Grupo `xfce4` (64 paquetes en la transacción) |
| **KDE Plasma** | Escritorio completo y de peso medio | Wayland | `plasma-desktop` 6.8.2-1 (versión mínima, no `plasma-meta`). Proveedores elegidos al instalar: `pipewire-jack` y `noto-fonts-emoji` |
| **i3** | Gestor de ventanas de mosaico, de referencia | X11 | `i3-wm`, `i3status`, `dmenu` y `xterm` |

Notas sobre cada candidato:

- **KDE Plasma solo ofrece sesión Wayland.** Con la versión 6.8.2 que trae Arch, `pacman -Ss plasma-x11` no devuelve ningún paquete, así que no existe sesión X11. Por eso KDE se mide en Wayland y los otros dos en X11.
- **XFCE 4.20** tiene soporte experimental para Wayland, pero su gestor de ventanas (`xfwm4`) solo funciona en X11. Se usa y se mide la sesión X11. El soporte Wayland no se probó.
- **i3** se mide como gestor de ventanas mínimo, con solo lo necesario para cumplir los atajos de terminal y de launcher (`xterm` y `dmenu`) y una barra básica (`i3status`). No es un escritorio equivalente en funciones: no trae panel, gestor de archivos ni ajustes gráficos. Se incluyó como referencia de lo más liviano posible.
- GNOME y Hyprland quedaron fuera de la comparación por su mayor exigencia de recursos. dwm se descartó por la dificultad de reproducir su configuración en el `install.sh`, ya que se configura recompilando código en C.

## 2. Método

**Qué se midió** (cada medición, en reposo y con el escritorio recién iniciado):

- Memoria usada y disponible, con `free -m` (columnas `used` y `available` de la fila `Mem`).
- Número de procesos, con `ps -e --no-headers | wc -l`.
- Memoria PSS total, como suma de la línea `Pss:` de `/proc/[0-9]*/smaps_rollup`. Se usa PSS (memoria proporcional) porque reparte la memoria compartida entre los procesos que la usan, que es la misma cifra que da `smem`. `smem` no está en los repositorios oficiales de Arch, así que se calculó directamente desde `/proc`.
- Espacio en disco, con `df -h /`.

Los cuatro comandos los ejecuta un script, `scripts/medir-escritorio.sh`, versionado en el repositorio, que guarda cada salida en `docs/logs/mediciones/medicion-<candidato>.txt`.

**Condiciones, iguales para los tres candidatos:**

- Máquina virtual de VirtualBox con 4 GB de RAM (3889 MB según `free -m`) y 2 vCPU, con el controlador gráfico VMSVGA, 128 MB de memoria de video y aceleración 3D activada.
- El mismo punto de partida: una instantánea (`base grafica`) con Arch, `xorg-server`, el gestor de login SDDM (instalado pero sin habilitar), la fuente `ttf-dejavu` y las Guest Additions de VirtualBox. Cada candidato se instaló desde esa instantánea, y al terminar se volvió a ella.
- SDDM como gestor de login provisional en los tres, solo para poder iniciar sesión. Suma lo mismo a cada candidato.
- Cada candidato en su sesión por defecto, sin personalizar y sin abrir aplicaciones.
- Un arranque de calentamiento descartado (el primer inicio crea configuración y gasta más), y después una medición, con la sesión recién iniciada y 3 minutos de espera para que terminen de arrancar los servicios.
- Las mediciones se tomaron desde una consola de texto (`tty3`) con la sesión gráfica abierta en segundo plano, para no sumar la memoria de una terminal gráfica, que es distinta en cada escritorio.

**Referencia del sistema sin escritorio:** con solo la base (sin ninguna sesión gráfica) la memoria PSS total es de 78 MB y el disco usado de 3.0 GB.

## 3. Resultados

Una medición por candidato, con el script, desde la misma instantánea:

| Candidato | Servidor gráfico | RAM usada (MB) | RAM disponible (MB) | Procesos | PSS (MB) | Disco usado (GB) |
|---|---|---|---|---|---|---|
| XFCE | X11 | 539 | 3350 | 140 | 288 | 3.2 |
| KDE Plasma | Wayland | 832 | 3057 | 171 | 652 | 4.9 |
| i3 | X11 | 426 | 3463 | 120 | 197 | 3.0 |

Detalle de `free -m` (MB):

| Candidato | total | used | free | shared | buff/cache | available | swap |
|---|---|---|---|---|---|---|---|
| XFCE | 3889 | 539 | 3041 | 4 | 517 | 3350 | 0 |
| KDE Plasma | 3889 | 832 | 2547 | 12 | 733 | 3057 | 0 |
| i3 | 3889 | 426 | 3211 | 25 | 480 | 3463 | 0 |

Diferencias respecto a XFCE:

| Comparación | RAM usada | Procesos | PSS | Disco |
|---|---|---|---|---|
| KDE Plasma frente a XFCE | +293 MB (+54 %) | +31 (+22 %) | +364 MB (2.3 veces) | +1.7 GB |
| i3 frente a XFCE | −113 MB (−21 %) | −20 (−14 %) | −91 MB (−32 %) | −0.2 GB |

Memoria PSS que añade cada escritorio sobre la base sin escritorio (78 MB): XFCE unos 210 MB, KDE Plasma unos 574 MB e i3 unos 119 MB.

Las salidas completas de los comandos están en `docs/logs/mediciones/` (`medicion-xfce.txt`, `medicion-kde.txt` y `medicion-i3.txt`), junto con una captura de pantalla de cada medición (`medicion-<candidato>.png`).

## 4. Elección e interpretación

**Se elige XFCE.** Primero los datos y después los demás criterios.

**Frente a KDE Plasma**, XFCE usa 293 MB menos de RAM (539 contra 832 MB, un 35 % menos que KDE), tiene 31 procesos menos (140 contra 171), menos de la mitad de memoria PSS (288 contra 652 MB) y ocupa 1.7 GB menos de disco. En la VM de 4 GB que se usó, el sistema con XFCE deja disponibles 3350 MB, 293 MB más que con KDE Plasma. Para una distribución que quiere dejar la mayor parte de la memoria a los programas que se ejecutan encima, la diferencia es relevante.

**Frente a i3**, XFCE usa más: 113 MB más de RAM, 20 procesos más y 91 MB más de PSS. Es el precio de ser un escritorio completo. i3 es el más liviano, pero lo que se midió es un gestor de ventanas mínimo: no incluye panel completo, gestor de archivos, ajustes gráficos ni configuración de pantalla, red o sonido por menús. La diferencia de 113 MB de RAM (el 3 % de la memoria total de la VM) se considera un costo razonable por tener esas piezas ya integradas, con XFCE todavía muy por debajo de KDE Plasma.

En resumen, XFCE queda en el punto intermedio: consume mucho menos que KDE Plasma y ofrece un escritorio completo, cosa que i3 no hace.

**Criterios complementarios** (no sustituyen a los datos, los acompañan):

- **Comodidad y facilidad de uso:** trae panel, menú de aplicaciones, gestor de archivos (`thunar`), terminal (`xfce4-terminal`) y ajustes gráficos listos desde la instalación. Cualquier integrante del equipo puede usarlo sin aprender un modelo de trabajo nuevo, a diferencia de un gestor de mosaico como i3.
- **Atajos y configuración versionable:** su configuración vive en archivos de texto bajo `~/.config/xfce4/` (por ejemplo, los atajos de teclado en `xfce4-keyboard-shortcuts.xml`), que se pueden guardar en `dotfiles/` y enlazar desde el `install.sh`. Eso permite que los cuatro integrantes reciban el mismo escritorio y los mismos atajos de forma reproducible.
- **Estabilidad en una máquina virtual:** XFCE arrancó sin problemas con la configuración por defecto de VirtualBox. KDE Plasma exige además Wayland y aceleración 3D, y depende más de la emulación gráfica, que es un riesgo mayor en máquinas virtuales.
- **Servidor gráfico:** X11 es una base madura y compatible con las herramientas que se usarán en las fases siguientes.
- **Mismo escritorio para todos:** todo el equipo usa el mismo entorno, por lo que conviene que sea uno liviano y predecible.

## 5. Piezas complementarias

Con XFCE como escritorio, las demás piezas se eligieron por lo que ya trae el escritorio y por la facilidad de reproducirlas en cada instalación:

| Pieza | Elegida | Alternativas consideradas | Motivo |
|---|---|---|---|
| Gestor de login | **SDDM** | LightDM | Es el gestor con el que se midieron los tres candidatos, así que lo medido coincide con lo que queda en la distro. Ya está instalado y probado, tiene temas personalizables y funciona con X11 y Wayland. Arrastra Qt6 (unos 150 a 200 MB de disco). LightDM es más liviano y usa GTK, como XFCE, pero exige instalar un greeter aparte y volver a probar, con una ganancia pequeña |
| Terminal | **`xfce4-terminal`** | `xterm`, `st`, `alacritty`, `kitty` | Viene con el grupo `xfce4` y se integra con el escritorio. No depende de OpenGL, que en una máquina virtual puede fallar o ir lento (`alacritty`, `kitty`). `st` se configura recompilando código, difícil de reproducir en el `install.sh`. `xterm` es más básica |
| Launcher | **`xfce4-appfinder`** | `dmenu`, `rofi` | Viene con `xfce4`, sin paquetes extra. `dmenu` está pensado para gestores de ventanas como i3, y `rofi` agrega un paquete y una configuración más |
| Barra de estado | **Panel de XFCE** | `polybar`, `tint2` | Ya está incluido y muestra hora, espacios de trabajo y bandeja del sistema. `polybar` está pensada para gestores de ventanas sin panel, y usarla aquí obligaría a duplicar o reemplazar el panel, con más paquetes y configuración. El panel además forma parte de lo medido |

Atajos obligatorios: la terminal se abre con `Super + Enter`, el launcher con `Super + D`, la ventana activa se cierra con `Super + Q` y los espacios de trabajo se cambian con `Super + [1-9]`.

## 6. Limitaciones

- **Servidores gráficos distintos:** KDE Plasma se midió en Wayland (su única sesión en la versión 6.8.2) y XFCE e i3 en X11. La comparación mezcla servidores gráficos, de modo que parte de la diferencia puede deberse a eso y no solo al escritorio. XFCE tiene soporte experimental para Wayland que no se probó.
- **i3 es un gestor de ventanas mínimo:** se midió con `i3status`, `dmenu` y `xterm`, y no como un escritorio equivalente en funciones. Por eso consume menos de lo que consumiría con las mismas piezas que XFCE, y la comparación con él es de referencia.
- **Una sola medición por candidato:** se optó por una medición tras un arranque de calentamiento descartado. No se calculan promedios ni desviaciones. Para dar una idea del ruido, la primera medición de XFCE, hecha a mano antes de tener el script, dio 535 MB de RAM usada, 139 procesos y 284 MB de PSS, frente a 539 MB, 140 procesos y 288 MB con el script: una diferencia de 4 MB y un proceso. Las diferencias entre candidatos (113 MB y 293 MB) son mucho mayores que ese ruido.
- **Ruido de la VM:** las mediciones dentro de una máquina virtual dependen del anfitrión y del emulador gráfico, y pueden variar un poco entre arranques.
- **El script suma 1 o 2 procesos:** el script de medición ejecuta algunos procesos adicionales respecto a los comandos escritos a mano. Afecta por igual a los tres candidatos.
- **El disco se leyó con la sesión ya iniciada**, no justo después de instalar, así que incluye la configuración y la caché que crea cada escritorio al arrancar. Después de instalar, XFCE ocupaba 3.1 GB y la base 3.0 GB.
- **Versiones de los paquetes:** KDE Plasma 6.8.2-1 y XFCE 4.20 a la fecha de la medición. Si las versiones cambian, los resultados pueden variar.
