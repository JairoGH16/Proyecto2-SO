#!/bin/bash
# security/setup-usuarios-acl.sh — usuarios, grupos y directorio compartido con ACL
# ArenalOS · Tema 9 (Protección y seguridad) · Responsable: Esteban
#
# Principio de privilegio mínimo: cada cuenta tiene SOLO lo que necesita.
#
#   Cuenta     Grupos                     Puede...
#   ---------  -------------------------  -----------------------------------------------
#   user       wheel, arenalos-ssh        administrar (sudo completo) y entrar por SSH
#   operador   arenalos-ops, arenalos-datos  leer/escribir el compartido y 3 comandos sudo
#   auditor    systemd-journal            SOLO leer el compartido (ACL) y los logs
#   invitado   (ninguno)                  nada: shell nologin y sin acceso al compartido
#
# Directorio compartido: /srv/arenalos/compartido
#   dueño root, grupo arenalos-datos, modo 2770 (rwxrws---):
#     - el bit setgid (2) hace que lo que se cree adentro herede el grupo arenalos-datos
#     - "otros" = 0: quien no esté en el grupo ni en la ACL no puede ni listar
#   ACL de acceso:      u:auditor:r-x         (lectura sin ser del grupo)
#   ACL por defecto:    d:g:arenalos-datos:rwx d:u:auditor:r-x  (la heredan los archivos nuevos)
#
# Idempotente: comprueba antes de crear. Ejecutar como root.

set -euo pipefail
[ "$(id -u)" -eq 0 ] || { echo "Ejecutar como root (sudo)"; exit 1; }

ADMIN_USER="${ADMIN_USER:-user}"          # cuenta administradora de cada VM (guía Fase 1)
DIR=/srv/arenalos/compartido

echo "[T9] Grupos"
for g in arenalos-ops arenalos-datos arenalos-ssh; do
    getent group "$g" >/dev/null || { groupadd "$g"; echo "  creado grupo $g"; }
done

echo "[T9] Usuarios"
crear() {  # crear <usuario> <shell> <comentario>
    if ! id "$1" &>/dev/null; then
        useradd -m -s "$2" -c "$3" "$1"
        passwd -l "$1" >/dev/null     # sin contraseña: no puede iniciar sesión por contraseña
        echo "  creado usuario $1"
    fi
}
crear operador /bin/bash         "ArenalOS operador (privilegio limitado)"
crear auditor  /bin/bash         "ArenalOS auditor (solo lectura)"
crear invitado /usr/bin/nologin  "ArenalOS invitado (sin acceso)"

usermod -aG arenalos-ops,arenalos-datos operador
usermod -aG systemd-journal auditor
if id "$ADMIN_USER" &>/dev/null; then
    usermod -aG arenalos-ssh "$ADMIN_USER"
fi

echo "[T9] Directorio compartido $DIR"
install -d -m 0755 -o root -g root /srv/arenalos
install -d -m 2770 -o root -g arenalos-datos "$DIR"
chmod 2770 "$DIR"                 # por si ya existía con otro modo
setfacl -m u:auditor:r-x "$DIR"
setfacl -d -m g:arenalos-datos:rwx,u:auditor:r-x,o::--- "$DIR"
getfacl -p "$DIR"
echo "[T9] Usuarios y ACL listos"
