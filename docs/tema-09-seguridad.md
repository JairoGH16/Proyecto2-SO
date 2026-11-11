# Tema/Módulo: 9 · Protección y seguridad          Responsable: Esteban

> Apoyo: Rafael · Entorno: VM VirtualBox 7.2, ArenalOS, kernel `6.18.62-1-lts`, OpenSSH 10.6p1, nftables 1.1.7.
> Datos crudos: [`docs/logs/esteban/tema-09/`](logs/esteban/tema-09/).

## 1. Qué se implementó

| Componente | Ruta en el repositorio | Se instala en |
|---|---|---|
| Usuarios, grupos y directorio compartido con ACL | [`security/setup-usuarios-acl.sh`](../security/setup-usuarios-acl.sh) | `/srv/arenalos/compartido` |
| sudo restringido por comando | [`security/sudoers.d/50-arenalos-ops`](../security/sudoers.d/50-arenalos-ops) | `/etc/sudoers.d/` |
| Endurecimiento de SSH | [`security/sshd_config.d/10-arenalos.conf`](../security/sshd_config.d/10-arenalos.conf) | `/etc/ssh/sshd_config.d/` |
| Firewall nftables (denegación por defecto) | [`security/nftables.conf`](../security/nftables.conf) | `/etc/nftables.conf` |
| Ajuste del servicio nftables | [`security/nftables.service.d/10-arenalos.conf`](../security/nftables.service.d/10-arenalos.conf) | `/etc/systemd/system/nftables.service.d/` |
| Instalador idempotente que valida cada archivo antes de aplicarlo | [`security/install.sh`](../security/install.sh) | lo llama `install.sh` |

**Cuentas con privilegio mínimo.** Cada cuenta tiene solo lo que necesita:

| Cuenta | Grupos | Puede | No puede |
|---|---|---|---|
| `user` | `wheel`, `arenalos-ssh` | Administrar con `sudo` y entrar por SSH con llave | Entrar al compartido **sin** sudo (no es del grupo) |
| `operador` | `arenalos-ops`, `arenalos-datos` | Leer y escribir el compartido; 3 comandos con sudo | Otros comandos con sudo, entrar por SSH |
| `auditor` | `systemd-journal` | **Leer** el compartido (por ACL) y los logs | Escribir, crear o borrar en el compartido; usar sudo |
| `invitado` | — | Nada (shell `nologin`) | Iniciar sesión, listar el compartido, usar sudo |

`operador`, `auditor` e `invitado` tienen la contraseña bloqueada (`passwd -l`).

**Directorio compartido** `/srv/arenalos/compartido`: dueño `root`, grupo `arenalos-datos`, modo `2770` (`rwxrws---`).
- El bit **setgid** hace que lo creado adentro herede el grupo.
- "Otros" no tienen ningún permiso (`---`).
- **ACL de acceso** `u:auditor:r-x`: le da lectura a alguien que no está en el grupo.
- **ACL por defecto** `d:g:arenalos-datos:rwx,d:u:auditor:r-x`: la heredan los archivos nuevos.

**sudoers por comando exacto.** El grupo `arenalos-ops` puede ejecutar como root **solo** estos comandos:
- `systemctl restart sshd.service`
- `systemctl is-active sshd.service nftables.service`
- `nft list ruleset`

Se usan rutas absolutas y la etiqueta `NOEXEC`, que impide que el comando lance otros programas. Así se bloquean escapes como el de un *pager* `less` con `!sh`. Por la misma razón **no** se permitió `journalctl`.

**SSH endurecido:**
- `PermitRootLogin no`
- Solo llaves: `PasswordAuthentication no`, `KbdInteractiveAuthentication no`, `AuthenticationMethods publickey`
- Lista blanca: `AllowGroups arenalos-ssh`
- `MaxAuthTries 3`, `LoginGraceTime 30`
- Sin reenvíos de X11, agente ni TCP
- `LogLevel VERBOSE`, que registra la huella de la llave usada

El archivo se llama `10-…` porque en sshd **gana el primer valor leído** y los archivos se leen en orden alfabético, antes de `99-archlinux.conf`.

**Firewall nftables.** Tabla `inet` (IPv4 e IPv6) con **`policy drop`** en `input`. Solo se acepta:
- tráfico de conexiones ya establecidas o relacionadas;
- loopback;
- ping (limitado a 5/s);
- ICMPv6, que IPv6 necesita para descubrir vecinos;
- los puertos de `define PUERTOS_TCP = { 22 }`, con conexiones nuevas limitadas a 30/min.

Lo demás se descarta, se cuenta y se registra una muestra limitada (10/min) con el prefijo `arenalos-drop:`. `forward` también es `drop`, y `output` es `accept`. **Pendiente:** si otro tema del equipo necesita un puerto (por ejemplo, la activación por socket del Tema 4), basta con agregarlo al `define`.

**Ajuste del servicio.** El `nftables.service` de Arch es `oneshot` sin `RemainAfterExit`: carga las reglas y queda `inactive`, aunque el firewall esté activo. El drop-in agrega `RemainAfterExit=yes`, `ExecReload` y `ExecStop=nft flush ruleset`, para que `systemctl status/stop nftables` reflejen el estado real.

**Seguridad al aplicar.** `install.sh` valida cada archivo antes de instalarlo (`visudo -cf`, `sshd -t`, `nft -c -f`) y usa `systemctl reload sshd`, que no corta las sesiones abiertas. Durante las pruebas, además, se programó un timer de rescate (`systemd-run --on-active=120 nft flush ruleset`) que se canceló solo después de comprobar el acceso.

## 2. Concepto de Sistemas Operativos

- **Protección: dominios y control de acceso.** Cada proceso se ejecuta con la identidad (UID, GID y grupos suplementarios) de un usuario, y el kernel decide en cada `open()`/`execve()` según los permisos del objeto. Los bits `rwx` dueño/grupo/otros son una **lista de control de acceso** reducida. Las **ACL POSIX** la extienden con entradas por usuario o grupo, y una **máscara** limita los permisos efectivos de esas entradas.
- **Principio de privilegio mínimo** (Saltzer y Schroeder): cada sujeto recibe solo los derechos que necesita. Se aplica en las cuentas, en `sudo` por comando (cambio de dominio controlado: un proceso pasa al dominio de root solo para una operación concreta) y en el filtrado de red.
- **Seguridad: autenticación y superficie de ataque.** La autenticación por llave pública (desafío-respuesta) no expone un secreto reutilizable y no se puede atacar por fuerza bruta de contraseñas. Desactivar lo que no se usa (root, reenvíos, métodos de autenticación) reduce la superficie de ataque.
- **Firewall en el kernel (netfilter).** El kernel evalúa cada paquete contra cadenas de reglas en *hooks* de la pila de red. El **seguimiento de conexiones** (`conntrack`) permite aceptar respuestas sin abrir puertos. Con una **política de denegación por defecto**, lo que no está permitido explícitamente se descarta.

**Bibliografía:**
- Silberschatz, Galvin y Gagne, *Operating System Concepts*, 10.ª ed.: cap. 17 "Protection" (principio de privilegio mínimo, dominios de protección, matriz y listas de acceso) y cap. 16 "Security" (autenticación, firewalls).
- Tanenbaum y Bos, *Modern Operating Systems*, 4.ª ed., cap. 9 "Security".
- Saltzer y Schroeder (1975), "The Protection of Information in Computer Systems".
- Páginas de manual: `acl(5)`, `setfacl(1)`, `sudoers(5)`, `sshd_config(5)`, `nft(8)`.
- Arch Wiki: *Access Control Lists*, *Sudo*, *OpenSSH*, *nftables*.

## 3. Método de medición

Todo se hizo en la VM de Esteban. Las pruebas de acceso se ejecutaron con la identidad real de cada cuenta mediante `runuser -u <cuenta> -- <comando>`. Así el kernel aplica los permisos de esa cuenta, no los de root.

| Prueba | Herramienta y comando |
|---|---|
| Permisos y ACL | `ls -ld`, `getfacl`, y 10 pruebas con `runuser` (lectura, escritura, creación y borrado por cada cuenta) |
| sudoers | `visudo -c`; `sudo -l -U <cuenta>`; `sudo -n -l <comando>` (dice si un comando está permitido: código 1 si no); ejecución real de comandos permitidos y prohibidos; `journalctl -t sudo` |
| SSH antes/después | `sshd -T` (valores efectivos); desde **otra máquina** (el host Windows por el puerto reenviado): `ssh -o PreferredAuthentications=none` (lista los métodos que ofrece el servidor), inicio con llave como `user`, `root` y `operador`, e intento con contraseña; `journalctl -u sshd` |
| Firewall: escaneo externo | Desde una **segunda VM** (`ArenalOS-scanner`, 10.10.10.2, live de Arch con `nmap 7.99`) en la red interna aislada de VirtualBox `arenalos-net` hacia la VM (10.10.10.1): `nmap -sS -Pn -n --reason -p 1-1024,8080 10.10.10.1`, **3 corridas sin firewall y 3 con firewall**. En el objetivo escuchaban `sshd` (22) y un servicio de prueba en el **8080** (`systemd-socket-activate -l 8080`), para comprobar que el firewall bloquea aunque haya un proceso escuchando |
| Firewall: reglas | `nft reset counters` antes de los escaneos, y después `nft list ruleset` con contadores; `journalctl -k --grep arenalos-drop` |
| Idempotencia | `sudo ./security/install.sh` dos veces seguidas |

## 4. Resultados

### 4.1 Permisos y ACL ([`02-usuarios-acl-pruebas.txt`](logs/esteban/tema-09/02-usuarios-acl-pruebas.txt))

```
drwxrws---+ 2 root arenalos-datos  /srv/arenalos/compartido
```

| Cuenta | Operación | Resultado |
|---|---|---|
| operador | escribir `informe.txt` | ✅ OK |
| operador | leer | ✅ OK |
| auditor | listar / leer | ✅ OK (por la ACL `u:auditor:r-x`) |
| auditor | agregar texto al archivo | ❌ `Permission denied` |
| auditor | crear `nuevo.txt` | ❌ `Permission denied` |
| auditor | borrar `informe.txt` | ❌ `Permission denied` |
| invitado | listar el directorio | ❌ `Permission denied` |
| invitado | leer `informe.txt` | ❌ `Permission denied` |
| user (admin, sin sudo) | listar el directorio | ❌ `Permission denied` |
| invitado | `su - invitado` | ❌ `This account is currently not available.` |

El archivo creado por `operador` quedó con grupo `arenalos-datos` (por setgid) y heredó la ACL por defecto: `user:auditor:r-x #effective:r--`, `mask::rw-`.

### 4.2 sudoers ([`03-sudoers-pruebas.txt`](logs/esteban/tema-09/03-sudoers-pruebas.txt))

| Cuenta | Comando | ¿Permitido? |
|---|---|---|
| operador | `systemctl is-active sshd.service nftables.service` | ✅ ejecutado |
| operador | `systemctl restart sshd.service` | ✅ ejecutado (registrado en `journalctl -t sudo`) |
| operador | `nft list ruleset` | ✅ ejecutado |
| operador | `systemctl restart NetworkManager.service` | ❌ no permitido (`sudo -l` exit 1) |
| operador | `systemctl stop sshd.service` | ❌ no permitido |
| operador | `cat /etc/shadow` | ❌ no permitido |
| operador | `bash` (shell de root) | ❌ no permitido |
| operador | `nft flush ruleset` (apagar el firewall) | ❌ no permitido |
| auditor / invitado | cualquier comando | ❌ `User … is not allowed to run sudo` |

### 4.3 SSH antes y después ([`01-ssh-antes.txt`](logs/esteban/tema-09/01-ssh-antes.txt), [`04-ssh-despues.txt`](logs/esteban/tema-09/04-ssh-despues.txt))

| Parámetro (`sshd -T`) | Antes | Después |
|---|---|---|
| PermitRootLogin | prohibit-password | **no** |
| PasswordAuthentication | **yes** | **no** |
| Métodos que ofrece el servidor | `publickey,password` | **`publickey`** |
| AllowGroups | (todos) | **arenalos-ssh** |
| MaxAuthTries / LoginGraceTime | 6 / 120 s | **3 / 30 s** |
| AllowTcpForwarding | yes | **no** |

| Prueba desde otra máquina | Resultado |
|---|---|
| `user` con llave | ✅ `conectado como user en arenalos-esteban` |
| `root` con llave **válida** | ❌ `Permission denied (publickey)` · log: `User root ... not allowed because none of user's groups are listed in AllowGroups` |
| `operador` con llave **válida** | ❌ `Permission denied (publickey)` · log: `User operador ... not allowed ...` |
| `user` con contraseña | ❌ `Permission denied (publickey)`: el método ya no existe |

### 4.4 Escaneo nmap desde otra VM ([`05-nmap-sin-firewall.txt`](logs/esteban/tema-09/05-nmap-sin-firewall.txt), [`07-nmap-con-firewall.txt`](logs/esteban/tema-09/07-nmap-con-firewall.txt))

| | Sin firewall (3 corridas) | Con firewall (3 corridas) |
|---|---|---|
| 22/tcp (sshd) | open (`syn-ack`) | **open** (`syn-ack`) |
| 8080/tcp (servicio de prueba escuchando) | open (`syn-ack`) | **filtered** (`no-response`) |
| Otros 1023 puertos | closed (`reset`) | **filtered** (`no-response`) |
| Tiempo de escaneo | 4.29 / 3.33 / 2.82 s, promedio **3.48 s** | 6.24 / 6.44 / 6.85 s, promedio **6.51 s** |
| Ping | 3/3 respondidos | 3/3 respondidos (permitido con límite) |
| Conexión TCP manual al 8080 | — | se queda colgada: timeout a los 5 s (`exit=124`) |

### 4.5 `nft list ruleset` interpretado ([`08-nft-ruleset-contadores.txt`](logs/esteban/tema-09/08-nft-ruleset-contadores.txt))

Contadores puestos en cero antes de los 3 escaneos con firewall, más un ping y dos conexiones de prueba:

```
table inet arenalos {
  chain input {
    type filter hook input priority filter; policy drop;
    ct state invalid counter packets 0 bytes 0 drop                        <- (1)
    ct state { established, related } counter packets 154 bytes 21998 accept  <- (2)
    iif "lo" accept                                                        <- (3)
    ip protocol icmp icmp type echo-request limit rate 5/second ... counter packets 1 accept  <- (4)
    meta l4proto ipv6-icmp counter packets 0 accept                        <- (5)
    tcp dport 22 ct state new limit rate 30/minute burst 30 packets counter packets 19 accept <- (6)
    limit rate 10/minute burst 5 packets log prefix "arenalos-drop: "      <- (7)
    counter packets 6150 bytes 270964 comment "descartados-por-politica"   <- (8)
  }
  chain forward { type filter hook forward priority filter; policy drop; } <- (9)
  chain output  { type filter hook output priority filter; policy accept; }
}
```

| # | Qué hace la regla | Qué dicen los contadores |
|---|---|---|
| `type filter hook input … policy drop` | La cadena se engancha al punto de entrada de la pila de red (paquetes dirigidos a esta máquina). Lo que no coincida con ninguna regla se **descarta** sin responder | — |
| (1) | Descarta paquetes que conntrack no puede asociar a una conexión válida (por ejemplo, un ACK suelto) | 0: no hubo paquetes inválidos |
| (2) | Acepta respuestas de conexiones que **esta** máquina inició, y el resto de paquetes de conexiones ya aceptadas (la sesión SSH en curso, DNS, pacman) | 154: el tráfico de las sesiones SSH abiertas |
| (3) | Loopback: los procesos locales se comunican sin filtro | sin contador |
| (4) | Ping limitado a 5/s (frena *ping flood*) | **1**, aunque se enviaron 3: el primer echo crea la "conexión" ICMP en conntrack y los otros 2 entran por (2) como `established` |
| (5) | ICMPv6: sin él, IPv6 no puede descubrir vecinos ni routers | 0 en la red interna (solo IPv4) |
| (6) | Acepta conexiones **nuevas** solo a los puertos de `PUERTOS_TCP` (22), con límite de 30/min contra fuerza bruta | 19: los SYN de nmap al 22 y los inicios de SSH |
| (7) | Registra en el journal del kernel una muestra limitada de lo que se va a descartar | 11 líneas en el journal de 6150 descartes |
| (8) | Cuenta lo que llega al final de la cadena y cae en la política `drop` | **6150** paquetes |
| (9) | No reenvía paquetes entre interfaces (no es un router) | — |

Ejemplo de línea registrada: `arenalos-drop: IN=enp0s8 SRC=10.10.10.2 DST=10.10.10.1 PROTO=TCP SPT=43746 DPT=8080 SYN`.

### 4.6 Idempotencia ([`06-install-idempotencia.txt`](logs/esteban/tema-09/06-install-idempotencia.txt))

La segunda ejecución de `install.sh` informó `sin cambios` en todos los archivos. `systemctl is-active nftables sshd` da `active active`.

## 5. Interpretación

**Permisos y ACL.** Los resultados coinciden con el modelo de control de acceso discrecional de UNIX extendido con ACL POSIX. El kernel evalúa en orden: dueño → entradas de usuario de la ACL → grupos → otros, y aplica la **máscara** a las entradas extendidas. Por eso:
- `auditor` lee aunque no está en el grupo (entrada `u:auditor:r-x`), pero no puede crear ni borrar: crear o borrar un archivo requiere permiso de **escritura sobre el directorio**, que la ACL no le da.
- `invitado` cae en "otros" (`---`), y el kernel rechaza incluso listar.
- En los archivos nuevos, la máscara `rw-` hace que la `x` de la ACL por defecto no se vuelva efectiva (`#effective:r--`). Es correcto, porque los datos no deben ser ejecutables.
- Que `user` (el administrador) tampoco pueda entrar sin `sudo` muestra la separación entre "tener privilegios" y "usarlos": el acceso privilegiado queda explícito y registrado.

**sudoers.** `sudo` funciona como un **cambio de dominio controlado**: el proceso solo obtiene UID 0 si la línea completa del comando coincide con una entrada. Las 5 pruebas negativas del operador confirman que la granularidad es por comando **y argumentos**: `restart sshd.service` está permitido, `stop sshd.service` no. La etiqueta `NOEXEC` y la exclusión de herramientas con *pager* evitan que un comando permitido sirva para escalar a una shell de root (un riesgo real documentado en GTFOBins). Cada uso queda auditado en el journal.

**SSH.** Se eliminó la autenticación por contraseña (el servidor ya no la ofrece), así que un ataque de fuerza bruta de contraseñas ya no es posible. `root` queda bloqueado por **dos controles independientes**, `PermitRootLogin no` y `AllowGroups`, y el log muestra que el primero en actuar fue `AllowGroups`. Es **defensa en profundidad**: si uno se configura mal, el otro sigue protegiendo. `operador` tiene una llave válida y aun así es rechazado: el **control de acceso** (quién puede entrar) es independiente de la **autenticación** (quién eres).

**Firewall.** El cambio que ve `nmap` desde afuera coincide con la teoría de netfilter:
- **`closed` → `filtered`.** Sin firewall, el kernel responde con **RST** a los puertos sin servicio, lo que le confirma al atacante que la máquina existe y qué puertos están cerrados. Con `policy drop`, el paquete se descarta **sin respuesta**, y nmap no puede distinguir "cerrado" de "filtrado".
- **El 8080 tenía un proceso escuchando** y aun así aparece `filtered`: el firewall actúa en la pila de red **antes** de que el paquete llegue al socket del proceso. Proteger una máquina no depende de que cada servicio esté bien configurado.
- **El escaneo tarda casi el doble** (3.48 → 6.51 s): sin respuesta, nmap debe esperar el timeout y **reintentar** cada sonda. El contador lo confirma: 3 escaneos × 1024 puertos filtrados × **2 sondas** = **6144**. Los otros 6 de los 6150 son los reintentos de SYN de la conexión manual al 8080 y broadcasts DHCP del escáner.
- **El ping** entra 1 vez por su regla y 2 veces por `established`: conntrack también sigue protocolos sin conexión (ICMP echo/reply), y por eso la regla (2) sirve para todo el tráfico de respuesta.
- El **límite del log** (11 líneas para 6150 descartes) impide que un escaneo llene el disco con el journal. Esto también es protección del SO.

**Limitaciones.**
- Es una red virtual aislada, y el "atacante" es una VM del mismo host.
- El límite de 30 conexiones SSH nuevas por minuto es **global**, no por IP: un atacante podría agotarlo y bloquear conexiones legítimas. Una mejora sería un *meter* por IP de origen, o fail2ban.
- `editor yes` en systemd-boot (necesario para el Tema 7) permite que alguien con acceso a la consola cambie los parámetros del kernel. Es un compromiso aceptado y documentado.
- AppArmor (opcional) no se implementó.
