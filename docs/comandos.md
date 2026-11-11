# Comandos propios de ArenalOS (Capa 3)

Cada comando está en [`bin/`](../bin/) y se instala en `/usr/local/bin/`. El enunciado exige que cada uno use al menos una interfaz del SO y documente cuál.

| Comando | Autor | Interfaces del SO | Tema relacionado |
|---|---|---|---|
| `midistro-info` | Equipo | `/proc`, `/sys` | Todos |
| [`usb-historial`](#usb-historial) | Esteban | `/sys/bus/usb/devices`, `/sys/block`, `/proc/mounts`, log de la regla udev | T8 |
| [`puertos-abiertos`](#puertos-abiertos) | Esteban | `/proc/net/{tcp,tcp6,udp,udp6}`, `/proc/<pid>/fd`, netfilter (`nft`) | T9 |

---

## usb-historial

**Qué hace.** Muestra los dispositivos USB conectados en este momento (puerto, `vendor:product`, velocidad, driver y, si es un almacenamiento, el disco y dónde está montado con qué opciones). También muestra el historial de conexiones y desconexiones que registra la regla udev del Tema 8, con un conteo por dispositivo.

**Uso.**
```
usb-historial          # dispositivos actuales + últimas 10 líneas del historial
usb-historial -n 30    # últimas 30 líneas del historial
usb-historial -h       # ayuda
```

**Interfaces del SO.**
- `/sys/bus/usb/devices/*/{idVendor,idProduct,speed,manufacturer,product,bDeviceClass}`: atributos que el kernel publica por cada dispositivo USB (se omiten los hubs, clase `09`).
- `/sys/bus/usb/devices/<dev>/<dev>:<if>/driver`: qué driver tomó cada interfaz (`usb-storage`, `usbhid`…).
- `/sys/block/*/device`: enlace simbólico que permite saber de qué dispositivo USB cuelga cada disco.
- `/proc/mounts`: punto de montaje y opciones (`ro,nosuid,nodev,noexec`).
- `/var/log/arenalos-usb.log`: escrito por `arenalos-usb-handler` (Tema 8).

**Ejemplo** (salida real, [`docs/logs/esteban/tema-09/10-comando-usb-historial.txt`](logs/esteban/tema-09/10-comando-usb-historial.txt)):
```
PUERTO  ID         VELOC.    DISPOSITIVO                 DRIVER / DISCO
1-1     80ee:0021  12M       VirtualBox USB Tablet       usbhid
3-1     0951:1666  5000M     Kingston DataTraveler 3.0   usb-storage | /dev/sdb /dev/sdb1 -> /media/usb-sdb1 (ro,nosuid,nodev,noexec,...)
```

---

## puertos-abiertos

**Qué hace.** Lista los puertos TCP y UDP en los que la máquina está escuchando, qué proceso es dueño de cada uno y si el firewall nftables **deja pasar** conexiones a ese puerto, lo bloquea o si el puerto solo escucha en loopback. Sirve para auditar rápidamente la superficie expuesta: "¿qué servicios tengo abiertos y cuáles de ellos son alcanzables desde la red?".

**Uso.**
```
sudo puertos-abiertos  # completo (procesos de todos los usuarios + firewall)
puertos-abiertos       # sin root: lista los puertos, pero no puede ver procesos ajenos ni el firewall
puertos-abiertos -h    # ayuda
```

**Interfaces del SO.**
- `/proc/net/tcp`, `tcp6`, `udp`, `udp6`: tabla de sockets del kernel. Las direcciones y puertos vienen en hexadecimal (IPv4 en *little-endian*). El estado `0A` es `LISTEN` en TCP, y `07` es un socket UDP sin conectar.
- `/proc/<pid>/fd/*`: cada descriptor que es un socket apunta a `socket:[<inodo>]`. El inodo se cruza con el de `/proc/net/*` para saber qué proceso tiene el puerto, y el nombre sale de `/proc/<pid>/comm`.
- `nft list ruleset` (netfilter): si la cadena `input` tiene `policy drop`, se extraen los puertos con `tcp/udp dport … accept`.

**Ejemplo** (salida real, [`docs/logs/esteban/tema-09/09-comando-puertos-abiertos.txt`](logs/esteban/tema-09/09-comando-puertos-abiertos.txt)):
```
PROTO PUERTO ESCUCHA EN    PROCESO(PID)           FIREWALL
tcp   22     0.0.0.0       sshd(307)              PERMITIDO
tcp6  22     ::            sshd(307)              PERMITIDO
tcp6  8080   ::            systemd-socket-(443)   bloqueado (drop)
```
