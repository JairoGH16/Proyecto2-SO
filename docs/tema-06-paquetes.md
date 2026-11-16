# Tema 6 · Gestión de paquetes

Responsable: Jairo González Hidalgo

## 1. Qué se implementó

- `pacman/arenalos-explicitos.hook`: hook de pacman (ALPM) que, después de cualquier transacción que instale o elimine paquetes, escribe en `/var/lib/arenalos/explicitos.txt` la lista de paquetes instalados explícitamente (`pacman -Qqe`). Se instala en `/etc/pacman.d/hooks/`. La idea parte del ejemplo de la sección *Pacman/Tips and tricks* de la ArchWiki.
- `pacman/PKGBUILD`: receta del paquete propio `arenalos-procesos` (versión 1.0-1, arquitectura `any`, depende de `python`), que empaqueta la herramienta del Tema 1 (`src/procesos/procesos.py`) como el comando `/usr/bin/arenalos-procesos`.
- `scripts/install-procesos-paquetes.sh`, llamado desde `install.sh` antes del mensaje final: instala el hook con `install -Dm644` en `/etc/pacman.d/hooks/`, construye `arenalos-procesos` con `makepkg` en una carpeta temporal como el usuario normal y lo instala con `pacman -U`. Así el hook y el paquete propio quedan instalados al ejecutar `install.sh`, sin pasos manuales.
- Documentación del funcionamiento interno de pacman, con evidencia medida: base de datos local y de sincronización, resolución de dependencias, verificación de firmas, hooks y transacciones (secciones 3 a 5).

## 2. Concepto de Sistemas Operativos

**Gestión de software instalado.** Un gestor de paquetes es una utilidad del sistema que instala, actualiza y elimina software de forma controlada. En Arch Linux lo hace `pacman`, apoyado en la biblioteca `libalpm`.

- **Base de datos de paquetes.** `pacman` mantiene una base de datos local (`/var/lib/pacman/local`, una carpeta por paquete con `desc`, `files` y `mtree`) y copias de las bases de datos de los repositorios (`/var/lib/pacman/sync`).
- **Resolución de dependencias.** Cada paquete declara de qué depende. Las dependencias forman un grafo dirigido; para instalar un paquete, `pacman` recorre el grafo, detecta lo que falta y ordena la instalación de modo que una dependencia siempre se instale antes que el paquete que la necesita (orden topológico). También detecta conflictos antes de tocar el disco.
- **Integridad y autenticidad.** Cada paquete trae su suma de verificación y una firma digital que `pacman` comprueba contra el llavero de claves de confianza (`pacman-key`), según el nivel de exigencia de `SigLevel` en `/etc/pacman.conf`.
- **Transacciones.** Una operación se ejecuta por fases (resolución, descarga, verificación de claves e integridad, conflictos de archivos, espacio en disco, instalación y hooks) y queda registrada en `/var/log/pacman.log`.
- **Hooks ALPM.** Son acciones que `pacman` ejecuta antes o después de una transacción cuando se cumple un disparador (operación, tipo y objetivo). Los del sistema viven en `/usr/share/libalpm/hooks` y los del administrador en `/etc/pacman.d/hooks`; se ejecutan en orden alfabético por nombre de archivo. El formato está en `alpm-hooks(5)`.
- **Empaquetado.** `PKGBUILD` y `makepkg` construyen un paquete a partir de una receta; el paquete se instala con `pacman -U`.

**Relación con la bibliografía.** Los libros del curso no tratan la gestión de paquetes como tema propio; el concepto se sustenta en tres partes:

- Silberschatz, A., Galvin, P. B. y Gagne, G. *Operating System Concepts*, 10.ª edición, Wiley. Capítulo 2, sección 2.4, «System Services» (utilidades del sistema entre el sistema operativo y los programas de aplicación), y sección 2.5, «Linkers and Loaders» (las bibliotecas compartidas de las que depende un programa, que son las dependencias que `pacman` también declara y resuelve, como `libcrypto.so`).
- El mismo libro, capítulo 16, sección 16.4, «Cryptography as a Security Tool»: sumas de verificación y firmas digitales, que son el mecanismo con que `pacman` comprueba la autenticidad de los paquetes.
- Documentación de pacman: ArchWiki, *pacman* y *Pacman/Tips and tricks*; páginas del manual `pacman(8)`, `alpm-hooks(5)`, `PKGBUILD(5)`, `makepkg(8)` y `pactree(8)`.

## 3. Método de medición

**Entorno.** VM de ArenalOS (`arenalos-jairo`) en VirtualBox, con 4 GB de RAM (3889 MB según `free -m`), 2 vCPU y disco dinámico de 20 GB; Arch Linux con kernel 6.18.62-1-lts y pacman con los repositorios `core` y `extra`.

**Exploración** (paso 15), con la salida guardada en `docs/logs/tema-06/exploracion.txt`:

```bash
ls /var/lib/pacman/local | wc -l
ls /var/lib/pacman/local/sudo-*
ls -l /var/lib/pacman/sync
grep -E '^(SigLevel|LocalFileSigLevel)' /etc/pacman.conf
sudo pacman-key --list-keys | head -8
ls /usr/share/libalpm/hooks /etc/pacman.d/hooks
pacman -Qi sudo; pacman -Ql sudo | head -10; pacman -Qo /usr/bin/sudo
```

**Árbol de dependencias** (paso 16), guardado en `docs/logs/tema-06/pactree-sudo.txt` y `pactree-nano.txt`:

```bash
pactree sudo
pactree nano
pactree -r glibc | head -15
```

**Prueba del hook con una transacción real** (paso 18), guardada en `docs/logs/tema-06/hook.txt`: copiar el hook a `/etc/pacman.d/hooks/`, instalar `tree` con `sudo pacman -S --noconfirm tree`, revisar `/var/log/pacman.log` y `/var/lib/arenalos/explicitos.txt`, y luego quitar `tree` con `sudo pacman -R --noconfirm tree` y revisar de nuevo.

**Costo del hook** (paso 19), guardado en `docs/logs/tema-06/costo-hook.txt`: el comando que el hook agrega a cada transacción, medido 5 veces con el tiempo real transcurrido:

```bash
TIMEFORMAT='%R s'
for i in 1 2 3 4 5; do time pacman -Qqe > /dev/null; done
```

**Paquete propio** (pasos 20 y 21), guardado en `docs/logs/tema-06/paquete-propio.txt`: como `makepkg` no corre como root ni lee la carpeta compartida (de `root:vboxsf`), se copian `PKGBUILD` y `procesos.py` a `~/build-arenalos`, se construye con `makepkg -f`, se instala con `sudo pacman -U --noconfirm arenalos-procesos-1.0-1-any.pkg.tar.zst`, se verifica con `pacman -Qi`, `pacman -Ql` y `pacman -Qo`, y se desinstala con `sudo pacman -R --noconfirm arenalos-procesos`.

**Lista declarada frente a instalada** (paso 22): comparación con `comm` entre `pkglist.txt` (sin comentarios) y `explicitos.txt`.

## 4. Resultados

### 4.1 Base de datos y firmas

| Dato | Valor |
|---|---|
| Paquetes instalados (`/var/lib/pacman/local`) | 409 |
| Archivos por paquete (ejemplo `sudo`) | `desc`, `files`, `mtree` |
| Bases de datos de sincronización | `core.db` (130 KB) y `extra.db` (9 MB) |
| `SigLevel` | `Required DatabaseOptional` |
| `LocalFileSigLevel` | `Optional` |
| Hooks del sistema en `/usr/share/libalpm/hooks` | 42 |
| `/etc/pacman.d/hooks` antes de la prueba | no existía |

`pacman -Qi sudo` muestra versión 1.9.17.p2-7, 7,85 MiB, instalado explícitamente, `Depends On : glibc openssl pam libldap zlib libcrypto.so=4-64 libssl.so=4-64`, `Required By : base-devel` y `Validated By : Signature`. `pacman -Ql sudo` lista sus archivos y `pacman -Qo /usr/bin/sudo` confirma el paquete al que pertenece el ejecutable.

### 4.2 Árbol de dependencias

| Paquete | Dependencias directas | Líneas del árbol |
|---|---|---|
| `sudo` | 7: `glibc`, `openssl`, `pam`, `libldap`, `zlib`, `libcrypto.so`, `libssl.so` | más de 100 |
| `nano` | 3: `ncurses`, `file`, `glibc` | 45 |

La cadena más larga de `nano` es `nano → file → bzip2 → bash → readline → ncurses → glibc`; la de `sudo` baja a `sudo → pam → audit → krb5 → libldap → libsasl → gdbm → readline → ncurses`. `glibc` aparece en casi todas las ramas, y `pactree -r glibc` muestra que de él dependen `acl`, `coreutils`, `curl`, `pacman` y muchos más. Los árboles completos están en `docs/logs/tema-06/`.

### 4.3 Hook propio con transacciones reales

| Operación sobre `tree` | ¿Corrió `arenalos-explicitos.hook`? | Paquetes explícitos |
|---|---|---|
| Instalar (22:15:51) | Sí | 30 → 31 |
| Reinstalar (22:17:45) | No | 31 → 31 |
| Quitar (22:17:46) | Sí | 31 → 30 |

En la instalación pacman imprimió `(2/2) ArenalOS: actualizando la lista de paquetes explicitos` y el log registra `[ALPM] running 'arenalos-explicitos.hook'...` justo después de `35-systemd-update.hook`. Con la instalación de `arenalos-procesos` con `pacman -U` el hook también corrió, y el paquete figuró en `explicitos.txt`; al desinstalarlo corrió otra vez y desapareció.

### 4.4 Costo del hook

| Repetición | 1 | 2 | 3 | 4 | 5 | Promedio |
|---|---|---|---|---|---|---|
| `pacman -Qqe` (s) | 0,071 | 0,057 | 0,040 | 0,045 | 0,032 | **0,049** |

En `pacman.log` las transacciones de reinstalación y de desinstalación de `tree` empiezan y terminan dentro del mismo segundo, de modo que duran menos de aproximadamente 1 s.

### 4.5 Paquete propio `arenalos-procesos`

| Dato (`pacman -Qi`) | Valor |
|---|---|
| Versión / arquitectura | 1.0-1 / `any` |
| `Depends On` | `python` |
| Tamaño instalado | 3,99 KiB |
| Motivo de instalación | explícito |
| `Validated By` | `None` (paquete local sin firma) |
| `Packager` | `Unknown Packager` |
| Archivos (`pacman -Ql`) | `/usr/`, `/usr/bin/`, `/usr/bin/arenalos-procesos` |

`arenalos-procesos --top 5` funciona como comando. Tras `pacman -R` el archivo `/usr/bin/arenalos-procesos` ya no existe y el paquete salió de `explicitos.txt`.

### 4.6 Lista declarada frente a instalada

- **Explícitos que no están en `pkglist.txt` (22):** los del `pacstrap` de la Fase 1 (`base`, `linux-lts`, `linux-firmware`, `mkinitcpio`, `nano`, `networkmanager`, `sudo`), las Guest Additions (`virtualbox-guest-utils`) y los 14 miembros del grupo `xfce4` (`exo`, `garcon`, `thunar`, `thunar-volman`, `tumbler`, `xfce4-appfinder`, `xfce4-panel`, `xfce4-power-manager`, `xfce4-session`, `xfce4-settings`, `xfce4-terminal`, `xfconf`, `xfdesktop` y `xfwm4`).
- **En `pkglist.txt` pero no instalados explícitamente (3):** `xfce4`, `python` y `xorg-xrandr`. Con `pacman -Qi` se comprobó que `python` está instalado como dependencia de `gdb` y `gdb-common`, y `xorg-xrandr` como dependencia de `virtualbox-guest-utils`.

## 5. Interpretación

**Qué hace pacman por dentro.** Los datos muestran cada pieza del mecanismo. La base de datos local es un directorio por paquete con metadatos, lista de archivos y sumas de verificación (409 paquetes en esta VM). Las bases de sincronización, que solo incluyen `core` y `extra`, son los catálogos con los que se resuelven las dependencias antes de instalar. Los árboles de `pactree` muestran que la resolución es un recorrido de un grafo: instalar `nano` exige `glibc` antes que `ncurses` y `file`, y a su vez `linux-api-headers`, `tzdata` y `filesystem` antes que `glibc`. Una dependencia debe estar instalada antes que el paquete que la necesita, y por eso `pacman` ordena los paquetes recorriendo el grafo y rechaza quitar `glibc` mientras otros dependan de él. `sudo` tiene 7 dependencias directas pero un árbol de más de cien líneas, porque las dependencias se encadenan y se comparten entre ramas (por eso `glibc` y `bash` se repiten).

**Integridad y autenticidad.** Con `SigLevel = Required DatabaseOptional` todo paquete de un repositorio debe traer una firma válida de una clave de confianza; `sudo` lo muestra con `Validated By : Signature`. `LocalFileSigLevel = Optional` permite instalar con `pacman -U` un archivo local sin firma, como el paquete propio (`Validated By : None`): `pacman` igual comprueba las claves y la integridad del archivo, pero no exige una firma, y un paquete construido en la propia máquina no la tiene.

**El hook.** El hook propio se ejecuta cuando cambia el conjunto de paquetes instalados y no cuando se reinstala uno: en la reinstalación de `tree` solo corrió `35-systemd-update.hook`, y el nuestro no, lo que es coherente con que `libalpm` trate la reinstalación como una operación de actualización (`Upgrade`) y no de instalación; como una reinstalación no cambia qué paquetes están instalados, la lista queda igual (31) y no hace falta que el hook corra. Los hooks de una misma fase se ejecutan en orden alfabético por nombre de archivo, de ahí que `35-systemd-update.hook` corra antes que `arenalos-explicitos.hook`. En cuanto al costo, el comando que agrega el hook tarda unos 0,05 s (entre 0,032 y 0,071 s; la primera lectura fue la más lenta por la caché del disco), frente a transacciones que duran del orden de 1 s o más, por lo que el costo es despreciable y casi constante, ya que depende de cuántos paquetes hay instalados (409) y no de cuántos se instalan.

**El paquete propio.** `makepkg` construyó un paquete `any`, porque el contenido es un script sin código compilado. El paquete instala un único archivo y declara `python` como dependencia, que es lo que `pacman` usa para resolverla. Las dos diferencias con `sudo` son esperables: no está firmado y no define empaquetador (`Unknown Packager`), porque ni el `PKGBUILD` ni `/etc/makepkg.conf` lo establecen.

**La lista declarada no coincide exactamente con la instalada, y eso es normal.** `xfce4` es un grupo de paquetes y no un paquete: `pacman -Qqe` nunca lo lista, solo a sus miembros (que por eso salen en la primera lista). `python` y `xorg-xrandr` sí están instalados, pero como dependencias de otros paquetes, y `install.sh` usa `pacman -S --needed`, que se salta lo ya instalado y no cambia su motivo de instalación a explícito. La comparación directa por nombres sirve entonces como una verificación aproximada; para una exacta habría que expandir los grupos (`pacman -Sgq xfce4`) y comprobar contra todos los paquetes instalados (`pacman -Qq`).

**Limitaciones.** El costo del hook se midió como el comando suelto y no como diferencia entre una transacción completa con y sin hook, y el registro de pacman tiene resolución de un segundo. Todo se midió en una sola VM, con una única instalación de cada paquete de prueba.
