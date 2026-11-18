# Comandos de Rafael (Temas 2 y 4)

| Comando | Autor | Interfaces del SO | Tema relacionado |
|---|---|---|---|
| [`riesgo-oom`](#riesgo-oom) | Rafael Odio | `/proc/<pid>/oom_score`, `/proc/<pid>/oom_score_adj`, `/proc/<pid>/status`, `/proc/pressure/memory` | T2 |
| [`servicios-limites`](#servicios-limites) | Rafael Odio | cgroups v2: `/sys/fs/cgroup/system.slice/*.service/{cpu.max,memory.max,memory.current,cpu.stat}` | T4 |

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
