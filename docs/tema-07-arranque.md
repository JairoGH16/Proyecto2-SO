# Tema 7 · Proceso de arranque

## 1. Qué se implementó
Se analizó, midió y optimizó la cadena completa de arranque de **ArenalOS** sobre firmware UEFI y `systemd`:
- **Cadena de arranque inspeccionada:** Firmware **UEFI 2.70 (EDK II)** $\rightarrow$ gestor de arranque **systemd-boot 262.2-1-arch** (`/EFI/BOOT/BOOTX64.EFI`) $\rightarrow$ kernel `linux-lts` $\rightarrow$ imagen inicial **initramfs** generada por `mkinitcpio` $\rightarrow$ gestor de servicios **systemd** (`sysinit.target` $\rightarrow$ `basic.target` $\rightarrow$ `multi-user.target` $\rightarrow$ `graphical.target`) $\rightarrow$ gestor de pantalla **SDDM** y escritorio **XFCE**.
- **Optimizaciones aplicadas e integradas en `install.sh`:**
  1. Reducción del tiempo de espera del menú de `systemd-boot` de `timeout 3` a `timeout 1` en `/boot/loader/loader.conf` (ahorro fijo de 2.0 s en la fase *loader*).
  2. Enmascaramiento (`systemctl mask`) de `NetworkManager-wait-online.service` para evitar bloqueos en la resolución de `network-online.target` cuando no hay servicios remotos críticos durante el inicio de sesión gráfico.
- **Procedimientos de recuperación validados:** Arranque interactivo en `rescue.target` y `emergency.target` mediante edición de parámetros del kernel en `systemd-boot`.

## 2. Concepto de SO
- **Firmware UEFI y Gestor de Arranque (`systemd-boot`):** En sistemas UEFI, el firmware inicializa el hardware y ejecuta directamente binarios EFI alojados en la partición ESP (`/boot`, FAT32). `systemd-boot` lee `/boot/loader/loader.conf` y las entradas en `/boot/loader/entries/*.conf` para cargar en memoria el kernel y el `initramfs` pasando el `PARTUUID` o `UUID` de la partición raíz.
- **Kernel e `initramfs` (`mkinitcpio`):** El kernel descomprime el `initramfs` en un sistema de archivos temporal en RAM (`rootfs`), ejecuta los *hooks* configurados en `/etc/mkinitcpio.conf` para cargar controladores de almacenamiento/video y montar la raíz real, y transfiere el control al PID 1 (`/sbin/init` $\rightarrow$ `systemd`) mediante `switch_root`.
- **Inicialización paralela con `systemd` y modos de recuperación:** `systemd` resuelve un grafo acíclico dirigido de dependencias entre unidades (`.service`, `.socket`, `.mount`, `.target`) hasta alcanzar `graphical.target`. Ante fallos del sistema, `systemd.unit=rescue.target` inicia en modo monousuario con sistemas de archivos montados (`rw`), mientras que `systemd.unit=emergency.target` entrega una consola mínima con `/` en solo lectura (`ro`) sin procesar `/etc/fstab` ni `sysinit.target`.

## 3. Método
1. **Inspección estática:** Se consultó el estado del gestor y los *hooks* del `initramfs` mediante `bootctl status`, `/boot/loader/loader.conf`, `/boot/loader/entries/arenalos-lts.conf`, `/etc/mkinitcpio.conf` y `systemctl list-units --type=target --state=active`.
2. **Medición Antes vs. Después:** En una VM con 2 vCPU, 4 GB de RAM y disco virtual SATA (`sda`), se realizaron **5 reinicios completos** antes de optimizar y **5 reinicios completos** tras aplicar los cambios, registrando en cada arranque `systemd-analyze`, `systemd-analyze blame` y `systemd-analyze critical-chain graphical.target`.
3. **Pruebas de recuperación:** Se interrumpió el menú de `systemd-boot` con la tecla `e` para arrancar explícitamente en `systemd.unit=rescue.target` y `systemd.unit=emergency.target`, verificando el estado de montaje de `/` con `findmnt /`.

## 4. Resultados

### 4.1 Configuración del bootloader e `initramfs`
```text
# /etc/mkinitcpio.conf
HOOKS=(base systemd autodetect microcode modconf kms keyboard sd-vconsole block filesystems fsck)
```
```text
# /boot/loader/loader.conf
default arenalos-lts.conf
timeout 1

# /boot/loader/entries/arenalos-lts.conf
title ArenalOS
linux /vmlinuz-linux-lts
initrd /initramfs-linux-lts.img
options root=UUID=33a26f4a-4658-4c51-882a-e4df7858b8d2 rw
```

### 4.2 Tiempos de arranque Antes de optimizar (5 corridas)
| Corrida | Kernel (s) | Initrd (s) | Userspace (s) | Total registrado por `systemd-analyze` (s) |
| :--- | :---: | :---: | :---: | :---: |
| 1 | 2.721 | 2.001 | 5.622 | 10.345 |
| 2 | 2.863 | 1.991 | 6.758 | 11.614 |
| 3 | 2.358 | 2.385 | 4.927 | 9.671 |
| 4 | 1.263 | 2.395 | 5.768 | 9.428 |
| 5 | 1.258 | 1.896 | 3.095 | 6.249 |
| **Promedio** | **2.093** | **2.134** | **5.234** | **9.461** |
| **Desv. estándar ($s$)** | **0.785** | **0.239** | **1.363** | **1.984** |

*(Nota: A este tiempo del SO se suman los 3.000 s fijos de espera configurados en `loader.conf`).*

### 4.3 Tiempos de arranque Después de optimizar (5 corridas)
| Corrida | Kernel (s) | Initrd (s) | Userspace (s) | Total registrado por `systemd-analyze` (s) |
| :--- | :---: | :---: | :---: | :---: |
| 1 | 1.045 | 1.631 | 3.997 | 6.673 |
| 2 | 1.608 | 3.094 | 4.815 | 9.518 |
| 3 | 1.247 | 1.698 | 4.005 | 6.951 |
| 4 | 1.781 | 1.646 | 5.078 | 8.506 |
| 5 | 1.074 | 2.160 | 3.930 | 7.165 |
| **Promedio** | **1.351** | **2.046** | **4.365** | **7.763** |
| **Desv. estándar ($s$)** | **0.328** | **0.625** | **0.538** | **1.199** |

*(Nota: Con `timeout 1`, la espera del bootloader baja a 1.000 s).*

### 4.4 Cadena crítica (`systemd-analyze critical-chain graphical.target` tras optimizar)
```text
graphical.target @3.926s
└─sddm.service @3.923s
  └─systemd-user-sessions.service @3.878s +36ms
    └─network.target @3.865s
      └─NetworkManager.service @3.297s +567ms
        └─basic.target @3.277s
          └─dbus-broker.service @3.139s +133ms
            └─dbus.socket @3.100s +97us
              └─sysinit.target @3.086s
                └─systemd-update-utmp.service @3.027s +52ms
                  └─systemd-tmpfiles-setup.service @2.689s +321ms
                    └─local-fs.target @2.628s
                      └─media-sf_arenalos.mount @3.708s
                        └─local-fs-pre.target @1.390s
                          └─systemd-tmpfiles-setup-dev.service @1.307s +79ms
                            └─systemd-tmpfiles-setup-dev-early.service @951ms +323ms
                              └─kmod-static-nodes.service @828ms +106ms
```

### 4.5 Procedimiento de recuperación en vivo (`rescue.target` y `emergency.target`)
1. Reiniciar el sistema y presionar `e` sobre la entrada `arenalos-lts.conf` en el menú de `systemd-boot`.
2. Añadir al final de la línea `options`:
   - `systemd.unit=rescue.target` $\rightarrow$ solicita contraseña de `root`, monta `/` en lectura/escritura (`rw`) y detiene la inicialización antes de red y entorno gráfico.
   - `systemd.unit=emergency.target` $\rightarrow$ solicita contraseña de `root`, mantiene `/` en solo lectura (`ro`) y omite `sysinit.target` y el montaje automático de `/etc/fstab` (para reparar errores de particiones se remonta con `mount -o remount,rw /`).

## 5. Interpretación
- **Impacto de la optimización:** El tiempo promedio del sistema operativo (`kernel + initrd + userspace`) disminuyó de **9.461 s** a **7.763 s** (una mejora de **1.698 s** o **17.95 %**), destacando la reducción en *userspace* de **5.234 s** a **4.365 s** (-16.6 %) y una mayor estabilidad entre corridas ($s$ bajó de 1.984 s a 1.199 s). Sumando la reducción del `timeout` de `systemd-boot` (de 3 s a 1 s), el tiempo total percibido desde el encendido hasta el login gráfico se redujo en **3.698 s** en promedio.
- **Análisis de cuellos de botella en VM:** Tanto `systemd-analyze blame` como `critical-chain` muestran que los mayores tiempos corresponden a la enumeración de dispositivos virtuales de VirtualBox (`dev-sda*.device`, ~3.2–4.9 s) y al montaje de la carpeta compartida (`media-sf_arenalos.mount`, ~3.67 s), seguidos por `NetworkManager.service` (~567 ms), lo cual explica la variabilidad entre reinicios provocada por la planificación de E/S del hipervisor anfitrión.