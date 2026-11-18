#!/usr/bin/env python3
"""midistro-info · modulo_procesos: procesos por estado, planificador y límite de tiempo real.

Integrante: Jairo (Temas 1 y 6).
Interfaces del SO:
  /proc/PID/stat                         estado de cada proceso (R, S, D, Z, T, I...)
  os.uname() (llamada uname)             versión del kernel: EEVDF desde 6.6, CFS antes
  /proc/sys/kernel/sched_rt_runtime_us   tiempo que pueden usar los procesos de tiempo real...
  /proc/sys/kernel/sched_rt_period_us    ...dentro de cada periodo
Capa 2: usa muestrear() de la herramienta del Tema 1 (src/procesos/procesos.py,
instalada como /usr/bin/arenalos-procesos por el paquete del Tema 6), que lee
/proc/PID/stat de cada proceso. Si no se puede importar, lo lee directamente.

Uso solo: python3 src/midistro-info/modulo_procesos.py
"""
import collections
import importlib.machinery
import importlib.util
import os
import sys

ORDEN = 40
sys.dont_write_bytecode = True

ESTADOS = {
    "R": "ejecutando", "S": "durmiendo", "D": "esperando E/S", "I": "inactivos (kernel)",
    "Z": "zombis", "T": "detenidos", "t": "en traza", "X": "muertos",
}


def cargar_capa2():
    """Importa procesos.py desde el repo o desde el paquete arenalos-procesos."""
    aqui = os.path.dirname(os.path.realpath(__file__))
    for ruta in (os.path.join(aqui, "..", "procesos", "procesos.py"), "/usr/bin/arenalos-procesos"):
        if os.path.isfile(ruta):
            try:
                loader = importlib.machinery.SourceFileLoader("arenalos_procesos", ruta)
                spec = importlib.util.spec_from_loader("arenalos_procesos", loader)
                modulo = importlib.util.module_from_spec(spec)
                loader.exec_module(modulo)
                return modulo, os.path.normpath(ruta)
            except Exception:
                continue
    return None, None


def estados_directo():
    """Lista de estados leída de /proc/PID/stat (fallback)."""
    estados = []
    for pid in filter(str.isdigit, os.listdir("/proc")):
        try:
            with open(f"/proc/{pid}/stat") as f:
                datos = f.read()
        except OSError:
            continue
        estados.append(datos[datos.rindex(")") + 2:].split()[0])
    return estados


def planificador():
    version = os.uname().release
    try:
        mayor, menor = (int(x) for x in version.split("-")[0].split(".")[:2])
    except ValueError:
        return f"desconocido (kernel {version})"
    if (mayor, menor) >= (6, 6):
        return f"EEVDF (kernel {mayor}.{menor} >= 6.6)"
    return f"CFS (kernel {mayor}.{menor} < 6.6)"


def tiempo_real():
    try:
        with open("/proc/sys/kernel/sched_rt_runtime_us") as f:
            runtime = int(f.read())
        with open("/proc/sys/kernel/sched_rt_period_us") as f:
            periodo = int(f.read())
    except (OSError, ValueError):
        return "desconocido"
    if runtime < 0:
        return "sin límite (sched_rt_runtime_us = -1)"
    return f"{100 * runtime / periodo:.0f} % de la CPU ({runtime} de {periodo} µs)"


def seccion():
    capa2, origen = cargar_capa2()
    if capa2:
        estados = [s["estado"] for s in capa2.muestrear().values()]
    else:
        estados = estados_directo()
    conteo = collections.Counter(estados)
    detalle = ", ".join(f"{n} {ESTADOS.get(e, e)}" for e, n in conteo.most_common())
    return [
        "== Procesos ==",
        f"  Procesos:     {len(estados)} ({detalle})",
        f"  Planificador: {planificador()}",
        f"  Tiempo real:  {tiempo_real()}",
        f"  Fuente:       {'herramienta del Tema 1 (' + origen + ')' if capa2 else 'lectura directa de /proc'}",
    ]


if __name__ == "__main__":
    print("\n".join(seccion()))
