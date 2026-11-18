# Comandos propios de ArenalOS (Capa 3)

Cada comando está en [`bin/`](../bin/) y `install.sh` lo deja en el `PATH`: `cambios-contexto` como el paquete `arenalos-cambios-contexto` (en `/usr/bin`) y los demás en `/usr/local/bin/`. El enunciado exige que cada uno use al menos una interfaz del SO y documente cuál.

| Comando                                   | Autor                             | Interfaces del SO                                                                                   | Tema relacionado |
|-------------------------------------------|-----------------------------------|-----------------------------------------------------------------------------------------------------|------------------|
| [`midistro-info`](#midistro-info)         | Equipo (un módulo por integrante) | `/proc`, `/sys`, `os.statvfs`, `os.uname`                                                           | Todos            |
| [`cambios-contexto`](#cambios-contexto)   | Jairo                             | `/proc/<pid>/status`                                                                                | T1, T6           |
| [`presion-cpu`](#presion-cpu)             | Jairo                             | `/proc/pressure/cpu`, `/proc/loadavg`, `/proc/stat`                                                 | T1               |
| [`riesgo-oom`](#riesgo-oom)               | Rafael Odio                       | `/proc/<pid>/oom_score`, `/proc/<pid>/oom_score_adj`, `/proc/<pid>/status`, `/proc/pressure/memory` | T2               |
| [`servicios-limites`](#servicios-limites) | Rafael Odio                       | cgroups v2: `/sys/fs/cgroup/system.slice/*.service/{cpu.max,memory.max,memory.current,cpu.stat}`    | T4               |
| [`ipc-activo`](#ipc-activo)               | Sebastián                         | `/proc/net/unix`, `/proc/<pid>/fd`, `/proc/sysvipc/shm`, `/dev/shm`                                 | T5               |
| [`arranque-info`](#arranque-info)         | Sebastián                         | `/sys/firmware/efi`, `/proc/cmdline`, `/proc/uptime`, systemd (`systemctl`, `systemd-analyze`)      | T7               |
| [`usb-historial`](#usb-historial)         | Esteban                           | `/sys/bus/usb/devices`, `/sys/block`, `/proc/mounts`, log de la regla udev                          | T8               |
| [`puertos-abiertos`](#puertos-abiertos)   | Esteban                           | `/proc/net/{tcp,tcp6,udp,udp6}`, `/proc/<pid>/fd`, netfilter (`nft`)                                | T9               |

---

## midistro-info

**Qué hace.** Es el comando obligatorio de la Capa 3: muestra en una sola vista el equipo, el kernel, el uptime, la CPU, la GPU y la NPU con su driver, la memoria, la swap y zram, los procesos por estado, el planificador y el sistema de archivos raíz. Está escrito en Python 3 con solo la biblioteca estándar, lee `/proc`, `/sys` y llamadas al sistema, y no llama a programas externos ni depende de `neofetch`, `fastfetch` o parecidos.

`bin/midistro-info` es un cargador: busca los módulos `modulo_*.py`, los ordena por su `ORDEN` e imprime la sección de cada uno. Cada integrante escribió un módulo en `src/midistro-info/`. Si un módulo falla, se imprime una línea con el error y las demás secciones salen igual.

**Uso.**
```
midistro-info                      # todas las secciones, en orden
MIDISTRO_DEBUG=1 midistro-info     # además, el traceback del módulo que falle
python3 src/midistro-info/modulo_memoria.py   # un solo módulo, desde el repo
```
Los módulos se buscan, en este orden, en `$MIDISTRO_MODULOS`, en `/usr/local/lib/midistro-info` (donde los deja `scripts/install-midistro-info.sh`) y en `../src/midistro-info` relativo al comando (para probar desde el repo).

**Interfaces del SO, por módulo.**

| Módulo                   | ORDEN | Integrante | Interfaces del SO                                                                                                                              | Capa 2                                                      |
|--------------------------|-------|------------|------------------------------------------------------------------------------------------------------------------------------------------------|-------------------------------------------------------------|
| `modulo_sistema.py`      | 10    | Sebastián  | `/proc/sys/kernel/{hostname,osrelease}`, `/proc/uptime`, `/proc/cpuinfo`, `os.cpu_count()`, `/proc/mounts`, `os.statvfs("/")`                  | El uptime es el mismo dato que muestra `arranque-info` (T7) |
| `modulo_dispositivos.py` | 20    | Esteban    | `/sys/bus/pci/devices/*/{class,vendor,device}`, enlace `driver` de cada dispositivo, `/sys/class/accel`, `/usr/share/hwdata/pci.ids` (nombres) | Lo mismo que registró el Tema 8 con `lspci -k`              |
| `modulo_memoria.py`      | 30    | Rafael     | `/proc/meminfo`, `/proc/swaps`, `/sys/block/zram0/{mm_stat,comp_algorithm}`                                                                    | Importa `memoria.py` (T2); si no puede, lee directo         |
| `modulo_procesos.py`     | 40    | Jairo      | `/proc/PID/stat`, `os.uname()` (EEVDF desde el kernel 6.6, CFS antes), `/proc/sys/kernel/sched_rt_{runtime,period}_us`                         | Importa `procesos.py` (T1); si no puede, lee directo        |

La GPU es la clase PCI que empieza por `0x03` y la NPU la `0x1200`; el driver sale del enlace simbólico `driver`. Si no hay GPU o NPU, el módulo imprime "no detectada", y si no tienen driver, "sin driver cargado". La raíz de sysfs se puede cambiar con `MIDISTRO_SYSFS` para probar con un árbol falso: se probó con GPU con driver, GPU sin driver, NPU por PCI, NPU solo en `/sys/class/accel` y sin ningún dispositivo.

**Ejemplo.** Pendiente: se agregará la salida real de la VM de ArenalOS, guardada en `docs/logs/capa3/midistro-info.txt`.

---

## cambios-contexto

**Qué hace.** Muestra los procesos con más cambios de contexto por segundo, separando los voluntarios (el proceso cedió la CPU, por ejemplo al esperar E/S) de los involuntarios (el planificador se la quitó porque se le acabó el turno o llegó otro con más derecho). Un `%INV` alto indica que el proceso compite por la CPU.

**Uso.**
```
cambios-contexto              # 10 procesos, muestra de 1 s
cambios-contexto -n 20 -t 2   # 20 procesos, muestra de 2 s
cambios-contexto -h           # ayuda
```

**Interfaces del SO.**
- `/proc/<pid>/status`: campos `voluntary_ctxt_switches` y `nonvoluntary_ctxt_switches`, contadores acumulados desde que nació el proceso. El comando toma dos muestras separadas por el intervalo `-t` y divide la diferencia entre los segundos.

**Instalación.** Además de correr desde `bin/`, se instala como el paquete `arenalos-cambios-contexto` (Tema 6), que deja el comando en `/usr/bin/cambios-contexto`.

**Ejemplo** (salida real, [`docs/logs/capa3/cambios-contexto.txt`](logs/capa3/cambios-contexto.txt)), con dos procesos `sh` en bucle infinito fijados a la CPU 0 con `taskset`:
```
    PID     VOL/s     INV/s   %INV  COMANDO
   3929       0.0     162.5  100.0  sh
   3930       0.0     161.5  100.0  sh
    370      33.5      11.5   25.6  Xorg
   2957       9.5      13.0   57.8  at-spi2-registr
   2970      14.5       4.0   21.6  xfwm4
```
Los dos `sh` nunca ceden la CPU (0 voluntarios) y el planificador se la quita unas 160 veces por segundo a cada uno (100 % involuntarios): compiten por una sola CPU. En reposo, en cambio, los procesos con más cambios (`Xorg`, `xfce4-terminal`, `kworker`) son casi todos voluntarios.

---

## presion-cpu

**Qué hace.** Resume cuánta competencia hay por la CPU en este momento: carga media, procesos ejecutables y bloqueados, uso de cada CPU durante la muestra y la presión PSI (*pressure stall information*), que es el porcentaje del tiempo en que al menos un proceso esperó CPU. Es más fiel que la carga media porque mide espera real.

**Uso.**
```
presion-cpu         # muestra de 1 s
presion-cpu -t 5    # muestra de 5 s
presion-cpu -h      # ayuda
```

**Interfaces del SO.**
- `/proc/pressure/cpu`: PSI de la CPU. La línea `some` trae el porcentaje de los últimos 10, 60 y 300 segundos.
- `/proc/loadavg`: carga media de 1, 5 y 15 minutos y la cuenta de procesos ejecutables y existentes.
- `/proc/stat`: tiempo de cada CPU (de ahí sale el uso durante la muestra) y `procs_blocked`, los procesos bloqueados esperando E/S.

**Ejemplo** (salida real, [`docs/logs/capa3/presion-cpu.txt`](logs/capa3/presion-cpu.txt)), 12 s después de poner dos `sh` en bucle en la CPU 0:
```
Carga media (1/5/15 min): 0.55 0.15 0.07
Procesos ejecutables ahora / existentes: 3 / 293
Procesos bloqueados esperando E/S: 0

Uso por CPU durante la muestra:
  cpu0: 100.0 %
  cpu1:   1.0 %

PSI cpu 'some': 70.27 % (10 s)  20.03 % (60 s)  5.30 % (300 s)
  'some' = porcentaje del tiempo en que al menos un proceso esperó CPU.
```
En reposo la misma medición daba un PSI de 0.70 % (10 s) y `cpu0` en 0.0 %. Con la carga, `cpu0` sube a 100 % y el PSI a 70 %, porque siempre hay un proceso esperando turno en esa CPU; la carga media de 1 minuto apenas llega a 0.55 porque es un promedio lento.

---

## `riesgo-oom`

**Qué hace.** Muestra qué procesos mataría primero el OOM killer: cada proceso tiene un puntaje (`oom_score`) que el kernel calcula según cuánta memoria usa, y el de mayor puntaje muere primero. El administrador puede inclinar la balanza con `oom_score_adj` (de -1000, nunca matar, a 1000, matar primero).

**Uso:**

```bash
riesgo-oom              # top 10 por defecto
riesgo-oom -n 5
```

**Interfaces del SO:**

- `/proc/meminfo` — campo `MemAvailable`, memoria realmente disponible para nuevas asignaciones.
- `/proc/pressure/memory` — PSI (Pressure Stall Information) de memoria; la línea `some` indica el % de tiempo que al menos una tarea estuvo bloqueada esperando memoria.
- `/proc/<pid>/oom_score` — el puntaje que calcula el kernel para ese proceso.
- `/proc/<pid>/oom_score_adj` — el ajuste manual aplicado (-1000 a 1000).
- `/proc/<pid>/status` — campo `VmRSS`, memoria física residente del proceso.

**Ejemplo** (de `docs/logs/capa3/riesgo-oom.txt`, en reposo, con `stress-ng --vm 1 --vm-bytes 512M` corriendo, y con un `sleep` al que se le subió `oom_score_adj` a 500):

```
$ riesgo-oom -n 5   (en reposo)
Memoria disponible: 3332 MiB
PSI memoria 'some': avg10=0.00 avg60=0.00 avg300=0.00

    PID   OOM    ADJ  RSS MiB  COMANDO
   2565   800    200      8.4  xfconfd
    570   800    200      6.0  dconf-service
    537   800    200      4.7  gpg-agent
    526   800    200      6.6  at-spi2-registr
    516   800    200      2.6  dbus-broker

$ riesgo-oom -n 5   (stress-ng usando 512 MiB)
Memoria disponible: 3033 MiB
PSI memoria 'some': avg10=0.00 avg60=0.00 avg300=0.00

    PID   OOM    ADJ  RSS MiB  COMANDO
   2749  1355   1000    337.2  stress-ng-vm
   2565   800    200      8.4  xfconfd
    ...

$ riesgo-oom -n 5   (un sleep con oom_score_adj = 500)
Memoria disponible: 2961 MiB
PSI memoria 'some': avg10=0.00 avg60=0.00 avg300=0.00

    PID   OOM    ADJ  RSS MiB  COMANDO
   2749  1360   1000    399.2  stress-ng-vm
   2751  1000    500      4.0  sleep
    ...
```

Dos hallazgos reales que no estaban anticipados: (1) todos los procesos de sesión en reposo (`xfconfd`, `dconf-service`, `gpg-agent`, `at-spi2-registr`, `dbus-broker`) ya traían `ADJ=200` de fábrica — algo en la sesión de usuario de systemd/XFCE les pone ese ajuste por defecto, no es 0 como cabría esperar sin configuración previa. (2) `stress-ng-vm` aparece con `ADJ=1000` desde que arranca, sin que el script lo haya tocado: `stress-ng` se pone ese ajuste a sí mismo a propósito, para ser la primera víctima del OOM killer si la presión real llegara a activarlo, en vez de arriesgar otros procesos del sistema. El caso más claro de lo que hace `oom_score_adj` es el `sleep`: con apenas 4 MiB de RSS llega al tope de 1000 solo por el ajuste manual, muy por encima de procesos que usan mucha más memoria real pero sin ese ajuste.

---

## `servicios-limites`

**Qué hace.** Para cada servicio de systemd corriendo, muestra los límites que el kernel le aplica de verdad (no solo lo que dice la unidad) y cuánto lleva usando. Es el Tema 4 visto desde dentro: `CPUQuota=` se convierte en `cpu.max` y `MemoryMax=` en `memory.max` dentro del cgroup del servicio. La columna `FRENADO` es `nr_throttled`, las veces que el kernel frenó al servicio por pasarse de su cuota de CPU.

**Uso:**

```bash
servicios-limites        # solo servicios con algún límite
servicios-limites -a     # todos los servicios
```

**Interfaces del SO:**

- `/sys/fs/cgroup/system.slice/<servicio>/cpu.max` — cuota de CPU (`<quota> <periodo>` en µs, o `max` si no hay límite).
- `/sys/fs/cgroup/system.slice/<servicio>/memory.max` — tope de memoria en bytes, o `max`.
- `/sys/fs/cgroup/system.slice/<servicio>/memory.current` — uso actual de memoria del cgroup.
- `/sys/fs/cgroup/system.slice/<servicio>/cpu.stat` — campo `nr_throttled`, veces que el kernel frenó al cgroup por exceder su cuota.

**Ejemplo** (de `docs/logs/capa3/servicios-limites.txt`, con un servicio transitorio de prueba: `sudo systemd-run --unit=prueba-limites -p CPUQuota=20% -p MemoryMax=128M sh -c 'while :; do :; done'`):

```
$ servicios-limites
SERVICIO                              CPU  MEM USADA   MEM MAX  FRENADO
prueba-limites.service               20 %    0.4 MiB   128 MiB       83

$ servicios-limites -a
SERVICIO                              CPU  MEM USADA   MEM MAX  FRENADO
NetworkManager.service             sin límite   16.6 MiB sin límite        0
dbus-broker.service                sin límite    3.0 MiB sin límite        0
...
prueba-limites.service               20 %    0.4 MiB   128 MiB       84
...
```

`FRENADO` subió de 83 a 84 entre las dos llamadas (unos segundos aparte): un bucle `while :; do :; done` sin ningún límite saturaría un núcleo al 100 %, así que con `CPUQuota=20%` el kernel tiene que frenarlo decenas de veces por segundo para mantenerlo en el 20 % — el contador no es simbólico, refleja intervención real y constante del *CFS bandwidth controller*. Tras `sudo systemctl stop prueba-limites`, correr `servicios-limites` sin `-a` vuelve a imprimir "(ningún servicio activo tiene límites; use -a para ver todos)".

Las unidades del Tema 4 (`arenalos-memlog.service`) usan los mismos mecanismos: `CPUQuota=20%` y `MemoryMax=128M` en `systemd/install.sh` son exactamente los valores que `servicios-limites` leería de su cgroup mientras esté activo — solo que, al ser `oneshot`, normalmente dura muy poco para alcanzar a capturarlo con este comando (de ahí usar un servicio transitorio para la demostración).

---

## `ipc-activo`

### Qué hace
Inspecciona en tiempo real los canales de comunicación entre procesos (IPC) abiertos en el sistema:
1. **Sockets de dominio Unix:** canales bidireccionales basados en el sistema de archivos o espacio abstracto (`AF_UNIX`) que permiten comunicar procesos locales sin pasar por la pila de red TCP/IP.
2. **Pipes anónimos:** canales unidireccionales de flujo de bytes gestionados en memoria por el kernel entre procesos emparentados (como tuberías de shell o comunicación padre-hijo).
3. **Memoria compartida (System V y POSIX):** regiones de memoria RAM mapeadas simultáneamente en el espacio de direcciones de varios procesos para intercambio directo de datos sin copias intermedias.

### Uso
```bash
ipc-activo [-n CUANTOS]
sudo ipc-activo -n 5
```

### Interfaces del SO
- `/proc/net/unix`: lee la tabla de sockets Unix activos del kernel, filtrando la bandera hexadecimal `0x10000` (`SO_ACCEPTCON`) para identificar cuáles están en estado `listen()` y obtener su número de inodo y ruta.
- `/proc/<pid>/fd`: inspecciona los enlaces simbólicos `socket:[inodo]` y `pipe:[inodo]` de cada proceso activo junto con `/proc/<pid>/comm` para asociar cada canal con su proceso propietario.
- `/proc/sysvipc/shm`: contabiliza los segmentos de memoria compartida System V registrados en el kernel.
- `/dev/shm`: lista los objetos de memoria compartida POSIX (`shm_open`) alojados en `tmpfs`.

### Ejemplo
```text
$ ipc-activo -n 5 (en reposo)
== Sockets Unix: 297 en total, 63 esperando conexiones ==
  systemd(1)                   /etc/pacman.d/gnupg/S.dirmngr
  systemd(1)                   /etc/pacman.d/gnupg/S.gpg-agent
  systemd(1)                   /etc/pacman.d/gnupg/S.gpg-agent.browser
  systemd(1)                   /etc/pacman.d/gnupg/S.gpg-agent.extra
  systemd(1)                   /etc/pacman.d/gnupg/S.gpg-agent.ssh

== Procesos con más pipes abiertos (de 25 procesos) ==
  Xorg(346)                    10 pipes
  sudo(966)                    6 pipes
  sudo(972)                    6 pipes
  sudo(970)                    5 pipes
  sddm(344)                    4 pipes

== Memoria compartida ==
  System V (/proc/sysvipc/shm): 5 segmentos
  POSIX (/dev/shm): 0 objetos

$ ipc-activo -n 5 (con un socket que escucha, un pipe y memoria compartida)
== Sockets Unix: 298 en total, 64 esperando conexiones ==
  systemd(1)                   /etc/pacman.d/gnupg/S.dirmngr
  systemd(1)                   /etc/pacman.d/gnupg/S.gpg-agent
  systemd(1)                   /etc/pacman.d/gnupg/S.gpg-agent.browser
  systemd(1)                   /etc/pacman.d/gnupg/S.gpg-agent.extra
  systemd(1)                   /etc/pacman.d/gnupg/S.gpg-agent.ssh

== Procesos con más pipes abiertos (de 28 procesos) ==
  Xorg(346)                    10 pipes
  sudo(982)                    6 pipes
  sudo(984)                    6 pipes
  sudo(970)                    5 pipes
  sddm(344)                    4 pipes

== Memoria compartida ==
  System V (/proc/sysvipc/shm): 6 segmentos
  POSIX (/dev/shm): 1 objetos
```

---

## `arranque-info`

### Qué hace
Presenta en una sola vista el diagnóstico del proceso de arranque siguiendo la secuencia jerárquica estudiada en el Tema 7: **firmware UEFI $\rightarrow$ gestor de arranque (`systemd-boot`) $\rightarrow$ kernel Linux $\rightarrow$ `systemd` (`initrd` + `userspace` y `target` por defecto)**.

### Uso
```bash
arranque-info
```

### Interfaces del SO
- `/sys/firmware/efi` y `/sys/firmware/efi/efivars/LoaderInfo-*`: comprueba si la máquina arrancó en modo UEFI (en lugar de BIOS legacy) y decodifica en UTF-16LE el nombre y versión del gestor de arranque (`systemd-boot`).
- `/proc/cmdline`: muestra la línea exacta de parámetros entregada por el bootloader al kernel (`initrd`, `root=UUID=...`).
- `/proc/uptime`: lee los segundos transcurridos desde el inicio del sistema para calcular horas y minutos encendidos.
- `systemctl get-default` y `systemd-analyze time`: consulta el *target* objetivo por defecto (`graphical.target`) y el desglose de tiempos de arranque del *kernel*, *initrd* y *userspace*.

### Ejemplo
```text
$ arranque-info
Modo de firmware: UEFI
Gestor de arranque: systemd-boot 262.2-1-arch
Parámetros del kernel: initrd=\initramfs-linux-lts.img root=UUID=33a26f4a-4658-4c51-882a-e4df7858b8d2
Encendido hace: 0 h 10 min
Target por defecto: graphical.target
Fases del arranque: Startup finished in 1.626s (kernel) + 1.571s (initrd) + 4.684s (userspace) = 7.882s 

$ bootctl status | head -n 12
System:
      Firmware: UEFI 2.70 (EDK II 1.00)
 Firmware Arch: x64
   Secure Boot: disabled (setup)
  TPM2 Support: no
  Measured UKI: no
   Measured OS: no
  Boot into FW: supported
 Platform Lang: n/a

Current Boot Loader:
        Product: systemd-boot 262.2-1-arch

$ cat /proc/cmdline
initrd=\initramfs-linux-lts.img root=UUID=33a26f4a-4658-4c51-882a-e4df7858b8d2

$ systemd-analyze time
Startup finished in 1.626s (kernel) + 1.571s (initrd) + 4.684s (userspace) = 7.882s 
graphical.target reached after 4.682s in userspace.

$ systemctl get-default
graphical.target
```

---

## usb-historial

**Qué hace.** Muestra los dispositivos USB conectados en este momento (puerto, `vendor:product`, velocidad, driver y, si es un almacenamiento, el disco y dónde está montado con qué opciones). También muestra el historial de conexiones y desconexiones que registra la regla udev del Tema 8, con un conteo por dispositivo.

**Uso.**
```
usb-historial          # dispositivos actuales + últimas 10 líneas del historial
usb-historial -n 30    # últimas 30 líneas del historial
usb-historial -h       # ayuda
```

**Interfaces del SO.**
- `/sys/bus/usb/devices/*/{idVendor,idProduct,speed,manufacturer,product,bDeviceClass}`: atributos que el kernel publica por cada dispositivo USB (se omiten los hubs, clase `09`).
- `/sys/bus/usb/devices/<dev>/<dev>:<if>/driver`: qué driver tomó cada interfaz (`usb-storage`, `usbhid`…).
- `/sys/block/*/device`: enlace simbólico que permite saber de qué dispositivo USB cuelga cada disco.
- `/proc/mounts`: punto de montaje y opciones (`ro,nosuid,nodev,noexec`).
- `/var/log/arenalos-usb.log`: escrito por `arenalos-usb-handler` (Tema 8).

**Ejemplo** (salida real, [`docs/logs/esteban/tema-09/10-comando-usb-historial.txt`](logs/esteban/tema-09/10-comando-usb-historial.txt)):
```
PUERTO  ID         VELOC.    DISPOSITIVO                 DRIVER / DISCO
1-1     80ee:0021  12M       VirtualBox USB Tablet       usbhid
3-1     0951:1666  5000M     Kingston DataTraveler 3.0   usb-storage | /dev/sdb /dev/sdb1 -> /media/usb-sdb1 (ro,nosuid,nodev,noexec,...)
```

---

## puertos-abiertos

**Qué hace.** Lista los puertos TCP y UDP en los que la máquina está escuchando, qué proceso es dueño de cada uno y si el firewall nftables **deja pasar** conexiones a ese puerto, lo bloquea o si el puerto solo escucha en loopback. Sirve para auditar rápidamente la superficie expuesta: "¿qué servicios tengo abiertos y cuáles de ellos son alcanzables desde la red?".

**Uso.**
```
sudo puertos-abiertos  # completo (procesos de todos los usuarios + firewall)
puertos-abiertos       # sin root: lista los puertos, pero no puede ver procesos ajenos ni el firewall
puertos-abiertos -h    # ayuda
```

**Interfaces del SO.**
- `/proc/net/tcp`, `tcp6`, `udp`, `udp6`: tabla de sockets del kernel. Las direcciones y puertos vienen en hexadecimal (IPv4 en *little-endian*). El estado `0A` es `LISTEN` en TCP, y `07` es un socket UDP sin conectar.
- `/proc/<pid>/fd/*`: cada descriptor que es un socket apunta a `socket:[<inodo>]`. El inodo se cruza con el de `/proc/net/*` para saber qué proceso tiene el puerto, y el nombre sale de `/proc/<pid>/comm`.
- `nft list ruleset` (netfilter): si la cadena `input` tiene `policy drop`, se extraen los puertos con `tcp/udp dport … accept`.

**Ejemplo** (salida real, [`docs/logs/esteban/tema-09/09-comando-puertos-abiertos.txt`](logs/esteban/tema-09/09-comando-puertos-abiertos.txt)):
```
PROTO PUERTO ESCUCHA EN    PROCESO(PID)           FIREWALL
tcp   22     0.0.0.0       sshd(307)              PERMITIDO
tcp6  22     ::            sshd(307)              PERMITIDO
tcp6  8080   ::            systemd-socket-(443)   bloqueado (drop)
```
