#!/usr/bin/env python3
"""midistro-info · modulo_dispositivos: GPU y NPU con su driver.

Integrante: Esteban (Tema 8).
Interfaces del SO:
  /sys/bus/pci/devices/*/class          clase PCI: 0x03xxxx es GPU, 0x1200xx es acelerador (NPU)
  /sys/bus/pci/devices/*/{vendor,device} identificadores del dispositivo
  /sys/bus/pci/devices/*/driver         enlace simbólico al driver que tomó el dispositivo
  /sys/class/accel/*                    aceleradores registrados en el subsistema accel del kernel
  /usr/share/hwdata/pci.ids             nombres legibles (opcional; si no está, se muestran los IDs)
Capa 2: el Tema 8 registró GPU, NPU y drivers con `lspci -k` en
docs/logs/esteban/tema-08/06-gpu-npu-cpu.txt; este módulo obtiene lo mismo
directo de /sys, sin llamar a lspci.

Nunca lanza excepción: si no hay GPU o NPU imprime "no detectada", y si el
dispositivo no tiene driver, "sin driver cargado".
La raíz de sysfs se puede cambiar con MIDISTRO_SYSFS para probar con un árbol falso.

Uso solo: python3 src/midistro-info/modulo_dispositivos.py
"""
import glob
import os

ORDEN = 20
SYSFS = os.environ.get("MIDISTRO_SYSFS", "/sys")
PCI_IDS = "/usr/share/hwdata/pci.ids"


def leer(ruta):
    try:
        with open(ruta) as f:
            return f.read().strip()
    except OSError:
        return ""


def driver(dispositivo):
    enlace = os.path.join(dispositivo, "driver")
    try:
        return os.path.basename(os.readlink(enlace))
    except OSError:
        return None


def nombres_pci(pares):
    """Busca en pci.ids el nombre de cada (vendor, device). Devuelve {par: texto}."""
    buscados = {(v.lower(), d.lower()) for v, d in pares}
    vendors = {v for v, _ in buscados}
    nombres, vendor_actual, nombre_vendor = {}, None, ""
    try:
        with open(PCI_IDS, encoding="utf-8", errors="replace") as f:
            for linea in f:
                if not linea.strip() or linea.startswith("#"):
                    continue
                if not linea.startswith("\t"):
                    if linea.startswith("C "):  # empieza la lista de clases: ya no hay más vendors
                        break
                    vendor_actual = linea[:4].lower()
                    nombre_vendor = linea[4:].strip()
                elif vendor_actual in vendors and not linea.startswith("\t\t"):
                    par = (vendor_actual, linea[1:5].lower())
                    if par in buscados:
                        nombres[par] = f"{nombre_vendor} {linea[5:].strip()}"
    except OSError:
        pass
    return nombres


def dispositivos_pci():
    lista = []
    for disp in sorted(glob.glob(os.path.join(SYSFS, "bus", "pci", "devices", "*"))):
        clase = leer(os.path.join(disp, "class")).lower()
        if clase.startswith("0x03"):
            tipo = "GPU"
        elif clase.startswith("0x1200"):
            tipo = "NPU"
        else:
            continue
        vendor = leer(os.path.join(disp, "vendor")).lower().replace("0x", "")
        device = leer(os.path.join(disp, "device")).lower().replace("0x", "")
        lista.append({"tipo": tipo, "ruta": os.path.realpath(disp), "slot": os.path.basename(disp),
                      "id": (vendor, device), "driver": driver(disp)})
    return lista


def aceleradores_accel(ya_vistos):
    """NPU registradas en /sys/class/accel que no salieron por PCI (por ejemplo, integradas)."""
    lista = []
    for acc in sorted(glob.glob(os.path.join(SYSFS, "class", "accel", "*"))):
        disp = os.path.join(acc, "device")
        real = os.path.realpath(disp)
        if real in ya_vistos:
            continue
        lista.append({"tipo": "NPU", "ruta": real, "slot": os.path.basename(acc),
                      "id": None, "driver": driver(disp)})
    return lista


def describir(d, nombres):
    if d["id"]:
        nombre = nombres.get(d["id"], "dispositivo")
        texto = f"{nombre} [{d['id'][0]}:{d['id'][1]}] en {d['slot']}"
    else:
        texto = f"acelerador {d['slot']}"
    return f"{texto} · driver: {d['driver'] or 'sin driver cargado'}"


def seccion():
    lineas = ["== Dispositivos =="]
    try:
        pci = dispositivos_pci()
        todos = pci + aceleradores_accel({d["ruta"] for d in pci})
        nombres = nombres_pci([d["id"] for d in todos if d["id"]])
        for tipo in ("GPU", "NPU"):
            de_tipo = [d for d in todos if d["tipo"] == tipo]
            if not de_tipo:
                lineas.append(f"  {tipo}:          no detectada")
            for d in de_tipo:
                lineas.append(f"  {tipo}:          {describir(d, nombres)}")
    except Exception as exc:  # este módulo nunca debe fallar
        lineas.append(f"  no se pudo leer {SYSFS}: {exc}")
    return lineas


if __name__ == "__main__":
    print("\n".join(seccion()))
