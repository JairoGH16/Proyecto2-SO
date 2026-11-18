#!/usr/bin/env python3
"""Tema 2 (Memoria): monitor en tiempo real de memoria física, swap, zram
y fallos de página por proceso. Solo biblioteca estándar, lee /proc y /sys.

Uso:
  memoria.py                 # refresca cada 2 s hasta Ctrl+C
  memoria.py --intervalo 1   # cambia el intervalo
  memoria.py --once          # una sola muestra (para scripts/experimentos)
  memoria.py --top 15        # procesos a mostrar, ordenados por majflt
"""
import argparse
import os
import time


def leer_meminfo():
    datos = {}
    with open("/proc/meminfo") as f:
        for linea in f:
            clave, resto = linea.split(":", 1)
            datos[clave] = int(resto.split()[0])  # kB
    return datos


def leer_swaps():
    """Uso por dispositivo de swap (zram vs swapfile), desde /proc/swaps."""
    dispositivos = []
    with open("/proc/swaps") as f:
        next(f)  # encabezado
        for linea in f:
            partes = linea.split()
            if len(partes) >= 5:
                nombre, tipo, tam_kb, usado_kb, prio = partes[:5]
                dispositivos.append({
                    "nombre": nombre, "tipo": tipo,
                    "tam_kb": int(tam_kb), "usado_kb": int(usado_kb),
                    "prioridad": int(prio),
                })
    return dispositivos


def leer_zram(dispositivo="/sys/block/zram0"):
    """Tasa de compresión de zram desde mm_stat. None si no existe/activo."""
    ruta = os.path.join(dispositivo, "mm_stat")
    if not os.path.exists(ruta):
        return None
    with open(ruta) as f:
        campos = f.read().split()
    orig, compr = int(campos[0]), int(campos[1])
    ratio = orig / compr if compr else 0.0
    return {"orig_kb": orig // 1024, "compr_kb": compr // 1024, "ratio": ratio}


def leer_fallos_por_proceso():
    """(pid, comm, minflt, majflt) de cada proceso visible en /proc."""
    procesos = []
    for pid in filter(str.isdigit, os.listdir("/proc")):
        try:
            with open(f"/proc/{pid}/stat") as f:
                contenido = f.read()
        except (FileNotFoundError, ProcessLookupError, PermissionError):
            continue
        # comm va entre paréntesis y puede contener espacios/paréntesis
        fin_comm = contenido.rfind(")")
        comm = contenido[contenido.find("(") + 1:fin_comm]
        resto = contenido[fin_comm + 2:].split()
        # resto[0]=state ... minflt es el campo 10 global -> índice 7 de resto
        minflt, majflt = int(resto[7]), int(resto[9])
        procesos.append((int(pid), comm, minflt, majflt))
    return procesos


def mb(kb):
    return kb / 1024


def mostrar(top):
    mem = leer_meminfo()
    swaps = leer_swaps()
    zram = leer_zram()
    procesos = sorted(leer_fallos_por_proceso(), key=lambda p: p[3], reverse=True)

    print(f"== ArenalOS · Tema 2 Memoria == {time.strftime('%H:%M:%S')}")
    print()
    print("-- Memoria física (MB) --")
    print(f"  Total: {mb(mem['MemTotal']):8.1f}  "
          f"Libre: {mb(mem['MemFree']):8.1f}  "
          f"Disponible: {mb(mem['MemAvailable']):8.1f}  "
          f"Cache: {mb(mem['Cached']):8.1f}")

    print("-- Swap (MB) --")
    print(f"  Total: {mb(mem['SwapTotal']):8.1f}  "
          f"Usado: {mb(mem['SwapTotal'] - mem['SwapFree']):8.1f}")
    for d in swaps:
        print(f"    {d['nombre']:<20} {d['tipo']:<10} "
              f"usado={mb(d['usado_kb']):7.1f} MB  prioridad={d['prioridad']}")

    print("-- zram --")
    if zram:
        print(f"  original={mb(zram['orig_kb']):7.1f} MB  "
              f"comprimido={mb(zram['compr_kb']):7.1f} MB  "
              f"ratio={zram['ratio']:.2f}x")
    else:
        print("  no activo")

    print(f"-- Top {top} procesos por fallos de página mayores (majflt) --")
    print(f"  {'PID':>7}  {'COMM':<20}  {'minflt':>10}  {'majflt':>10}")
    for pid, comm, minflt, majflt in procesos[:top]:
        print(f"  {pid:>7}  {comm:<20}  {minflt:>10}  {majflt:>10}")


def main():
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("--intervalo", type=float, default=2.0)
    ap.add_argument("--top", type=int, default=10)
    ap.add_argument("--once", action="store_true")
    args = ap.parse_args()

    if args.once:
        mostrar(args.top)
        return
    try:
        while True:
            os.system("clear")
            mostrar(args.top)
            time.sleep(args.intervalo)
    except KeyboardInterrupt:
        pass


if __name__ == "__main__":
    main()
