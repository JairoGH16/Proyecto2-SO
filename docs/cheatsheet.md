# Cheatsheet de atajos de ArenalOS

Atajos de XFCE versionados en [`dotfiles/xfce/xfconf/xfce-perchannel-xml/xfce4-keyboard-shortcuts.xml`](../dotfiles/xfce/xfconf/xfce-perchannel-xml/xfce4-keyboard-shortcuts.xml) (lanzadores) y `xfwm4` (acciones de ventana). El `install.sh` los copia a `~/.config/xfce4/xfconf/` del usuario.

## Obligatorios

| Atajo | Qué hace | Diseñó |
|---|---|---|
| `Super + Enter` | Abre una terminal (`xfce4-terminal`) | Equipo (Fase 2) |
| `Super + Q` | Cierra la ventana activa | Equipo (Fase 2) |
| `Super + D` | Abre el launcher de aplicaciones (`xfce4-appfinder`) | Equipo (Fase 2) |
| `Super + 1` … `Super + 9` | Cambia al workspace con ese número (hay 9) | Equipo (Fase 2) |

## Libres (3 por integrante)

### Esteban

| Atajo | Qué hace | Por qué es útil | Relación |
|---|---|---|---|
| `Super + U` | Abre una terminal con `usb-historial -n 20` | Ver de un vistazo qué dispositivos USB están conectados, si una memoria quedó montada en solo lectura y las últimas conexiones/desconexiones | Comando propio · T8 |
| `Super + Shift + P` | Abre una terminal con `sudo puertos-abiertos` | Auditar qué puertos escuchan, qué proceso los tiene y si el firewall los deja pasar. `Super + P` ya lo usa XFCE para pantallas | Comando propio · T9 |
| `Super + M` | Abre una terminal con `journalctl -f -t arenalos-usb` | Ver **en vivo** lo que registra la regla udev del Tema 8 al conectar o desconectar una USB | Función de la Capa 2 · T8 |

Las terminales de `Super + U` y `Super + Shift + P` quedan abiertas (`--hold`) para poder leer la salida; se cierran con `Super + Q`. `Super + M` se detiene con `Ctrl + C`.

### Jairo

| Atajo | Qué hace | Por qué es útil | Relación |
|---|---|---|---|
| | | | |

### Rafael

| Atajo | Qué hace | Por qué es útil | Relación |
|---|---|---|---|
| | | | |

### Sebastián

| Atajo | Qué hace | Por qué es útil | Relación |
|---|---|---|---|
| | | | |
