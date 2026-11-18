#!/usr/bin/env python3
"""midistro-info · modulo_memoria: memoria física, swap y zram.

Integrante: Rafael (Temas 2 y 4).
Interfaces del SO:
  /proc/meminfo               MemTotal, MemAvailable, SwapTotal y SwapFree
  /proc/swaps                 cada dispositivo de swap (zram y swapfile) con su prioridad
  /sys/block/zram0/mm_stat    bytes originales y comprimidos de zram
  /sys/block/zram0/comp_algorithm   algoritmo de compresión activo (entre corchetes)
Capa 2: usa las funciones de la herramienta del Tema 2 (src/memoria/memoria.py,
instalada como /usr/local/bin/memoria): leer_meminfo(), leer_swaps() y leer_zram().
Si no se puede importar, lee los mismos archivos directamente.

Uso solo: python3 src/midistro-info/modulo_memoria.py
"""
import importlib.machinery
import importlib.util
import os
import sys

ORDEN = 30
ZRAM = "/sys/block/zram0"
sys.dont_write_bytecode = True


def cargar_capa2():
    """Importa memoria.py desde el repo o desde donde lo instala install.sh."""
    aqui = os.path.dirname(os.path.realpath(__file__))
    for ruta in (os.path.join(aqui, "..", "memoria", "memoria.py"), "/usr/local/bin/memoria"):
        if os.path.isfile(ruta):
            try:
                loader = importlib.machinery.SourceFileLoader("arenalos_memoria", ruta)
                spec = importlib.util.spec_from_loader("arenalos_memoria", loader)
                modulo = importlib.util.module_from_spec(spec)
                loader.exec_module(modulo)
                return modulo, os.path.normpath(ruta)
            except Exception:
                continue
    return None, None


# --- lectura directa (fallback si memoria.py no está) ---

def meminfo_directo():
    datos = {}
    with open("/proc/meminfo") as f:
        for linea in f:
            clave, resto = linea.split(":", 1)
            datos[clave] = int(resto.split()[0])
    return datos


def swaps_directo():
    lista = []
    with open("/proc/swaps") as f:
        next(f, None)
        for linea in f:
            p = linea.split()
            if len(p) >= 5:
                lista.append({"nombre": p[0], "tipo": p[1], "tam_kb": int(p[2]),
                              "usado_kb": int(p[3]), "prioridad": int(p[4])})
    return lista


def zram_directo():
    try:
        with open(os.path.join(ZRAM, "mm_stat")) as f:
            campos = f.read().split()
    except OSError:
        return None
    orig, compr = int(campos[0]), int(campos[1])
    return {"orig_kb": orig // 1024, "compr_kb": compr // 1024, "ratio": orig / compr if compr else 0.0}


def algoritmo_zram():
    try:
        with open(os.path.join(ZRAM, "comp_algorithm")) as f:
            texto = f.read()
    except OSError:
        return None
    if "[" in texto:
        return texto[texto.index("[") + 1:texto.index("]")]
    return texto.strip() or None


def mib(kb):
    return f"{kb / 1024:.0f} MiB"


def seccion():
    capa2, origen = cargar_capa2()
    if capa2:
        meminfo, swaps, zram = capa2.leer_meminfo(), capa2.leer_swaps(), capa2.leer_zram(ZRAM)
    else:
        meminfo, swaps, zram = meminfo_directo(), swaps_directo(), zram_directo()

    total, disponible = meminfo.get("MemTotal", 0), meminfo.get("MemAvailable", 0)
    sw_total, sw_libre = meminfo.get("SwapTotal", 0), meminfo.get("SwapFree", 0)
    lineas = [
        "== Memoria ==",
        f"  RAM:          {mib(total - disponible)} usados de {mib(total)} ({mib(disponible)} disponibles)",
        f"  Swap:         {mib(sw_total - sw_libre)} usados de {mib(sw_total)}",
    ]
    if not swaps:
        lineas.append("                sin dispositivos de swap activos")
    for s in sorted(swaps, key=lambda s: -s["prioridad"]):
        lineas.append(f"                {s['nombre']} ({s['tipo']}, prioridad {s['prioridad']}): "
                      f"{mib(s['usado_kb'])} de {mib(s['tam_kb'])}")
    if zram is None:
        lineas.append("  zram:         no configurado")
    else:
        alg = algoritmo_zram()
        lineas.append(f"  zram:         {mib(zram['orig_kb'])} comprimidos en {mib(zram['compr_kb'])} "
                      f"(razón {zram['ratio']:.2f}" + (f", {alg})" if alg else ")"))
    lineas.append(f"  Fuente:       {'herramienta del Tema 2 (' + origen + ')' if capa2 else 'lectura directa de /proc y /sys'}")
    return lineas


if __name__ == "__main__":
    print("\n".join(seccion()))
