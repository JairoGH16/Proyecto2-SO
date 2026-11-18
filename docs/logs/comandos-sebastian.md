# Comandos de Sebastián (Temas 5 y 7)

| Comando | Autor | Interfaces del SO | Tema relacionado |
|---|---|---|---|
| [`ipc-activo`](#ipc-activo) | Sebastián | `/proc/net/unix`, `/proc/<pid>/fd`, `/proc/sysvipc/shm`, `/dev/shm` | T5 |
| [`arranque-info`](#arranque-info) | Sebastián | `/sys/firmware/efi`, `/proc/cmdline`, `/proc/uptime`, systemd (`systemctl`, `systemd-analyze`) | T7 |

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