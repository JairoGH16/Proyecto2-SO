# Cheatsheet de atajos de ArenalOS

Atajos de XFCE versionados en [`dotfiles/xfce/xfconf/xfce-perchannel-xml/xfce4-keyboard-shortcuts.xml`](../dotfiles/xfce/xfconf/xfce-perchannel-xml/xfce4-keyboard-shortcuts.xml) (lanzadores) y `xfwm4` (acciones de ventana). El `install.sh` los copia a `~/.config/xfce4/xfconf/` del usuario.

Los 4 primeros son los obligatorios del enunciado; los otros 12 son los libres, 3 por integrante.

| Atajo                     | Qué hace                                               | Por qué es útil                                                                                                                              | Relación                  | Diseñó    |
|---------------------------|--------------------------------------------------------|----------------------------------------------------------------------------------------------------------------------------------------------|---------------------------|-----------|
| `Super + Enter`           | Abre una terminal (`xfce4-terminal`)                   | Obligatorio                                                                                                                                  | Escritorio (Fase 2)       | Equipo    |
| `Super + Q`               | Cierra la ventana activa                               | Obligatorio                                                                                                                                  | Escritorio (Fase 2)       | Equipo    |
| `Super + D`               | Abre el launcher de aplicaciones (`xfce4-appfinder`)   | Obligatorio                                                                                                                                  | Escritorio (Fase 2)       | Equipo    |
| `Super + 1` … `Super + 9` | Cambia al workspace con ese número (hay 9)             | Obligatorio                                                                                                                                  | Escritorio (Fase 2)       | Equipo    |
| `Super + T`               | Abre una terminal con `arenalos-procesos --top 15`     | Ver los procesos que más CPU usan, con estado, `nice` y política                                                                             | Función de la Capa 2 · T1 | Jairo     |
| `Super + C`               | Abre una terminal con `cambios-contexto -n 15 -t 2`    | Ver qué procesos compiten por la CPU (cambios involuntarios)                                                                                 | Comando propio · T1       | Jairo     |
| `Super + O`               | Abre una terminal con `presion-cpu -t 3`               | Saber si el sistema está saturado (PSI)                                                                                                      | Comando propio · T1       | Jairo     |
| `Super + Y`               | Abre una terminal con `memoria --top 15`               | Ver en vivo memoria, swap, zram y fallos de página por proceso                                                                               | Función de la Capa 2 · T2 | Rafael    |
| `Super + S`               | Abre una terminal con `servicios-limites -a`           | Ver los límites de CPU y memoria de cada servicio y si el kernel lo frena                                                                    | Comando propio · T4       | Rafael    |
| `Super + K`               | Abre una terminal con `riesgo-oom -n 15`               | Saber qué procesos mataría primero el OOM killer                                                                                             | Comando propio · T2       | Rafael    |
| `Super + B`               | Abre una terminal con `arranque-info`                  | Ver cómo arrancó la máquina: UEFI, gestor, parámetros y tiempos                                                                              | Comando propio · T7       | Sebastián |
| `Super + I`               | Abre una terminal con `ipc-activo`                     | Ver qué sockets Unix, pipes y memoria compartida hay abiertos                                                                                | Comando propio · T5       | Sebastián |
| `Super + A`               | Abre una terminal con `systemd-analyze critical-chain` | Ver la cadena crítica del arranque                                                                                                           | Función de la Capa 2 · T7 | Sebastián |
| `Super + U`               | Abre una terminal con `usb-historial -n 20`            | Ver de un vistazo qué dispositivos USB están conectados, si una memoria quedó montada en solo lectura y las últimas conexiones/desconexiones | Comando propio · T8       | Esteban   |
| `Super + Shift + P`       | Abre una terminal con `sudo puertos-abiertos`          | Auditar qué puertos escuchan, qué proceso los tiene y si el firewall los deja pasar. `Super + P` ya lo usa XFCE para pantallas               | Comando propio · T9       | Esteban   |
| `Super + M`               | Abre una terminal con `journalctl -f -t arenalos-usb`  | Ver **en vivo** lo que registra la regla udev del Tema 8 al conectar o desconectar una USB                                                   | Función de la Capa 2 · T8 | Esteban   |

**Cómo se cierran las terminales.**
- Quedan abiertas (`--hold`) para poder leer la salida y se cierran con `Super + Q`: `Super + T`, `Super + C`, `Super + O`, `Super + S`, `Super + K`, `Super + B`, `Super + I`, `Super + A`, `Super + U` y `Super + Shift + P`.
- `Super + Y` (`memoria --top 15`) se refresca sola y se detiene con `Ctrl + C`.
- `Super + M` (`journalctl -f`) se detiene con `Ctrl + C`.
