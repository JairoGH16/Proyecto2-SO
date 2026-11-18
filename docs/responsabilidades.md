# Matriz de responsabilidades

## Capa 2 · Temas

| Tema / módulo                     | Responsable principal | Apoyo     | Ruta en el repositorio                              | Ficha de evidencia                |
|-----------------------------------|-----------------------|-----------|-----------------------------------------------------|-----------------------------------|
| Tema 1 · Procesos y planificación | Jairo                 | Sebastián | `src/procesos/`, `scripts/experimento-{nice,rt}.sh` | `docs/tema-01-procesos.md`        |
| Tema 2 · Memoria                  | Rafael                | Jairo     | `src/memoria/`, `scripts/experimento-memoria.sh`    | `docs/tema-02-memoria.md`         |
| Tema 4 · Gestión de servicios     | Rafael                | Esteban   | `systemd/`                                          | `docs/tema-04-servicios.md`       |
| Tema 5 · Concurrencia e IPC       | Sebastián             | Rafael    | `src/ipc/`                                          | `docs/tema-05-ipc.md`             |
| Tema 6 · Gestión de paquetes      | Jairo                 | Sebastián | `pacman/`, `scripts/install-procesos-paquetes.sh`   | `docs/tema-06-paquetes.md`        |
| Tema 7 · Proceso de arranque      | Sebastián             | Esteban   | bloque del Tema 7 en `install.sh`                   | `docs/tema-07-arranque.md`        |
| Tema 8 · E/S y dispositivos       | Esteban               | Jairo     | `udev/`                                             | `docs/tema-08-es-dispositivos.md` |
| Tema 9 · Protección y seguridad   | Esteban               | Rafael    | `security/`                                         | `docs/tema-09-seguridad.md`       |

## Capa 3 · Comandos y atajos libres

Cada integrante diseñó 2 comandos libres y 3 atajos. Los comandos están documentados en [`comandos.md`](comandos.md) y los atajos en [`cheatsheet.md`](cheatsheet.md).

| Integrante | Comandos libres (`bin/`)            | Atajos libres                                 | Instalador de los comandos                           |
|------------|-------------------------------------|-----------------------------------------------|------------------------------------------------------|
| Jairo      | `cambios-contexto`, `presion-cpu`   | `Super + T`, `Super + C`, `Super + O`         | `scripts/install-comandos-capa3.sh`                  |
| Rafael     | `riesgo-oom`, `servicios-limites`   | `Super + Y`, `Super + S`, `Super + K`         | `scripts/install-comandos-memoria-servicios.sh`      |
| Sebastián  | `ipc-activo`, `arranque-info`       | `Super + B`, `Super + I`, `Super + A`         | `scripts/install-comandos-ipc-arranque.sh`           |
| Esteban    | `usb-historial`, `puertos-abiertos` | `Super + U`, `Super + Shift + P`, `Super + M` | `scripts/install-comandos-seguridad-dispositivos.sh` |
