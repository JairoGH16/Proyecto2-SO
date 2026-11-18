# Tema 2 · Memoria

Responsable: Rafael Odio (apoyo: Jairo)

## 1. Qué se implementó

- `src/memoria/install.sh` + `src/memoria/zram-generator.conf`: instalador idempotente que
  - crea `/swapfile` (4 GiB, `chmod 600`, `mkswap`) y lo agrega a `/etc/fstab` con `pri=10`;
  - instala `zram-generator` y su configuración (`zram0`, tamaño `ram/2`, compresión `zstd`, `swap-priority=100`), para que el kernel prefiera zram (comprimido, en RAM) antes de tocar el swapfile en disco.
- `src/memoria/memoria.py`: herramienta en Python 3 (solo biblioteca estándar) que, en tiempo real,
  - lee memoria física de `/proc/meminfo` (total, libre, disponible, caché);
  - lee swap por dispositivo desde `/proc/swaps` (distingue `/dev/zram0` de `/swapfile`, con su prioridad);
  - calcula la tasa de compresión de zram desde `/sys/block/zram0/mm_stat`;
  - lista los procesos con más fallos de página mayores y menores, leyendo los campos `minflt`/`majflt` de `/proc/PID/stat`.
- `scripts/experimento-memoria.sh`: automatiza el experimento de presión con `stress-ng --vm`, registrando antes y después `free`, `swapon --show` y una muestra de `memoria.py`, además de `vmstat` durante toda la corrida y cualquier evento de OOM killer en `dmesg`.

## 2. Concepto de Sistemas Operativos

**Memoria virtual, paginación por demanda y swapping.** Cada proceso ve un espacio de direcciones virtual que el kernel traduce a páginas físicas (típicamente 4 KiB). Con paginación por demanda, una página se trae a RAM solo cuando el proceso realmente la toca (fallo de página). Un **fallo menor** (`minflt`) ocurre cuando la página ya está en memoria física pero no mapeada en la tabla de páginas del proceso (por ejemplo, páginas compartidas o recién reservadas con `mmap`): se resuelve sin tocar disco. Un **fallo mayor** (`majflt`) ocurre cuando la página hay que traerla desde el dispositivo de swap (o desde un archivo mapeado): es mucho más costoso porque implica E/S.

Cuando la memoria física se agota, el kernel elige páginas para liberar (la política de reemplazo, aproximando LRU) y las escribe a swap si están sucias (**swap-out**); cuando el proceso vuelve a tocarlas, se leen de vuelta (**swap-in**, el fallo mayor). Linux permite varios dispositivos de swap simultáneos con **prioridad**: a igual prioridad reparte round-robin, pero usa primero el de mayor prioridad. **zram** crea un bloque de swap respaldado por RAM comprimida (`zstd` en este caso): es mucho más rápido que un disco porque nunca sale del bus de memoria, a cambio de gastar CPU en comprimir/descomprimir. Por eso tiene sentido darle prioridad más alta que al swapfile: el kernel intenta primero el swap rápido y solo cae al disco cuando zram también se llena. Si la presión supera toda la memoria (RAM + swap disponible), el kernel invoca al **OOM killer**, que mata al proceso que estima más responsable para liberar memoria y evitar que el sistema se bloquee por completo.

**Referencias:**

- Silberschatz, A., Galvin, P. B. y Gagne, G. *Operating System Concepts*, 10.ª edición, Wiley. Capítulo 9, «Virtual Memory»: paginación por demanda (9.2), fallos de página (9.2.1) y algoritmos de reemplazo (9.4).
- Arpaci-Dusseau, R. H. y Arpaci-Dusseau, A. C. *Operating Systems: Three Easy Pieces*. Capítulo 22, «Beyond Physical Memory: Mechanisms», sobre swapping y el costo de traer páginas desde un dispositivo lento.
- Tanenbaum, A. S. y Bos, H. *Modern Operating Systems*, 5.ª edición, Pearson, 2023. Sección 3.4, «Page Replacement Algorithms», y 3.7 sobre el manejo de la presión de memoria.
- Documentación del kernel de Linux: `Documentation/admin-guide/blockdev/zram.rst` y `Documentation/admin-guide/mm/concepts.rst` (sección sobre swap y OOM killer).
- Páginas del manual: `proc(5)` (campos de `/proc/PID/stat`), `swapon(8)`, `mkswap(8)` y `zram-generator.conf(5)`.

## 3. Método de medición

**Entorno.** VM `ArenalOS-Rafael` (VirtualBox, UEFI), 4096 MB de RAM (3889 MB reportados por `free`), 2 vCPU, disco dinámico de 40 GB, Arch Linux kernel 6.18.63-3-lts. XFCE activo durante las pruebas (sin otras aplicaciones abiertas además de la terminal).

**Configuración aplicada** (vía `sudo bash install.sh`, que invoca `src/memoria/install.sh`):

```bash
swapon --show
# NAME       TYPE      SIZE USED PRIO
# /swapfile  file        4G   0B   10
# /dev/zram0 partition 1.9G   0B  100
```

**Monitor en reposo:**

```bash
sudo python3 src/memoria/memoria.py --once
```

**Experimento de presión**, con `stress-ng --vm 4 --vm-bytes 7G --vm-method all --timeout 60s` (7 GiB en total repartidos entre los 4 workers — por encima de los ~3,9 GiB de RAM, para forzar paginación real). Se corrió dos veces con `scripts/experimento-memoria.sh`, alternando si zram está activo o no:

```bash
sudo bash scripts/experimento-memoria.sh con-zram

sudo systemctl stop dev-zram0.swap      # desactiva zram, deja solo /swapfile
sudo bash scripts/experimento-memoria.sh sin-zram
sudo systemctl start dev-zram0.swap     # reactiva zram
```

Cada corrida registra `vmstat 1` durante toda la ventana de 60 s (columnas `swpd`, `si`, `so`), `free -m` y `swapon --show` antes/después, una muestra de `memoria.py --once` antes/después, el `mm_stat` de zram al final y `dmesg | grep -i oom`. Los logs completos están en `docs/logs/mediciones/experimento-memoria-con-zram.log` y `-sin-zram.log`.

**Nota metodológica:** se corrió el experimento una sola vez por configuración, no las 3 repeticiones recomendadas por el enunciado para mediciones en VM (ruidosas). Los resultados son consistentes y la diferencia entre ambas corridas es grande, pero repetir ayudaría a confirmar que no es ruido puntual — ver Limitaciones.

## 4. Resultados

### 4.1 Con zram activo

| Momento | Swap total usado | `/dev/zram0` | `/swapfile` | `stress-ng` bogo-ops completados | majflt de Xorg |
|---|---|---|---|---|---|
| Antes | 0 MB | 0 MB (pri 100) | 0 MB (pri 10) | — | 82 |
| Después | 120,2 MB | 99,9 MB | 20,3 MB | 7168 | 616 |

`vmstat` durante la corrida: `swpd` sube de 0 a un pico de **4 281 596 KB (~4,28 GB)** mientras la carga está activa, con `si`/`so` en 0 la mayor parte del tiempo (el movimiento hacia/desde zram, al ser en RAM, no siempre se refleja como E/S clásica de swap en estas columnas). `stress-ng` reporta **49,64 % de páginas intercambiadas** y termina sin errores.

### 4.2 Sin zram (solo swapfile)

| Momento | Swap total usado | `/swapfile` | `stress-ng` bogo-ops completados | majflt de Xorg |
|---|---|---|---|---|
| Antes | 18,7 MB | 18,7 MB (pri 10) | — | 795 |
| Después | 129,6 MB | 129,6 MB | **0** | **2643** |

`stress-ng` emitió una advertencia explícita: `all bogo-op counters are zero, data may be incorrect` — ningún worker terminó ni una sola iteración en los 60 s. `vmstat` muestra `swpd` subiendo de forma sostenida hasta **~3 587 036 KB (~3,59 GB)**, con columnas `bi` (bloques leídos del disco) frecuentemente en varios miles y el contador `b` (procesos bloqueados en E/S) en 1–2 varias veces, algo que no aparece en la corrida con zram.

### 4.3 Comparación

| Métrica | Con zram | Sin zram |
|---|---|---|
| Bogo-ops completados por `stress-ng` | 7168 | 0 |
| Swap usado al final | 120,2 MB (83 % en zram) | 129,6 MB (100 % swapfile) |
| majflt de Xorg (antes → después) | 82 → 616 (×7,5) | 795 → 2643 (×3,3, mismo total pero partiendo de una base ya más alta) |
| Procesos bloqueados (`b`) en `vmstat` | 0 en toda la corrida | hasta 2 |
| OOM killer | no | no |

Ningún evento de OOM en `dmesg` en ninguna de las dos corridas: la carga fue suficiente para forzar swap real, pero no para agotar RAM + swap disponible (6 GB con zram, 4 GB sin él).

## 5. Interpretación

La diferencia más clara es el throughput de `stress-ng`: con zram activo los workers lograron completar trabajo real (7168 bogo-ops) mientras el kernel paginaba de fondo; sin zram, el sistema quedó tan dominado por la E/S de swap al disco que **ningún worker completó una sola iteración** en el mismo minuto — el propio `stress-ng` lo marca como una corrida cuyos datos no son confiables, lo cual es en sí mismo evidencia de cuánto degrada el rendimiento el swap por disco puro. Esto coincide con la teoría: un fallo mayor que resuelve una página en zram solo implica descomprimir en RAM (latencia de microsegundos), mientras que uno que resuelve en el swapfile implica una operación de E/S real (mucho más lenta, incluso sobre el disco virtual de la VM).

La prioridad configurada (zram 100 > swapfile 10) se comportó como se esperaba: en la corrida con ambos activos, el 83 % del swap usado terminó en zram y solo el 17 % en el swapfile, confirmando que el kernel prefiere el dispositivo de mayor prioridad y solo recurre al de menor prioridad cuando el primero no alcanza.

Los fallos de página mayores de los procesos de escritorio (Xorg, xfwm4, xfce4-terminal) subieron considerablemente en ambas corridas porque sus páginas fueron las elegidas para liberar espacio durante la presión y tuvieron que volver a traerse de swap una vez que `stress-ng` terminó y la memoria volvió a estar disponible; el salto es mayor en la corrida sin zram, consistente con una resolución de fallos más lenta y con más páginas acumuladas esperando regresar.

**Limitaciones:** una sola repetición por configuración (no las 3 recomendadas para mediciones en VM), por lo que no se puede descartar variación entre corridas; el valor final de `mm_stat` de zram no coincide con el 99,9 MB visto en `swapon --show` segundos antes, porque el kernel ya había liberado buena parte del swap para cuando se leyó ese archivo — es una limitación del orden de medición del script, no del mecanismo de zram en sí.
