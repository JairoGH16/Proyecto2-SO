# Bitácora de instalación · ArenalOS

Instalación manual de Arch Linux (ArenalOS) en una máquina virtual, en modo UEFI. Cada comando va con el porqué de su uso. No se usó `archinstall` ni ningún script de instalación de terceros: todo se hizo a mano desde la consola de la VM.

## Decisiones de partida

| Aspecto | Decisión | Por qué |
| --- | --- | --- |
| Hipervisor | Oracle VirtualBox | Permite snapshots para volver atrás si la instalación sale mal. |
| VM | 4 GB de RAM, 2 vCPU, disco dinámico de 20 GB, UEFI, red NAT | Cumple el mínimo del enunciado (2 vCPU, 4 GB) y el disco dinámico solo ocupa el espacio que se usa. NAT da internet sin configurar nada. |
| Particiones (GPT) | ESP de 1 GiB en `/boot`, `/home` de 4 GiB, raíz con el resto (~15 GiB) | La raíz va de última para poder ampliarla o reducirla sin mover otras particiones. |
| Sistemas de archivos | ESP en FAT32, `/home` y raíz en ext4 | El firmware UEFI solo lee FAT32 en la ESP. ext4 es estable y simple. |
| Bootloader | systemd-boot | Solo UEFI, configuración en archivos pequeños e integrado con systemd (`bootctl`). |
| Kernel | `linux-lts` | Cambia menos que `linux`, así las 4 instalaciones tienen el mismo kernel y las mediciones se pueden repetir. Cumple EEVDF (kernel ≥ 6.6). |
| Paquetes del `pacstrap` | `base linux-lts linux-firmware mkinitcpio sudo networkmanager nano` | Lo mínimo para arrancar, tener red, usar `sudo` y editar archivos. |
| Idioma y zona | `en_US.UTF-8`, teclado `la-latin1`, `America/Costa_Rica` | La salida de las herramientas queda en inglés, lo que evita que se rompan scripts que la leen. |
| Cuentas | root con contraseña y usuario `user` en `wheel` con `sudo` | Los modos de rescate y emergencia (Tema 7) piden la contraseña de root. |
| Hostname | `arenalos-<nombre>`, uno por integrante | Distingue las máquinas en los registros y en la red. |
| Swap | No se crea en esta fase | Se crea como swapfile en el Tema 2. |

## 1. Preparar la VM

**1. Descargar la ISO y su checksum.**

```bash
wget https://fastly.mirror.pkgbuild.com/iso/2026.11.01/archlinux-2026.11.01-x86_64.iso
wget https://fastly.mirror.pkgbuild.com/iso/2026.11.01/sha256sums.txt
```

Por qué: la ISO se publica junto a su hash para poder comprobar que no está corrupta ni alterada.

**2. Verificar el checksum.**

```bash
sha256sum -c --ignore-missing sha256sums.txt
```

Por qué: compara el hash real de la ISO con el publicado y debe imprimir `archlinux-2026.11.01-x86_64.iso: OK`.

**3. Crear la VM en VirtualBox** (Máquina → Nueva). Valores usados:

- Nombre `ArenalOS`, tipo Linux, distribución Arch Linux, versión Arch Linux (64-bit), con la ISO descargada.
- *Proceed with Unattended Installation* sin marcar.
- 4096 MB de memoria, 2 CPU, disco de 20 GB, *Use EFI* marcado.

Por qué: EFI es necesario para systemd-boot y para que el arranque estudiado sea el de los equipos actuales. La instalación desatendida haría el trabajo que el proyecto exige hacer a mano.

**4. Revisar la configuración.** Habilitar EFI activo, Secure Boot desactivado y red en NAT.

Por qué: Secure Boot impediría arrancar el medio de instalación sin firmar, y NAT da internet para que `pacstrap` pueda descargar paquetes.

**5. Snapshot `inicial`** (VM creada, sin encender).

Por qué: si la instalación sale mal, se vuelve a una VM limpia en segundos.

## 2. Instalar Arch a mano (desde el entorno live)

**6. Arrancar la ISO**, entrada *Arch Linux install medium (x86_64, UEFI)*.

Por qué: es la entrada que carga el medio de instalación en modo UEFI.

**7. Confirmar modo UEFI.**

```bash
cat /sys/firmware/efi/fw_platform_size
```

Por qué: si el archivo existe y dice `64`, el firmware arrancó en UEFI de 64 bits. Si no existe, la VM arrancó en BIOS y la instalación no serviría.

**8. Teclado y reloj.**

```bash
loadkeys la-latin1
timedatectl
```

Por qué: el teclado latinoamericano evita errores con símbolos como `/`, `|` o `-`. `timedatectl` confirma que el reloj se sincroniza.

**9. Comprobar la red.**

```bash
ping -c 3 archlinux.org
```

Por qué: `pacstrap` descarga los paquetes y con NAT debe funcionar sin configurar nada.

**10. Identificar el disco.**

```bash
lsblk
```

Por qué: muestra los dispositivos y confirma que el disco (`sda`, 20G) no tiene particiones, antes de escribir sobre él.

**11. Particionar con `fdisk`.**

```bash
fdisk /dev/sda
```

Dentro de `fdisk`, una acción a la vez:

1. `g`: crea una tabla de particiones GPT.
2. `n`, Enter, Enter, `+1G`: partición 1 (ESP) de 1 GiB.
3. `t`, `uefi`: marca la partición 1 como *EFI System*.
4. `n`, Enter, Enter, `+4G`: partición 2 (`/home`) de 4 GiB.
5. `n`, Enter, Enter, Enter: partición 3 (raíz) con todo el espacio restante.
6. `p`: muestra la tabla para revisarla antes de escribir.
7. `w`: escribe los cambios en el disco y sale.

Por qué: UEFI exige GPT y una partición ESP. `/home` aparte conserva los datos del usuario si hay que reinstalar la raíz. La raíz va de última para poder redimensionarla.

**12. Formatear.**

```bash
mkfs.fat -F 32 /dev/sda1
mkfs.ext4 /dev/sda2
mkfs.ext4 /dev/sda3
```

Por qué: la ESP debe ser FAT32 para que el firmware UEFI la lea. `/home` y la raíz usan ext4.

**13. Montar en `/mnt`.**

```bash
mount /dev/sda3 /mnt
mount --mkdir /dev/sda1 /mnt/boot
mount --mkdir /dev/sda2 /mnt/home
```

Por qué: primero va la raíz y después las demás. Si `/boot` se montara antes, el montaje de la raíz lo taparía. `--mkdir` crea los puntos de montaje que faltan.

**14. Instalar el sistema base.**

```bash
pacstrap -K /mnt base linux-lts linux-firmware mkinitcpio sudo networkmanager nano
```

Por qué: instala en el disco lo mínimo para arrancar y administrarse. `-K` inicializa el llavero de claves de pacman en el sistema nuevo para verificar firmas de paquetes.

**15. Generar y revisar el fstab.**

```bash
genfstab -U /mnt >> /mnt/etc/fstab
nano /mnt/etc/fstab
```

Por qué: `genfstab -U` escribe las entradas de montaje identificando las particiones por UUID, que no cambia aunque cambie el nombre del dispositivo. Se revisó que hubiera 3 entradas (raíz, `/boot`, `/home`) y en la de `/boot` se cambió `fmask=0022,dmask=0022` por `fmask=0077,dmask=0077`, para que la ESP no sea legible por cualquier usuario. Se guardó con `Ctrl + O` y se cerró con `Ctrl + X`.

**16. Entrar al sistema nuevo.**

```bash
arch-chroot /mnt
```

Por qué: desde aquí los comandos configuran el disco instalado, no el medio live.

**17. Zona horaria y reloj.**

```bash
ln -sf /usr/share/zoneinfo/America/Costa_Rica /etc/localtime
hwclock --systohc
```

Por qué: fija la hora local y guarda la hora del sistema en el reloj de hardware.

**18. Idioma y teclado de la consola.** En `/etc/locale.gen` se quitó el `#` de la línea `en_US.UTF-8 UTF-8` y luego:

```bash
locale-gen
echo "LANG=en_US.UTF-8" > /etc/locale.conf
echo "KEYMAP=la-latin1" > /etc/vconsole.conf
```

Por qué: `locale-gen` solo compila los idiomas habilitados. `locale.conf` fija el idioma del sistema y `vconsole.conf` hace permanente el teclado latinoamericano.

**19. Hostname.**

```bash
echo "arenalos-<nombre>" > /etc/hostname
```

Por qué: identifica la máquina en la red y en los registros. Cada integrante usó el suyo (`arenalos-jairo`, `arenalos-rafael`, `arenalos-sebastian`, `arenalos-esteban`).

**20. Contraseña de root.**

```bash
passwd
```

Por qué: los modos de rescate y emergencia (Tema 7) piden la contraseña de root.

**21. Usuario con `sudo`.**

```bash
useradd -m -G wheel -s /bin/bash user
passwd user
EDITOR=nano visudo
```

En `visudo` se quitó el `#` de la línea `%wheel ALL=(ALL:ALL) ALL`.

Por qué: el trabajo diario se hace sin ser root. `-m` crea la carpeta personal, `-G wheel` agrega al usuario al grupo autorizado a usar `sudo` y `visudo` es la forma segura de editar los permisos de `sudo` porque revisa que no queden errores.

**22. Generar el initramfs.**

```bash
mkinitcpio -P
ls /boot
```

Por qué: el initramfs es el mini sistema que carga los controladores necesarios para montar la raíz durante el arranque. `-P` lo genera para todos los kernels instalados. En `/boot` aparecen `vmlinuz-linux-lts` e `initramfs-linux-lts.img`.

**23. Instalar systemd-boot.**

```bash
bootctl install
cat /sys/firmware/efi/fw_platform_size
```

Por qué: copia el gestor de arranque a la ESP (`/boot/EFI/systemd/` y `/boot/EFI/BOOT/BOOTX64.EFI`) y crea las carpetas `loader`. El segundo comando vuelve a confirmar que se está en UEFI (`64`).

**24. Configurar el gestor.**

```bash
cat > /boot/loader/loader.conf <<EOF
default arenalos-lts.conf
timeout 3
EOF

cat > /boot/loader/entries/arenalos-lts.conf <<EOF
title   ArenalOS
linux   /vmlinuz-linux-lts
initrd  /initramfs-linux-lts.img
options root=UUID=$(blkid -s UUID -o value /dev/sda3) rw
EOF

cat /boot/loader/entries/arenalos-lts.conf
```

Por qué: `loader.conf` elige la entrada por defecto y el tiempo del menú, y `arenalos-lts.conf` indica qué kernel, qué initramfs y qué partición raíz usar (por UUID). El último comando comprueba que el UUID se haya resuelto. No se agregó `editor no` porque en el Tema 7 se editarán parámetros del kernel desde este menú.

**25. Habilitar la red.**

```bash
systemctl enable NetworkManager
```

Por qué: sin esto el sistema instalado arranca sin red.

**26. Salir, desmontar y apagar.**

```bash
exit
umount -R /mnt
poweroff
```

Por qué: `exit` sale del chroot y `umount -R` desmonta todo para asegurar que lo escrito llegó al disco antes de apagar.

**27. Quitar la ISO.** Con la VM apagada: Configuración → Almacenamiento → *Remove Disk from Virtual Drive* sobre la ISO.

Por qué: si la ISO sigue puesta, la VM puede volver a arrancar el instalador. Con EFI no hace falta cambiar el orden de arranque, porque el firmware busca el sistema en el disco.

## 3. Primer arranque y evidencia

**28. Primer arranque.** Aparece el menú de systemd-boot con la entrada ArenalOS y luego el login.

**29. Iniciar sesión y probar la red.** Login con `user` y la contraseña del paso 21, y luego:

```bash
ping -c 3 archlinux.org
```

Por qué: confirma que NetworkManager arrancó y que el usuario y su contraseña funcionan.

**30. Evidencia de la instalación.**

```bash
lsblk -f
cat /etc/fstab
sudo bootctl status
journalctl --list-boots
```

Por qué: son las salidas que pide el enunciado como evidencia. `lsblk -f` muestra las particiones y sistemas de archivos, `/etc/fstab` los montajes, `bootctl status` el bootloader y el modo UEFI, y `journalctl --list-boots` los arranques registrados. Las capturas de cada integrante están en `docs/logs/<nombre>/` (`01-lsblk.png`, `02-fstab.png`, `03-bootctl-status.png` y `04-journalctl-list-boots.png`).

**31. Snapshot `base instalada`.** Se apagó con `sudo poweroff` y se tomó la instantánea.

Por qué: es el punto de partida limpio para la siguiente fase y para volver atrás si algo se rompe.

## Problemas encontrados y cómo se resolvieron

| Problema | Cómo se resolvió |
| --- | --- |
| Durante la instalación, en la consola de la VM, los caracteres escritos dejaron de verse hasta presionar Enter. La causa es desconocida, pero probablemente fue algún detalle de Oracle VirtualBox que desconocemos. | Se cerró la VM y se volvió a abrir. |
