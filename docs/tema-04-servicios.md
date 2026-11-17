# Tema 4 · Gestión de servicios

Responsable: Rafael Odio (apoyo: Esteban)

## 1. Qué se implementó

- `systemd/arenalos-memlog.service` + `systemd/arenalos-memlog.timer`: un servicio que reutiliza la herramienta del Tema 2 (`src/memoria/memoria.py`) en vez de inventar algo sin relación. Cada vez que se activa, toma 5 muestras de memoria/swap/zram separadas por 1 s y las agrega a `/var/log/arenalos-memlog.log`, construyendo un historial ligero útil para diagnosticar presión de memoria después del hecho (por ejemplo, para correlacionar con el experimento del Tema 2).
- `systemd/arenalos-memlog.sh`: el script que corre el `ExecStart`, instalado en `/usr/local/bin/arenalos-memlog`.
- `systemd/install.sh`: instalador idempotente que genera el unit (con `Environment=REPO_DIR=...` resuelto a la ruta real del repositorio en esta máquina), instala el timer, recarga `systemd` y habilita el timer.
- El unit usa `Type=oneshot` activado por el timer cada 2 minutos (`OnUnitActiveSec=2min`), con `Restart=on-failure`, `CPUQuota=20%` y `MemoryMax=128M`.

## 2. Concepto de Sistemas Operativos

**Unidades de systemd y control de recursos con cgroups.** systemd administra servicios como *units*; un `.service` describe cómo arrancar/detener un proceso y un `.timer` lo activa según un calendario, en vez de depender de un demonio siempre corriendo (una alternativa más liviana a dejar un proceso en bucle con `sleep`). Cada servicio corre dentro de un **cgroup** (control group) propio bajo `/sys/fs/cgroup/system.slice/<unit>.service/`; ahí es donde el kernel aplica límites reales, no solo informativos: `memory.max` (de `MemoryMax=`) hace que el kernel mate o bloquee al proceso si intenta pasarse, y `cpu.max` (de `CPUQuota=`) limita el porcentaje de tiempo de CPU que puede consumir en cada período, sin importar cuántos procesos hijos abra (el cgroup agrupa a todos).

**`Restart=` y recuperación de fallas.** systemd distingue cómo termina un proceso: una salida limpia (`exit 0`) no es una falla; una señal (como `SIGKILL`, código 9) o una salida con código distinto de cero sí lo son. Con `Restart=on-failure`, systemd reacciona solo ante esas terminaciones anormales y programa un reinicio automático (`RestartSec=` es la espera antes de reintentar), independientemente de si la unidad fue activada por un timer o a mano. Esto es lo que permite que matar el proceso en pleno ciclo con `kill -9` dispare un reinicio inmediato sin esperar al siguiente disparo del timer.

**Referencias:**

- Silberschatz, A., Galvin, P. B. y Gagne, G. *Operating System Concepts*, 10.ª edición, Wiley. Capítulo 3, «Processes», sección sobre terminación y señales; y el tratamiento de contenedores/cgroups en el capítulo sobre virtualización.
- Arch Wiki: *systemd*, *systemd/Timers* y *Resource-management with systemd* (CPUQuota, MemoryMax y su relación con `cgroup v2`).
- Documentación del kernel: `Documentation/admin-guide/cgroup-v2.rst`, secciones de los controladores `memory` y `cpu`.
- Páginas del manual: `systemd.service(5)`, `systemd.timer(5)`, `systemd.resource-control(5)` (`CPUQuota=`, `MemoryMax=`), `systemd.exec(5)` (`Restart=`).

## 3. Método de medición

**Entorno.** VM `ArenalOS-Rafael`, kernel 6.18.63-3-lts con `cgroup v2`, mismas condiciones que el Tema 2.

**Instalación** (parte de `sudo bash install.sh`, que invoca `systemd/install.sh`):

```bash
sudo bash systemd/install.sh
systemctl status arenalos-memlog.timer
systemctl list-timers arenalos-memlog.timer
```

**Ejecuciones periódicas** (revisión de `journalctl -u`):

```bash
journalctl -u arenalos-memlog.service --no-pager
cat /var/log/arenalos-memlog.log
```

**Cuota aplicada** (el unit es `oneshot` y dura ~5-6 s; para capturar el cgroup mientras existe hay que lanzarlo en segundo plano):

```bash
sudo systemctl start arenalos-memlog.service &
sleep 1
systemd-cgls /system.slice/arenalos-memlog.service
cat /sys/fs/cgroup/system.slice/arenalos-memlog.service/memory.max
cat /sys/fs/cgroup/system.slice/arenalos-memlog.service/cpu.max
wait
```

**Falla provocada:**

```bash
sudo systemctl start arenalos-memlog.service &
sleep 1
PID=$(systemctl show arenalos-memlog.service -p MainPID --value)
sudo kill -9 "$PID"
sleep 3
journalctl -u arenalos-memlog.service --no-pager | tail -20
systemctl status arenalos-memlog.service
```

## 4. Resultados

### 4.1 Timer y ejecuciones periódicas

```
● arenalos-memlog.timer - Ejecuta arenalos-memlog cada 2 minutos
     Active: active (waiting)
    Trigger: ... 26s left
   Triggers: ● arenalos-memlog.service
```

`journalctl -u arenalos-memlog.service` muestra ejecuciones automáticas cada ~2 minutos sin intervención (14:21:07, 14:22:51, 14:25:26, 14:26:30...), cada una completando las 5 muestras y terminando con `Deactivated successfully`. `/var/log/arenalos-memlog.log` acumula los bloques de 5 muestras de `memoria.py` por cada corrida, confirmando que el servicio hace lo que promete, no solo que "corre".

### 4.2 Cgroup y cuota aplicada

```
CGroup /system.slice/arenalos-memlog.service:
├─2198 /bin/bash /usr/local/bin/arenalos-memlog
└─2200 sleep 1

memory.max: 134217728
cpu.max:    20000 100000
```

`134217728` bytes = 128 MiB exactos (`MemoryMax=128M`) y `20000 100000` significa 20 000 µs de cada período de 100 000 µs = 20 % (`CPUQuota=20%`). Ambos archivos viven en el cgroup real del proceso, no son solo lo que dice la unidad: son los límites que el kernel aplica.

### 4.3 Falla provocada y reinicio automático

```
Nov 17 14:28:34 ... Starting Snapshot periodico de memoria/swap/zram (Tema 2 -> Tema 4)...
Nov 17 14:28:35 ... arenalos-memlog.service: Main process exited, code=killed, status=9/KILL
Nov 17 14:28:35 ... arenalos-memlog.service: Failed with result 'signal'.
Nov 17 14:28:35 ... Failed to start Snapshot periodico de memoria/swap/zram (Tema 2 -> Tema 4).
Nov 17 14:28:37 ... arenalos-memlog.service: Scheduled restart job, restart counter is at 1.
Nov 17 14:28:37 ... Starting Snapshot periodico de memoria/swap/zram (Tema 2 -> Tema 4)...
```

Y `systemctl status` justo después muestra una unidad nueva y activa, con un PID distinto (2253, no el que se mató) y el mismo cgroup con los mismos límites (`Memory: 800K (max: 128M...)`). El reinicio ocurrió 2 s después de la señal (`RestartSec=2`), sin esperar al siguiente disparo del timer (el próximo estaba a más de un minuto).

## 5. Interpretación

El `kill -9` confirma la diferencia entre terminación normal y anormal que explica la teoría: cuando el script termina solo (las 5 muestras completas, `exit 0`), systemd no reinicia nada — es el comportamiento correcto para un `oneshot` disparado por timer. Pero cuando se le manda `SIGKILL` a mitad de corrida, systemd lo clasifica como falla (`Failed with result 'signal'`) y, por tener `Restart=on-failure`, lo vuelve a arrancar de inmediato, dándole al servicio una forma de recuperarse de una caída sin depender de que alguien lo note o de esperar al siguiente ciclo del timer.

Los límites de recursos no son solo configuración declarada: `cat` sobre los archivos reales del cgroup (`memory.max`, `cpu.max`) muestra que el kernel efectivamente los tiene cargados para ese proceso específico, y `systemd-cgls` confirma que tanto el script como su `sleep` hijo quedan agrupados bajo el mismo cgroup — si el script abriera más procesos, todos compartirían la misma cuota de CPU y memoria, no cada uno por separado.

Elegir un timer en vez de un servicio persistente (`Type=simple` en bucle) fue deliberado: para una tarea que solo necesita correr periódicamente y terminar, un `oneshot` + timer es más barato (no hay proceso ocioso entre corridas) y sigue permitiendo la misma recuperación ante fallas, porque `Restart=` no depende de cómo se disparó la unidad.
