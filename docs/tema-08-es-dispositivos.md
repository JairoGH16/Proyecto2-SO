# Tema/Módulo: 8 · E/S y dispositivos          Responsable: Esteban

> Apoyo: Jairo · Entorno: VM VirtualBox 7.2 (sobre Windows 11 con Hyper-V), ArenalOS, kernel `6.18.62-1-lts`, 2 vCPU, 4 GiB.
> Datos crudos y scripts de medición: [`docs/logs/esteban/tema-08/`](logs/esteban/tema-08/).

## 1. Qué se implementó

| Componente | Ruta en el repositorio | Se instala en |
|---|---|---|
| Lista negra de módulos justificada | [`udev/arenalos-blacklist.conf`](../udev/arenalos-blacklist.conf) | `/etc/modprobe.d/` |
| Regla udev propia (almacenamiento USB) | [`udev/99-arenalos-usb.rules`](../udev/99-arenalos-usb.rules) | `/etc/udev/rules.d/` |
| Servicio plantilla que ejecuta la acción | [`udev/arenalos-usb@.service`](../udev/arenalos-usb@.service) | `/etc/systemd/system/` |
| Script de la acción (registrar + montar `ro`) | [`udev/arenalos-usb-handler`](../udev/arenalos-usb-handler) | `/usr/local/lib/arenalos/` |
| Instalador idempotente del tema | [`udev/install.sh`](../udev/install.sh) | lo llama `install.sh` |

**Lista negra.** Bloquea 4 grupos de módulos que la VM carga, pero cuyo hardware no existe en VirtualBox:

| Módulo | Qué controla | Evidencia de que sobra en la VM |
|---|---|---|
| `pcspkr` | Parlante interno de la placa | La VM no tiene parlante; solo genera "beeps" |
| `intel_rapl_msr`, `intel_rapl_common` | Medición/límite de energía (RAPL) por MSR | `/sys/class/powercap/` queda **vacío** (0 zonas) |
| `intel_pmc_core` (+ `pmt_*`, `intel_vsec`) | Power Management Controller de chipsets Intel | Sin mensajes en `dmesg` y sin `/sys/kernel/debug/pmc_core` |
| `vmw_vmci`, `vmw_vsock_vmci_transport` | Canal VM↔host de **VMware** | Requiere el PCI `15ad:0740`, que **no aparece** en `lspci` (el hipervisor es VirtualBox) |

**Regla udev.** Al conectar cualquier almacenamiento USB con sistema de archivos:
1. udev marca el dispositivo con `TAG+="systemd"` y `SYSTEMD_WANTS=arenalos-usb@sdb1.service`.
2. systemd inicia el servicio.
3. El script lee las propiedades del dispositivo (desde udev y `/sys`) y deja registro en el journal y en `/var/log/arenalos-usb.log`: vendor:product, modelo, serie, FS y tamaño.
4. Monta el dispositivo en **solo lectura** con `ro,nosuid,nodev,noexec` en `/media/usb-<dev>`.

Al desconectarlo, `BindsTo=dev-%i.device` hace que systemd detenga el servicio, y este desmonta y registra la desconexión. El montaje no se hace desde `RUN+=` porque `systemd-udevd` ejecuta `RUN` en un espacio de montaje privado y mata los procesos largos. La forma correcta de lanzar acciones largas es delegarlas a systemd (`udev(7)`, `systemd.device(5)`).

## 2. Concepto de Sistemas Operativos

- **Subsistema de E/S y drivers como módulos cargables.** El kernel ve el hardware por buses: PCI, USB, SCSI. Cada dispositivo publica un `modalias`, y udev carga el módulo cuyo alias coincide (por ejemplo `pci:v000015ADd00000405…` corresponde a `vmwgfx`). Una lista negra corta ese emparejamiento automático.
- **Dependencias entre módulos.** `blacklist` solo impide la carga por alias. En cambio `install <mod> /bin/false` impide cualquier carga, incluida la que ocurre como dependencia de otro módulo.
- **Modelo de dispositivos y hot-plug.** Al conectar un dispositivo, el kernel emite *uevents* (`add`/`remove`) por cada objeto que crea en `/sys`. udev los procesa con reglas y los reenvía. systemd modela el dispositivo como una unidad `.device` a la que se puede atar un servicio.
- **Interrupciones.** Al terminar cada operación, el controlador avisa a la CPU con una IRQ, y el kernel cuenta cada IRQ en `/proc/interrupts`. El costo de E/S depende de **cuántas peticiones** se hacen, no solo de cuántos bytes se mueven. Además, cada protocolo genera un número distinto de interrupciones por petición.
- **Heterogeneidad de cómputo (Unidad 1).** CPU, GPU y NPU son dispositivos que el SO expone por distintos subsistemas: CPU en `/sys/devices/system/cpu`, GPU por DRM (`/dev/dri`) y NPU por el subsistema *accel* (`/dev/accel`).

**Bibliografía:**
- Silberschatz, Galvin y Gagne, *Operating System Concepts*, 10.ª ed., cap. 12 "I/O Systems": interrupciones, DMA, drivers, subsistema de E/S del kernel.
- Tanenbaum y Bos, *Modern Operating Systems*, 4.ª ed., cap. 5 "Input/Output".
- Páginas de manual: `modprobe.d(5)`, `udev(7)`, `systemd.device(5)`, `proc(5)`.
- Arch Wiki: *Kernel module*, *udev*.

## 3. Método de medición

Todo se ejecutó en la VM de Esteban. Los scripts están en `docs/logs/esteban/tema-08/`.

**A. Lista negra (módulos antes/después).** Se reinició **3 veces sin** la lista negra y **3 veces con** ella. Después de cada arranque se ejecutó [`medir-modulos.sh`](logs/esteban/tema-08/medir-modulos.sh), que registra:
- cantidad de módulos: `lsmod | tail -n +2 | wc -l`
- memoria total de módulos: suma de la columna *Size* de `lsmod`
- cuántos módulos candidatos siguen cargados
- tiempos de arranque: `systemd-analyze`

La lista negra se instaló con `sudo ./udev/install.sh`, que regenera el initramfs porque el hook `modconf` copia `/etc/modprobe.d`. Se ejecutó dos veces para comprobar que es idempotente.

**B. Regla udev.** Se conectó la USB **Kingston DataTraveler 3.0** (`0951:1666`, FAT32, 57.7 GiB) a la VM por el controlador xHCI (USB 3.0), con `VBoxManage controlvm … usbattach`. Durante la conexión y la desconexión se capturó con:
```
udevadm monitor --kernel --udev --property
dmesg -w
```
Después se revisaron `udevadm info`, `udevadm test`, `systemctl status arenalos-usb@sdb1`, `findmnt` y una **prueba negativa** de escritura (`touch`).

**C. `/proc/interrupts` antes/después de E/S intensiva.** Con [`irq-exp.sh`](logs/esteban/tema-08/irq-exp.sh) se contó el incremento de dos líneas de IRQ durante cada operación:
- **IRQ 21**: `ahci`, el disco SATA, compartida con el audio
- **IRQ 20**: `xhci-hcd`, la USB 3.0, compartida con `vboxguest`

Antes de cada operación se ejecutó `sync; echo 3 > /proc/sys/vm/drop_caches`. Todas las operaciones usan `O_DIRECT` (`oflag/iflag=direct`) para evitar la caché de páginas. La lectura de la USB es en crudo y de solo lectura, así que no se escribe nada en la memoria.

| Operación | Comando |
|---|---|
| Reposo (línea base de ruido) | `sleep 5` |
| SATA, escritura 256 MiB en bloques de 1 MiB | `dd if=/dev/zero of=/root/t8-io.img bs=1M count=256 oflag=direct` |
| SATA, escritura 64 MiB en bloques de 4 KiB | `dd if=/dev/zero of=/root/t8-io.img bs=4k count=16384 oflag=direct` |
| USB, lectura 256 MiB en bloques de 1 MiB | `dd if=/dev/sdb of=/dev/null bs=1M count=256 iflag=direct` |
| USB, lectura 32 MiB en bloques de 4 KiB | `dd if=/dev/sdb of=/dev/null bs=4k count=8192 iflag=direct` |

Cada operación se repitió **5 veces**. Se reportan promedio ± desviación estándar. También se registraron los límites de la cola de bloque (`/sys/block/<dev>/queue/max_sectors_kb`) para interpretar los resultados. Las copias completas de `/proc/interrupts` antes y después están en `04a`/`04b`.

**D. GPU / NPU / CPU.** Se usaron `lspci -k`, `lspci -nn -v -s 00:02.0`, `/sys/bus/pci/devices/0000:00:02.0/driver`, `/sys/class/drm`, `modinfo vmwgfx`, `journalctl -k | grep vmwgfx`, `/sys/class/accel`, `/proc/cpuinfo` y `/sys/devices/system/cpu`.

## 4. Resultados

### 4.1 Lista negra (3 arranques por condición)

| Condición | Módulos cargados | Memoria en módulos | Candidatos cargados | Arranque total (`systemd-analyze`) |
|---|---|---|---|---|
| Sin lista negra | **47** | **3196 KiB** | 11 | 11.61 ± 0.73 s |
| Lista negra v1 (solo `install` del transporte vsock) | 37 | 2816 KiB | 1 (`vmw_vmci`) | 11.40 ± 0.87 s |
| **Lista negra final** | **36** (−11) | **2708 KiB** (−488 KiB, −15.3 %) | **0** | 11.10 ± 0.13 s |

Los valores de módulos y memoria fueron idénticos en las 3 repeticiones de cada condición. Después del cambio no hubo servicios fallidos, y la red, el video y vsock siguieron funcionando (ver [`02-modulos-antes-despues.csv`](logs/esteban/tema-08/02-modulos-antes-despues.csv)).

Prueba en seco que explica la versión v1 (`modprobe -n -v net-pf-40`):
```
insmod .../vmw_vmci.ko.zst      <- la dependencia se carga ANTES
install /bin/false              <- y recién después se bloquea el transporte
```
Al agregar `install vmw_vmci /bin/false`, las dos líneas pasan a ser `install /bin/false`.

Práctica con `modprobe` ([`01-modulos-antes-y-modprobe.txt`](logs/esteban/tema-08/01-modulos-antes-y-modprobe.txt)):
- `modprobe -r pcspkr` → el dispositivo `PC Speaker` desaparece de `/proc/bus/input/devices`.
- `modprobe -v pcspkr` → `insmod …/pcspkr.ko.zst`, y `dmesg` muestra `input: PC Speaker as /devices/platform/pcspkr/input/input9`.

### 4.2 Regla udev (conexión y desconexión)

Extracto de [`03-regla-udev-conexion.txt`](logs/esteban/tema-08/03-regla-udev-conexion.txt) y [`05-regla-udev-desconexion.txt`](logs/esteban/tema-08/05-regla-udev-desconexion.txt):

```
dmesg:   usb 3-1: new SuperSpeed USB device number 2 using xhci_hcd
         usb 3-1: New USB device found, idVendor=0951, idProduct=1666
         usb-storage 3-1:1.0: USB Mass Storage device detected
         sd 2:0:0:0: [sdb] 121077760 512-byte logical blocks: (62.0 GB/57.7 GiB)
          sdb: sdb1
udevadm info /dev/sdb1:  ID_BUS=usb  ID_FS_USAGE=filesystem  ID_FS_TYPE=vfat
                         SYSTEMD_WANTS=arenalos-usb@sdb1.service  TAGS=:systemd:
journal: CONECTADO sdb1 id=0951:1666 vendor='Kingston' modelo='DataTraveler_3.0'
         serie=E0D55E6C09F21821295307B6 fs=vfat etiqueta='KINGSTON' tamano=59119MiB
         -> montado en /media/usb-sdb1 (ro,nosuid,nodev,noexec,umask=0022)
findmnt: /media/usb-sdb1 /dev/sdb1 vfat ro,nosuid,nodev,noexec,...
touch /media/usb-sdb1/prueba  ->  Read-only file system   (prueba negativa OK)
--- desconexión ---
dmesg:   usb 3-1: USB disconnect, device number 2
uevents: remove .../block/sdb/sdb1 -> remove .../block/sdb -> remove scsi -> unbind/remove usb 3-1
journal: Stopping arenalos-usb@sdb1 ... DESCONECTADO sdb1 -> desmontado /media/usb-sdb1
```

### 4.3 Interrupciones por operación (5 repeticiones)

| Operación | Peticiones al dispositivo | Δ IRQ 21 `ahci` | Δ IRQ 20 `xhci` | IRQ por petición | Rendimiento (dd) |
|---|---|---|---|---|---|
| Reposo 5 s | — | 25.6 ± 6.7 | 4.4 ± 0.8 | — | — |
| SATA escr. 256 MiB, bs=1M | 256 | **346.2 ± 11.8** | 0.8 ± 1.0 | 1.35 | 331 MB/s |
| SATA escr. 64 MiB, bs=4k | 16 384 | **16 415.4 ± 4.7** | 21.6 ± 3.9 | **1.00** | 3.1 MB/s |
| USB lect. 256 MiB, bs=1M | 1 024 (*) | 29.4 ± 2.6 | **3 085.6 ± 1.5** | **3.01** | 26.6 MB/s |
| USB lect. 32 MiB, bs=4k | 8 192 | 59.8 ± 11.3 | **24 628.8 ± 14.6** | **3.01** | 0.67 MB/s |

(*) `max_sectors_kb` de la USB es **256**, así que cada `read` de 1 MiB se parte en 4 comandos SCSI: 256 MiB ÷ 256 KiB = 1024. En el disco SATA `max_sectors_kb = 4096`, y cada bloque de 1 MiB va en una sola petición ([`04c-colas-bloque.txt`](logs/esteban/tema-08/04c-colas-bloque.txt)).

### 4.4 GPU, NPU y CPU ([`06-gpu-npu-cpu.txt`](logs/esteban/tema-08/06-gpu-npu-cpu.txt))

| Unidad | Qué ve el SO | Driver / interfaz |
|---|---|---|
| **CPU** | `12th Gen Intel Core i5-12450H`, 2 vCPU (`/sys/devices/system/cpu/online = 0-1`), flag `hypervisor` | Planificador del kernel; `/proc/cpuinfo`, `/sys/devices/system/cpu` |
| **GPU** | `00:02.0 VGA [0300]: VMware SVGA II Adapter [15ad:0405]`, IRQ 18, BAR0 de 128 MiB prefetchable (VRAM) y BAR de 2 MiB (FIFO de comandos) | **`vmwgfx`** (DRM/KMS) → `/dev/dri/card0` (grupo `video`, modo de pantalla) y `/dev/dri/renderD128` (grupo `render`, render sin privilegios). Depende de `ttm` (gestor de memoria de GPU) |
| **NPU** | No hay dispositivo de clase PCI `1200` y `/sys/class/accel/` está vacío | **No detectada.** El kernel trae drivers de NPU (`intel_vpu` "Driver for Intel NPU", `amdxdna`), pero no se cargan porque no hay dispositivo que coincida |

`journalctl -k`:
```
vmwgfx 0000:00:02.0: [drm] Legacy memory limits: VRAM = 131072 KiB, FIFO = 2048 KiB
vmwgfx 0000:00:02.0: [drm] Using command buffers with DMA pool.
[drm] Initialized vmwgfx 2.21.0 for 0000:00:02.0 on minor 0
fbcon: vmwgfxdrmfb (fb0) is primary device
```
Durante todo el experimento, la línea de IRQ 18 de `vmwgfx` registró **0 interrupciones**.

## 5. Interpretación

**Lista negra.** Los datos coinciden con la teoría: la carga de módulos está guiada por *modalias*, y en una VM el kernel carga drivers por coincidencias (el modelo de CPU del host o un transporte vsock genérico) aunque el hardware real no exista. Bloquearlos ahorró **11 módulos y 488 KiB de memoria del kernel**, sin perder funcionalidad.

El caso de `vmw_vmci` muestra la diferencia entre `blacklist` e `install`:
- Al abrir un socket `AF_VSOCK` (familia 40), el kernel pide el alias `net-pf-40`.
- `modprobe` carga **primero las dependencias** del módulo pedido y después ejecuta su `install`.
- Por eso hubo que bloquear también la dependencia.

El tiempo de arranque bajó en promedio (11.61 → 11.10 s; kernel 2.39 → 2.20 s), pero la diferencia está dentro de la variación de una VM sobre Hyper-V (±0.7 s). **No se afirma que haya una mejora de arranque**: el efecto medible es el de memoria y módulos.

**Regla udev.** La secuencia observada coincide con el modelo de dispositivos:
1. El controlador xHCI detecta el dispositivo.
2. `usb-storage` lo registra como host SCSI.
3. `sd` crea `sdb`, y la tabla de particiones genera `sdb1`.
4. Cada objeto nuevo produce un *uevent* `add`.
5. udev enriquece el evento con `ID_BUS`/`ID_FS_*` y aplica la regla.

La desconexión genera los `remove` en **orden inverso**, de las hojas a la raíz, y `BindsTo=` vincula la vida del servicio a la del dispositivo. La prueba negativa confirma la política de seguridad: un USB conectado no puede modificarse ni ejecutar binarios (`noexec`). Esto conecta con el Tema 9.

**Interrupciones.** El resultado central es que **las interrupciones son proporcionales al número de peticiones, no a los bytes**:
- **AHCI/SATA, bloques de 4 KiB:** 16 415 IRQ para 16 384 escrituras, o sea **1.00 IRQ por petición**. Con `O_DIRECT` síncrono, la profundidad de cola es 1, y cada comando termina con una interrupción de finalización.
- **AHCI/SATA, bloques de 1 MiB:** el mismo volumen genera unas 190 veces menos interrupciones por MiB (1.35 contra 256.5). El rendimiento sube de 3.1 a 331 MB/s porque el costo fijo por petición (interrupción, cambio de contexto, procesamiento en el driver) se reparte entre más bytes. El exceso sobre 1.0 (unas 90 IRQ) corresponde a las escrituras de metadatos y journal de ext4 (`jbd2`) al asignar los bloques del archivo.
- **USB Mass Storage, Bulk-Only Transport:** **3.01 IRQ por petición** en los dos tamaños de bloque, con una desviación mínima (±1.5 en 3086). Coincide exactamente con las 3 fases de cada comando BOT: CBW (comando), transferencia de datos y CSW (estado), y el xHCI genera un evento de finalización por cada transferencia. Con bloques de 1 MiB, la predicción 1024 × 3 = 3072 más el ruido de reposo (unas 9 IRQ en 10 s) da ≈ 3081, frente a 3085.6 medido.
- **Ruido.** Las IRQ están **compartidas** (INTx del IO-APIC: `ahci` con el audio, `xhci` con `vboxguest`). Por eso se midió la línea base en reposo, que resultó pequeña frente a las cargas (≤ 1 % en los casos de 4 KiB).

Una limitación: es E/S **virtualizada**. El controlador lo emula VirtualBox sobre Hyper-V, y los rendimientos absolutos no representan al hardware real (la Kingston de USB 3.0 da unos 27 MB/s en la VM). Los **cocientes** de IRQ por petición, en cambio, son estables y coinciden con los protocolos.

**GPU, NPU y la conexión con la Unidad 1.** El SO expone cada unidad de cómputo por un subsistema distinto:
- **CPU:** se administra por el planificador y se ve en `/sys/devices/system/cpu`.
- **GPU:** el SO no "ejecuta" en ella. El driver `vmwgfx` mapea sus BARs en memoria (MMIO), le envía buffers de comandos por DMA a través del FIFO de 2 MiB, gestiona su memoria con `ttm` y la presenta a los programas por DRM, con nodos separados: `card0` para el modo de pantalla (KMS) y `renderD128` para el render. La "GPU" es un adaptador **paravirtual** (VMware SVGA II, que VirtualBox emula en modo VMSVGA). El aviso `unsupported hypervisor` aparece porque `vmwgfx` espera a VMware. En esta configuración, sin aceleración 3D, no se registraron interrupciones de la GPU: el driver sincroniza por el FIFO.
- **NPU:** Linux la expone con un subsistema propio, *accel* (`/dev/accel/accelN`), que se separó de DRM porque no es una GPU. Hay drivers (`intel_vpu`, `amdxdna`), pero no hay dispositivo. Ni la VM ni el host tienen NPU: el i5-12450H es de 12.ª generación, y las NPU de Intel llegaron con Core Ultra. `midistro-info` debe reportar "no detectada" sin fallar.
