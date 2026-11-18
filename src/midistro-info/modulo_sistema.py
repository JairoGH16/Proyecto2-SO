#!/usr/bin/env python3
"""midistro-info · modulo_sistema: equipo, kernel, uptime, CPU y sistema de archivos raíz.

Integrante: Sebastián (Temas 5 y 7).
Interfaces del SO:
  /proc/sys/kernel/hostname y /proc/sys/kernel/osrelease   nombre del equipo y kernel
  /proc/uptime                                             segundos desde el arranque
  /proc/cpuinfo y os.cpu_count()                           modelo y cantidad de CPU
  /proc/mounts y os.statvfs("/")                           dispositivo, tipo y uso de la raíz
Capa 2: el uptime es el mismo dato que muestra arranque-info (Tema 7, bin/arranque-info),
que lo lee de /proc/uptime para el diagnóstico del arranque.

Uso solo: python3 src/midistro-info/modulo_sistema.py
"""
import os

ORDEN = 10


def leer(ruta, defecto="desconocido"):
    try:
        with open(ruta) as f:
            return f.read().strip()
    except OSError:
        return defecto


def uptime():
    try:
        segundos = int(float(leer("/proc/uptime", "0").split()[0]))
    except (ValueError, IndexError):
        return "desconocido"
    dias, resto = divmod(segundos, 86400)
    horas, resto = divmod(resto, 3600)
    minutos = resto // 60
    return (f"{dias} d " if dias else "") + f"{horas} h {minutos} min"


def cpu():
    modelo = "desconocido"
    try:
        with open("/proc/cpuinfo") as f:
            for linea in f:
                if linea.startswith("model name"):
                    modelo = linea.split(":", 1)[1].strip()
                    break
    except OSError:
        pass
    return f"{modelo} ({os.cpu_count() or '?'} CPU)"


def raiz():
    dispositivo, tipo = "desconocido", "desconocido"
    try:
        with open("/proc/mounts") as f:
            for linea in f:
                partes = linea.split()
                if len(partes) >= 3 and partes[1] == "/":
                    dispositivo, tipo = partes[0], partes[2]  # la última entrada de "/" es la que vale
    except OSError:
        pass
    try:
        st = os.statvfs("/")
        total = st.f_blocks * st.f_frsize
        libre = st.f_bavail * st.f_frsize
        usado = total - st.f_bfree * st.f_frsize
        gib = 1024 ** 3
        uso = f", {usado / gib:.1f} de {total / gib:.1f} GiB usados ({libre / gib:.1f} GiB libres)"
    except OSError:
        uso = ""
    return f"{dispositivo} ({tipo}){uso}"


def seccion():
    return [
        "== Sistema ==",
        f"  Equipo:       {leer('/proc/sys/kernel/hostname')}",
        f"  Kernel:       {leer('/proc/sys/kernel/osrelease')}",
        f"  Encendido:    {uptime()}",
        f"  CPU:          {cpu()}",
        f"  FS raíz:      {raiz()}",
    ]


if __name__ == "__main__":
    print("\n".join(seccion()))
