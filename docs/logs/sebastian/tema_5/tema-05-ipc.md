# Tema 5 · Concurrencia e IPC

## 1. Qué se implementó
Se desarrolló en C (`src/ipc/ipc_collector.c`) un recolector y procesador concurrente de telemetría del sistema bajo el esquema **productor/consumidor**:
- **Productor (proceso padre):** Lee métricas reales desde `/proc/loadavg` y `/proc/meminfo` y las envía a través de un **pipe anónimo** (`pipe()`).
- **Consumidores (procesos hijos creados con `fork()`):** Leen paquetes desde el pipe y actualizan un búfer circular de 16 posiciones y contadores globales alojados en **memoria compartida POSIX** (`shm_open()` + `mmap(..., MAP_SHARED)`).
- **Sincronización explícita:** Semáforo POSIX sin nombre (`sem_init(&shm->mutex, 1, 1)`) alojado dentro de la región compartida entre procesos, acompañado de la bandera `--no-sync` para desactivarlo y reproducir condiciones de carrera.
- **Manejo de señales:** Manejadores instalados mediante `sigaction()` para `SIGTERM`/`SIGINT` (detención controlada, cierre de descriptores y `shm_unlink`) y `SIGCHLD` (recolección asíncrona con `waitpid(-1, NULL, WNOHANG)` para impedir procesos *zombie*).

## 2. Concepto de SO
- **Comunicación entre procesos (IPC):** Los *pipes* anónimos proveen un canal unidireccional basado en flujo de bytes con sincronización implícita de lectura/escritura administrada por el kernel. Por su parte, la memoria compartida POSIX (`shm_open` + `mmap`) mapea las mismas páginas físicas de RAM en el espacio de direcciones de múltiples procesos, permitiendo intercambio de estructuras sin copias intermedias entre espacio de usuario y kernel.
- **Exclusión mutua y condición de carrera:** Cuando múltiples procesos leen, modifican y escriben variables compartidas (`total_processed`, `head`, `load_accumulator`) sin bloqueo, el planificador puede intercalar sus ejecuciones en medio de la sección crítica (*lost update*). El semáforo binario garantiza acceso exclusivo y atómico.
- **Señales y ciclo de vida de procesos:** Al finalizar un proceso hijo, el kernel conserva su entrada en la tabla de procesos en estado `Z` (*zombie*) hasta que el padre recoge su código de salida con `waitpid()`. Capturar `SIGCHLD` permite recolectar procesos hijos en cuanto terminan sin bloquear el flujo principal del productor.

## 3. Método
1. **Prueba de condición de carrera:** Se ejecutaron 5 corridas con sincronización activa (`./ipc_collector --events 2000 --workers 4`) y 5 corridas con sincronización desactivada (`./ipc_collector --no-sync --events 2000 --workers 4`), registrando eventos enviados, contabilizados en memoria compartida y perdidos, junto con su promedio y desviación estándar.
2. **Traza de llamadas al sistema:** Se ejecutó `strace -f -e trace=clone,clone3,pipe,pipe2,openat,mmap,kill,wait4 ./ipc_collector --events 20 --workers 2` para inspeccionar las *syscalls* ejecutadas por el padre y los procesos hijos.
3. **Prueba de señales y ausencia de zombies:** Se ejecutó `./ipc_collector --events 5000 --workers 4 --delay-us 2000` en segundo plano; primero se envió `SIGTERM` a un trabajador hijo individual para verificar su recolección inmediata por `SIGCHLD`, y luego se envió `SIGTERM` al proceso padre comprobando el estado de procesos con `ps -eo pid,ppid,stat,comm` y la limpieza de `/dev/shm`.

## 4. Resultados

### 4.1 Comparación con sincronización vs. sin sincronización (2000 eventos, 4 trabajadores)
| Corrida | Con `sem_t` (Registrados) | Con `sem_t` (Perdidos) | Sin sincronización (Registrados) | Sin sincronización (Perdidos) |
| :--- | :---: | :---: | :---: | :---: |
| 1 | 2000 | 0 | 527 | 1473 |
| 2 | 2000 | 0 | 915 | 1085 |
| 3 | 2000 | 0 | 1167 | 833 |
| 4 | 2000 | 0 | 387 | 1613 |
| 5 | 2000 | 0 | 592 | 1408 |
| **Promedio** | **2000.0** | **0.0** | **717.6** | **1282.4** |
| **Desv. estándar ($s$)** | **0.0** | **0.0** | **317.15** | **317.15** |

### 4.2 Traza de llamadas al sistema (`strace -f`)
```text
openat(AT_FDCWD, "/dev/shm/arenalos_ipc_telemetry", O_RDWR|O_CREAT|O_EXCL|O_NOFOLLOW|O_CLOEXEC, 0600) = 3
mmap(NULL, 432, PROT_READ|PROT_WRITE, MAP_SHARED, 3, 0) = 0x7f8bb35e6000
pipe2([3, 4], 0)                        = 0
clone(child_stack=NULL, flags=CLONE_CHILD_CLEARTID|CLONE_CHILD_SETTID|SIGCHLDstrace: Process 1123 attached
[pid  1122] clone(child_stack=NULL, flags=CLONE_CHILD_CLEARTID|CLONE_CHILD_SETTID|SIGCHLDstrace: Process 1124 attached
[pid  1122] wait4(-1 <unfinished ...>
[pid  1122] <... wait4 resumed>, NULL, 0, NULL) = 1124
[pid  1122] wait4(-1, NULL, WNOHANG, NULL) = 0
wait4(-1, NULL, WNOHANG, NULL)          = 1123
wait4(-1, NULL, WNOHANG, NULL)          = -1 ECHILD (No child processes)
wait4(-1, NULL, 0, NULL)                = -1 ECHILD (No child processes)
```

### 4.3 Manejo de señales (`SIGCHLD` / `SIGTERM`), `ps` y `/dev/shm`
```text
Terminando trabajador hijo PID=1144 mientras el padre (1142) sigue activo...
--- ps tras terminar el hijo (sin procesos en estado Z) ---
    PID    PPID STAT COMMAND
   1142    1140 S+   ipc_collector
   1145    1142 S+   ipc_collector
   1146    1142 S+   ipc_collector
   1147    1142 S+   ipc_collector
Enviando SIGTERM al proceso padre PID=1142...
[Productor PID=1142] Iniciando 4 consumidores | Eventos=5000 | Sincronizacion=ACTIVA (sem_t)
[Resultado] Enviados=563 | Registrados en SHM=563 | Perdidos=0 | Hijos recolectados=4
[Telemetria] Carga promedio 1m=0.03 | Ultima MemAvailable=3363768 kB
--- ps tras SIGTERM al padre ---
    PID    PPID STAT COMMAND
--- Verificacion de shm_unlink en /dev/shm ---
total 0
drwxrwxrwt  2 root root   40 Nov 17 15:45 .
drwxr-xr-x 19 root root 3740 Nov 17 15:27 ..
```

## 5. Interpretación
- **Efectividad de la sincronización:** Con `sem_t` activo, el 100 % de los 2000 paquetes enviados se contabilizaron sin pérdidas en las 5 repeticiones. Al desactivar el semáforo (`--no-sync`), se perdió un promedio de **1282.4 eventos (64.12 %)** con alta dispersión ($s = 317.15$), porque los cuatro consumidores leyeron simultáneamente el mismo valor de `shm->total_processed` antes de incrementarlo, pisando las actualizaciones concurrentes.
- **Verificación a nivel de kernel (`strace`):** La traza confirma la apertura del segmento compartido de 432 bytes mediante `openat()` + `mmap(..., MAP_SHARED)`, la creación del canal unidireccional con `pipe2()`, la bifurcación de trabajadores mediante `clone(..., SIGCHLD)` y su recolección con `wait4()` hasta recibir `ECHILD`.
- **Resiliencia ante señales:** Al matar al hijo `1144`, el manejador de `SIGCHLD` en el padre (`1142`) lo recolectó de inmediato sin dejar ninguna entrada en estado `Z`, mientras los tres trabajadores restantes (`1145`–`1147`) continuaron procesando hasta completar exactamente los `563` eventos enviados antes del `SIGTERM` al padre (`Hijos recolectados=4`). Finalmente, `/dev/shm` quedó vacío (`total 0`), confirmando la liberación del recurso compartido.