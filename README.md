# ArenalOS

ArenalOS es una distribución personalizada sobre Arch Linux, hecha para el proyecto 2 del curso de Sistemas Operativos (IC-6600) del TEC. Se instala a mano en una máquina virtual de VirtualBox y luego se configura con un solo instalador, `install.sh`, que deja el escritorio XFCE y lo que cada integrante hizo para los temas del curso.

## Equipo

| Integrante | Temas de la Capa 2                                              |
|------------|-----------------------------------------------------------------|
| Jairo      | Tema 1 · Procesos y planificación, Tema 6 · Gestión de paquetes |
| Rafael     | Tema 2 · Memoria, Tema 4 · Gestión de servicios                 |
| Sebastián  | Tema 5 · Concurrencia e IPC, Tema 7 · Proceso de arranque       |
| Esteban    | Tema 8 · E/S y dispositivos, Tema 9 · Protección y seguridad    |

El detalle de quién hizo cada parte está en [`docs/responsabilidades.md`](docs/responsabilidades.md).

## Capas

| Capa                       | Qué es                                                                                        | Dónde está                                                                                                                              |
|----------------------------|-----------------------------------------------------------------------------------------------|-----------------------------------------------------------------------------------------------------------------------------------------|
| Capa 1 · Base              | Arch instalado a mano en modo UEFI con systemd-boot y `linux-lts`, y escritorio XFCE con SDDM | [`docs/instalacion.md`](docs/instalacion.md), [`docs/justificacion-de-escritorio.md`](docs/justificacion-de-escritorio.md), `dotfiles/` |
| Capa 2 · Temas             | Un módulo por tema del curso, cada uno con su instalador y su ficha de evidencia medida       | `docs/tema-0X-*.md`                                                                                                                     |
| Capa 3 · Comandos y atajos | `midistro-info`, 2 comandos libres y 3 atajos por integrante                                  | [`docs/comandos.md`](docs/comandos.md), [`docs/cheatsheet.md`](docs/cheatsheet.md)                                                      |

## Cómo instalar

1. Instalar Arch a mano siguiendo [`docs/instalacion.md`](docs/instalacion.md) (pasos 1 a 31).
2. Instalar las Guest Additions y compartir el clon de este repositorio con la VM como carpeta `arenalos` (paso 32). Queda en `/media/sf_arenalos`.
3. Desde la cuenta normal de la VM:

   ```bash
   sudo bash /media/sf_arenalos/install.sh
   ```

4. Reiniciar y entrar a XFCE desde SDDM.

`install.sh` se puede correr más de una vez sin problema. Qué instala en cada paso está en la sección 4 de [`docs/instalacion.md`](docs/instalacion.md). Antes de correrlo, ojo: el Tema 9 deja SSH solo con llave.

## Uso

- `midistro-info` muestra un resumen del sistema: kernel, uptime, CPU, GPU y NPU con su driver, memoria, swap y zram, procesos, planificador y sistema de archivos raíz.
- Los demás comandos están en [`docs/comandos.md`](docs/comandos.md).
- Los atajos de teclado (`Super + Enter` abre una terminal, `Super + D` el launcher, `Super + Q` cierra la ventana, `Super + 1` … `Super + 9` cambia de workspace, y 12 atajos más) están en [`docs/cheatsheet.md`](docs/cheatsheet.md).

## Estructura del repositorio

| Ruta          | Contenido                                                                                                 |
|---------------|-----------------------------------------------------------------------------------------------------------|
| `install.sh`  | Instalador de ArenalOS: escritorio, temas y comandos                                                      |
| `pkglist.txt` | Paquetes que instala `install.sh`, con una sección por tema                                               |
| `bin/`        | Comandos de la Capa 3                                                                                     |
| `src/`        | Herramientas de los temas (`procesos/`, `memoria/`, `ipc/`) y módulos de `midistro-info`                  |
| `pacman/`     | Hook de pacman y recetas `PKGBUILD` de los paquetes propios (Tema 6)                                      |
| `systemd/`    | Servicio y timer `arenalos-memlog` (Tema 4)                                                               |
| `udev/`       | Lista negra de módulos y regla udev de las USB (Tema 8)                                                   |
| `security/`   | Usuarios, ACL, sudoers, SSH y firewall (Tema 9)                                                           |
| `scripts/`    | Instaladores de cada parte y scripts de los experimentos                                                  |
| `dotfiles/`   | Configuración de XFCE (atajos, panel, workspaces, fondo) y la foto del volcán Arenal                      |
| `docs/`       | Fichas de los temas, instalación, comandos, atajos, responsabilidades, bitácora de IA y logs de evidencia |

## Uso de IA

Las consultas a herramientas de IA, con sus errores y cómo se validaron, están en [`docs/bitacora_ia.md`](docs/bitacora_ia.md), con una sección por integrante.
