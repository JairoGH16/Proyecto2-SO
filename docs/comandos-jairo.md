# Comandos de Jairo (Temas 1 y 6)

| Comando                                 | Autor | Interfaces del SO                                   | Tema relacionado |
|-----------------------------------------|-------|-----------------------------------------------------|------------------|
| [`cambios-contexto`](#cambios-contexto) | Jairo | `/proc/<pid>/status`                                | T1, T6           |
| [`presion-cpu`](#presion-cpu)           | Jairo | `/proc/pressure/cpu`, `/proc/loadavg`, `/proc/stat` | T1               |

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