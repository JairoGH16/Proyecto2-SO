# Tema 1 · Procesos y planificación

Responsable: Jairo González Hidalgo

## 1. Qué se implementó

- `src/procesos/procesos.py`: herramienta en Python 3 (solo biblioteca estándar) que
  - lista procesos leyendo `/proc/PID/stat` (PID, PPID, estado, nice, política de planificación y %CPU calculado con dos muestras separadas por un intervalo);
  - cambia el valor nice de un proceso con `setpriority` (`--nice PID VALOR`);
  - cambia la política de planificación con `sched_setscheduler` (`--politica PID POL [--prio N]`, con `other`, `batch`, `idle`, `fifo` y `rr`).
- `scripts/experimento-nice.sh`: lanza procesos que solo giran, fijados a un mismo núcleo con `taskset`, cada uno con un nice distinto, y compara el reparto medido de CPU con el que predice la tabla de pesos del kernel.
- `scripts/experimento-rt.sh`: enfrenta un proceso normal (nice 0) contra uno `SCHED_FIFO` en el mismo núcleo.

## 2. Concepto de Sistemas Operativos

**Planificación de CPU.** El planificador decide qué proceso listo ocupa la CPU y por cuánto tiempo. En Linux, los procesos normales (`SCHED_OTHER`) los planifica **EEVDF** (Earliest Eligible Virtual Deadline First), que reemplazó al planificador CFS en el kernel 6.6. En este sistema el kernel es 6.18.62-1-lts, por lo que se usa EEVDF.

- **Peso por nice.** Cada proceso normal tiene un peso derivado de su valor nice mediante la tabla `sched_prio_to_weight` del kernel: nice 0 pesa 1024, nice 5 pesa 335 y nice 10 pesa 110. Cada paso de nice cambia el peso en un factor aproximado de 1,25.
- **Reparto proporcional.** A largo plazo, un proceso que compite por la misma CPU recibe la fracción `peso / suma de pesos de los procesos que compiten`. Con nice 0 y 10 la teoría predice 1024 / (1024 + 110) = 90,3 % y 9,7 %.
- **Cómo lo logra EEVDF (resumen).** Cada proceso acumula cuánto tiempo de CPU se le debe respecto de lo que le correspondería según su peso; el kernel escoge, entre los procesos que ya tienen derecho a correr (elegibles), al que tiene el plazo virtual más cercano. Un peso mayor hace que el plazo avance más lento y que el proceso corra más seguido.
- **Políticas de tiempo real.** `SCHED_FIFO` y `SCHED_RR` van antes que cualquier proceso normal y se ordenan solo por prioridad estática (1 a 99), sin repartir por pesos. Para que un proceso de tiempo real no deje sin CPU al resto del sistema, el kernel limita su uso con `sched_rt_runtime_us` dentro de `sched_rt_period_us`; con los valores por defecto (950000 de 1000000 µs), reserva el 5 % para los procesos normales.
- **Permisos.** Pasar a una política de tiempo real o bajar el valor de nice (aumentar la prioridad) requiere privilegios.

**Referencias:**

- Silberschatz, A., Galvin, P. B. y Gagne, G. *Operating System Concepts*, 10.ª edición, Wiley. Capítulo 5, «CPU Scheduling»: criterios y algoritmos (secciones 5.2 y 5.3), planificación de tiempo real (sección 5.6) y el planificador CFS de Linux (sección 5.7.1). En la 9.ª edición el mismo tema es el capítulo 6.
- Arpaci-Dusseau, R. H. y Arpaci-Dusseau, A. C. *Operating Systems: Three Easy Pieces*. Capítulo 9, «Scheduling: Proportional Share», que explica el reparto de CPU por pesos y el planificador CFS con su tabla de pesos por nice.
- Tanenbaum, A. S. y Bos, H. *Modern Operating Systems*, 5.ª edición, Pearson, 2023. Capítulo 2, sección 2.5, «Scheduling» (planificación en sistemas interactivos, 2.5.3, y en tiempo real, 2.5.4).
- Stoica, I. y Abdel-Wahab, H. *Earliest Eligible Virtual Deadline First: A Flexible and Accurate Mechanism for Proportional Share Resource Allocation*, Old Dominion University, informe técnico TR-95-22, 1995. Es el algoritmo en el que se basa EEVDF; los libros anteriores describen CFS, su antecesor en el kernel de Linux.
- Documentación del kernel de Linux: `Documentation/scheduler/sched-eevdf.rst`.
- Páginas del manual: `sched(7)`, `sched_setscheduler(2)`, `setpriority(2)`, `proc(5)` y `nice(1)`.

## 3. Método de medición

**Entorno.** VM de ArenalOS (`arenalos-jairo`) en VirtualBox, con 4 GB de RAM (3889 MB según `free -m`), 2 vCPU y disco dinámico de 20 GB; Arch Linux con kernel 6.18.62-1-lts. Sin otras aplicaciones abiertas durante las pruebas. Frecuencia de ticks de `/proc`: 100 por segundo (`os.sysconf("SC_CLK_TCK")`).

**Datos del planificador** (paso 5):

```bash
uname -r
chrt -m
cat /proc/sys/kernel/sched_rt_runtime_us /proc/sys/kernel/sched_rt_period_us
```

**Listado de procesos** (paso 7): se ejecutó la herramienta y `ps` y se compararon las columnas comunes (PID, PPID, estado, nice y política):

```bash
sudo python3 /media/sf_arenalos/src/procesos/procesos.py --top 10
ps -eo pid,ppid,stat,ni,cls,pcpu,comm --sort=-pcpu | head -11
```

**Prueba de la herramienta** (paso 8, con `sudo`): un proceso `sh -c 'while :; do :; done'` al que se le cambió el nice a 10, luego la política a `batch` y luego a `fifo` con prioridad 5, verificando cada cambio con `ps -o pid,ni,cls,comm -p PID`.

**Prueba negativa** (sin `sudo`, con el script copiado a `~/procesos.py` porque la carpeta compartida es de `root:vboxsf` y no se puede leer sin privilegios): intentar pasar a `fifo` con prioridad 5 y bajar el nice a -5.

**Experimento de nice** (paso 10): procesos que giran, fijados al núcleo 0 con `taskset -c 0` y lanzados con `nice -n N`. Tras 30 s, el script lee `utime + stime` de `/proc/PID/stat` y calcula el porcentaje medido. Se compara con `peso / suma de pesos` según `sched_prio_to_weight`. Comandos exactos:

```bash
sudo bash /media/sf_arenalos/scripts/experimento-nice.sh 30 0 10      # 3 repeticiones
sudo bash /media/sf_arenalos/scripts/experimento-nice.sh 30 0 5 10    # 3 repeticiones
```

**Experimento de tiempo real** (paso 11): un proceso normal y uno `SCHED_FIFO` de prioridad 10, ambos en el núcleo 0, durante 10 s. Se verificó la política del proceso de tiempo real con el campo 41 de `/proc/PID/stat` (1 = FIFO). Comando exacto, con 3 repeticiones y con un snapshot previo (`antes-experimento-rt`):

```bash
sudo bash /media/sf_arenalos/scripts/experimento-rt.sh 10 10
```

Las salidas completas están en `docs/logs/tema-01/` (`nice-0-10.txt`, `nice-0-5-10.txt` y `tiempo-real.txt`).

## 4. Resultados

### 4.1 Datos del planificador

| Dato | Valor |
|---|---|
| Kernel | 6.18.62-1-lts (mayor que 6.6: EEVDF) |
| Prioridades `SCHED_FIFO` y `SCHED_RR` | 1 a 99 |
| `SCHED_OTHER`, `SCHED_BATCH`, `SCHED_IDLE`, `SCHED_DEADLINE` | 0 a 0 |
| `sched_rt_runtime_us` / `sched_rt_period_us` | 950000 / 1000000 |

### 4.2 Listado de procesos: herramienta frente a `ps`

Salida de `procesos.py --top 10` (sistema en reposo, intervalo de 1 s):

```
    PID    PPID E   NI POLITICA   %CPU  COMANDO
      1       0 S    0 OTHER       0.0  systemd
      2       0 S    0 OTHER       0.0  kthreadd
      3       2 S    0 OTHER       0.0  pool_workqueue_release
      4       2 I  -20 OTHER       0.0  kworker/R-rcu_gp
      5       2 I  -20 OTHER       0.0  kworker/R-sync_wq
      6       2 I  -20 OTHER       0.0  kworker/R-kvfree_rcu_reclaim
      7       2 I  -20 OTHER       0.0  kworker/R-slub_flushwq
      8       2 I  -20 OTHER       0.0  kworker/R-netns
     12       2 I    0 OTHER       0.0  kworker/u8:0-events_unbound
     13       2 I    0 OTHER       0.0  kworker/u8:1-ipv6_addrconf
```

Salida de `ps -eo pid,ppid,stat,ni,cls,pcpu,comm --sort=-pcpu | head -11`:

```
    PID    PPID STAT  NI CLS %CPU COMMAND
    365     363 Ssl+   0  TS  0.3 Xorg
    770       1 Sl     0  TS  0.1 xfce4-terminal
    523     436 Sl     0  TS  0.0 xfce4-panel
      1       0 Ss     0  TS  0.0 systemd
    647     645 Sl     0  TS  0.0 VBoxClient
    492     436 Sl     0  TS  0.0 xfwm4
    640     639 Sl     0  TS  0.0 VBoxClient
    537     436 Sl     0  TS  0.0 xfdesktop
    436     399 Sl     0  TS  0.0 xfce4-session
    232       1 Ss     0  TS  0.0 systemd-udevd
```

El proceso que aparece en ambas listas, `systemd` (PID 1), coincide en todos los campos: PPID 0, estado `S` (en `ps`, `Ss`: la segunda letra marca que es líder de sesión), nice 0 y política `OTHER` (en `ps`, `TS`). Los procesos de kernel `kworker/R-*` aparecen con nice -20 y estado `I` (inactivo), y `ps` los traduce con la misma letra.

### 4.3 Cambio de nice y de política

| Paso | Resultado de `ps -o pid,ni,cls,comm` |
|---|---|
| `--nice PID 10` | nice 10 |
| `--politica PID batch` | `NI` 10, `CLS` `B` |
| `--politica PID fifo --prio 5` | `NI` `-`, `CLS` `FF` |

Con `FIFO`, la columna `NI` muestra `-` porque el nice no aplica a los procesos de tiempo real.

Prueba negativa, sin privilegios:

| Intento | Resultado |
|---|---|
| Pasar a `fifo` con prioridad 5 | `Error: [Errno 1] Operation not permitted` |
| Bajar el nice a -5 | `Error: [Errno 13] Permission denied` |

### 4.4 Reparto de CPU con distinto nice (30 s, núcleo 0)

**Nice 0 y 10** (esperado 90,3 % y 9,7 %):

| Repetición | Ticks nice 0 | Ticks nice 10 | % nice 0 | % nice 10 |
|---|---|---|---|---|
| 1 | 2687 | 288 | 90,3 | 9,7 |
| 2 | 2693 | 290 | 90,3 | 9,7 |
| 3 | 2686 | 290 | 90,3 | 9,7 |
| **Promedio** | 2688,7 | 289,3 | **90,3** | **9,7** |

**Nice 0, 5 y 10** (esperado 69,7 %, 22,8 % y 7,5 %):

| Repetición | Ticks nice 0 | Ticks nice 5 | Ticks nice 10 | % nice 0 | % nice 5 | % nice 10 |
|---|---|---|---|---|---|---|
| 1 | 2077 | 679 | 223 | 69,7 | 22,8 | 7,5 |
| 2 | 2073 | 677 | 222 | 69,8 | 22,8 | 7,5 |
| 3 | 2073 | 677 | 222 | 69,8 | 22,8 | 7,5 |
| **Promedio** | 2074,3 | 677,7 | 222,3 | **69,8** | **22,8** | **7,5** |

La diferencia máxima entre lo medido y lo esperado fue de 0,1 puntos porcentuales.

### 4.5 Tiempo real contra normal (10 s, núcleo 0, `SCHED_FIFO` prioridad 10)

| Repetición | Ticks normal | Ticks FIFO | % normal | % FIFO |
|---|---|---|---|---|
| 1 | 50 | 942 | 5,0 | 95,0 |
| 2 | 46 | 945 | 4,6 | 95,4 |
| 3 | 51 | 946 | 5,1 | 94,9 |
| **Promedio** | 49,0 | 944,3 | **4,9** | **95,1** |

## 5. Interpretación

**El listado coincide con `ps`.** Para el proceso que aparece en las dos salidas (`systemd`, PID 1) la herramienta y `ps` dan el mismo PID, PPID, estado, nice y política. Las dos listas no muestran los mismos procesos porque con el sistema en reposo casi todos tienen 0,0 % de CPU en el intervalo de la herramienta (que mide el uso durante 1 s), mientras que `ps` ordena por el promedio de uso desde que arrancó cada proceso; por eso el orden y el %CPU no se pueden comparar uno a uno.

**Nice reparte en proporción a los pesos.** Los porcentajes medidos coinciden con los que predice la tabla `sched_prio_to_weight`: 90,3 / 9,7 con nice 0 y 10, y 69,8 / 22,8 / 7,5 con nice 0, 5 y 10, con diferencias de a lo sumo 0,1 puntos. Esto es lo que se espera de EEVDF: a largo plazo, cada proceso recibe `peso / suma de pesos`, y un nice mayor no impide que el proceso corra, solo reduce su parte. Con tres procesos se ve que el reparto no es lineal en nice: del nice 0 al 5 el peso cae de 1024 a 335, y del 5 al 10 de 335 a 110, un factor cercano a 3 por cada cinco pasos.

**Por qué la coincidencia es tan buena.** Los procesos del experimento solo giran, así que siempre están listos y nunca bloquean; el núcleo 0 estuvo ocupado casi todo el tiempo (unos 2975 de 3000 ticks posibles en 30 s), y los procesos quedaron fijados al mismo núcleo, de modo que el único factor que reparte la CPU entre ellos es el peso. Las tres repeticiones difieren en pocos ticks (de 1 a 7), lo que indica poca variabilidad. Las diferencias residuales pueden deberse a que la VM comparte CPU con el anfitrión, a que los procesos arrancan con unos milisegundos de diferencia y a que `/proc` cuenta en ticks de 10 ms.

**Tiempo real desplaza a los procesos normales.** Con `SCHED_FIFO` el reparto fue de 95,1 % para el proceso de tiempo real y 4,9 % para el normal, muy distinto del 50 / 50 que habría con dos procesos de igual nice. Una prioridad de tiempo real no se reparte por pesos: el proceso `FIFO` corre mientras esté listo. Que el proceso normal obtuviera cerca del 5 % se debe al límite del kernel (`sched_rt_runtime_us` = 950000 de `sched_rt_period_us` = 1000000), que le quita el núcleo al proceso de tiempo real durante el 5 % de cada segundo y evita que el sistema quede sin respuesta. Esto coincide con el valor medido (95,1 % frente a 95 % esperado).

**Comparación entre ambos mecanismos.** Nice ajusta cuánto se lleva cada proceso, pero todos avanzan. La prioridad de tiempo real da prioridad absoluta, con el costo de que un proceso mal escrito puede acaparar la CPU, y por eso el kernel impone el tope. La herramienta `procesos.py` permite observar y cambiar ambos mecanismos, y las pruebas sin privilegios mostraron que el kernel exige permisos para subir la prioridad: `sched_setscheduler` falla con `EPERM` y `setpriority` con `EACCES`.

**Limitaciones.** Todo se midió en una VM con procesos fijados a un solo núcleo; en un sistema real con varios núcleos y procesos que se bloquean por entrada y salida, el reparto sería menos limpio. Los experimentos miden solo el caso de procesos limitados por CPU.

Log del experimento de nice sobre el sistema instalado con `install.sh`: `docs/logs/tema-01/integrado.txt`.
