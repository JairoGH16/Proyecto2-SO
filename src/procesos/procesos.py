#!/usr/bin/env python3
"""procesos.py: lista procesos leyendo /proc y permite cambiar su prioridad y politica.

Uso:
  procesos.py [--top N] [--intervalo S]      lista los procesos con mas CPU
  procesos.py --nice PID VALOR               cambia el valor nice (setpriority)
  procesos.py --politica PID POL [--prio N]  cambia la politica (sched_setscheduler)
                                             POL: other, batch, idle, fifo, rr
Solo usa la biblioteca estandar de Python 3.
"""
import argparse
import os
import sys
import time

POLITICAS = {0: "OTHER", 1: "FIFO", 2: "RR", 3: "BATCH", 5: "IDLE", 6: "DEADLINE"}
POL_NOMBRE = {
    "other": os.SCHED_OTHER,
    "batch": os.SCHED_BATCH,
    "idle": os.SCHED_IDLE,
    "fifo": os.SCHED_FIFO,
    "rr": os.SCHED_RR,
}
TICKS = os.sysconf("SC_CLK_TCK")


def leer_stat(pid):
    """Devuelve un diccionario con los campos de /proc/PID/stat, o None si ya no existe."""
    try:
        with open(f"/proc/{pid}/stat") as f:
            datos = f.read()
    except (FileNotFoundError, ProcessLookupError, PermissionError):
        return None
    # El nombre (comm) va entre parentesis y puede tener espacios o parentesis.
    ini, fin = datos.index("("), datos.rindex(")")
    campos = datos[fin + 2:].split()
    # campos[0] es el campo 3 de proc(5): state. Por eso campo N = campos[N - 3].
    return {
        "pid": int(datos[:ini]),
        "comm": datos[ini + 1:fin],
        "estado": campos[0],
        "ppid": int(campos[1]),
        "ticks": int(campos[11]) + int(campos[12]),   # utime + stime
        "nice": int(campos[16]),
        "politica": POLITICAS.get(int(campos[38]), str(campos[38])),
    }


def muestrear():
    datos = {}
    for nombre in os.listdir("/proc"):
        if nombre.isdigit():
            s = leer_stat(int(nombre))
            if s:
                datos[s["pid"]] = s
    return datos


def listar(top, intervalo):
    antes = muestrear()
    t0 = time.monotonic()
    time.sleep(intervalo)
    despues = muestrear()
    real = time.monotonic() - t0
    filas = []
    for pid, s in despues.items():
        previo = antes.get(pid)
        uso = 0.0
        if previo:
            uso = (s["ticks"] - previo["ticks"]) / (TICKS * real) * 100
        filas.append((uso, s))
    filas.sort(key=lambda x: x[0], reverse=True)
    print(f"{'PID':>7} {'PPID':>7} {'E':<2} {'NI':>3} {'POLITICA':<8} {'%CPU':>6}  COMANDO")
    for uso, s in filas[:top]:
        print(f"{s['pid']:>7} {s['ppid']:>7} {s['estado']:<2} {s['nice']:>3} "
              f"{s['politica']:<8} {uso:>6.1f}  {s['comm']}")


def main():
    p = argparse.ArgumentParser(description="Procesos desde /proc, prioridad y politica.")
    p.add_argument("--top", type=int, default=15, help="cuantos procesos mostrar")
    p.add_argument("--intervalo", type=float, default=1.0, help="segundos de muestreo")
    p.add_argument("--nice", nargs=2, metavar=("PID", "VALOR"), type=int)
    p.add_argument("--politica", nargs=2, metavar=("PID", "POL"))
    p.add_argument("--prio", type=int, default=0, help="prioridad de tiempo real (1-99)")
    a = p.parse_args()
    if a.top < 1:
        p.error("--top debe ser al menos 1")
    if a.intervalo <= 0:
        p.error("--intervalo debe ser mayor que 0")
    if a.politica and not a.politica[0].isdigit():
        p.error(f"argument --politica: PID invalido: '{a.politica[0]}'")
    try:
        if a.nice:
            os.setpriority(os.PRIO_PROCESS, a.nice[0], a.nice[1])
            print(f"PID {a.nice[0]}: nice = {a.nice[1]}")
        elif a.politica:
            pid, pol = int(a.politica[0]), a.politica[1].lower()
            if pol not in POL_NOMBRE:
                sys.exit(f"Politica desconocida: {pol} (use: {', '.join(POL_NOMBRE)})")
            os.sched_setscheduler(pid, POL_NOMBRE[pol], os.sched_param(a.prio))
            print(f"PID {pid}: politica = {pol.upper()}, prioridad = {a.prio}")
        else:
            listar(a.top, a.intervalo)
    except (PermissionError, ProcessLookupError, OSError) as e:
        sys.exit(f"Error: {e}")


if __name__ == "__main__":
    main()
