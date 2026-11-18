#!/bin/bash
# security/install.sh — instala el Tema 9 (Protección y seguridad) de ArenalOS
# Responsable: Esteban
#
# Idempotente. Cada archivo se VALIDA antes de instalarse, porque un error en
# sudoers deja sin sudo y uno en sshd/nftables puede dejar la VM sin acceso:
#   sudoers  -> visudo -cf     sshd -> sshd -t     nftables -> nft -c -f
# Uso:  sudo ./security/install.sh
#
# AVISO: después de esto SSH solo acepta LLAVES y solo a miembros de arenalos-ssh.
# Antes de ejecutarlo, copie su llave pública a ~/.ssh/authorized_keys del usuario.

set -euo pipefail
[ "$(id -u)" -eq 0 ] || { echo "Ejecutar como root (sudo)"; exit 1; }
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

put() {  # put <modo> <origen> <destino>  -> 0 si cambió
    if ! cmp -s "$2" "$3"; then install -Dm"$1" "$2" "$3"; echo "  actualizado: $3"; return 0; fi
    echo "  sin cambios: $3"; return 1
}

# Si se actualizó el kernel durante esta corrida, el que está en ejecución ya no
# tiene sus módulos en disco: nft no puede cargar nf_tables hasta reiniciar.
modulos_disponibles() {
    [ -d "/usr/lib/modules/$(uname -r)" ]
}

echo "[T9] 1/4 Usuarios, grupos y directorio compartido con ACL"
# Se oculta solo el getfacl informativo; los errores salen por stderr y set -e detiene el script.
bash "$DIR/setup-usuarios-acl.sh" >/dev/null && echo "  listo"

echo "[T9] 2/4 sudoers restringido"
visudo -cf "$DIR/sudoers.d/50-arenalos-ops" >/dev/null   # oculta "parsed OK"; los errores van a stderr
put 440 "$DIR/sudoers.d/50-arenalos-ops" /etc/sudoers.d/50-arenalos-ops || true   # put devuelve 1 si no hubo cambios

echo "[T9] 3/4 SSH endurecido"
# En un Arch recién instalado todavía no existen las llaves de host (las crea
# sshdgenkeys.service al primer arranque de sshd) y sshd -t falla con
# "no hostkeys available". ssh-keygen -A crea solo las que falten.
ssh-keygen -A
ssh_cambio=0
if put 644 "$DIR/sshd_config.d/10-arenalos.conf" /etc/ssh/sshd_config.d/10-arenalos.conf; then
    ssh_cambio=1
fi
# Se valida siempre, no solo cuando cambia el archivo, por si una corrida anterior
# se interrumpió después de copiarlo y antes de validarlo.
if ! sshd -t; then
    rm -f /etc/ssh/sshd_config.d/10-arenalos.conf
    echo "  ERROR: sshd -t falló; se retiró la configuración" >&2
    exit 1
fi
systemctl enable sshd >/dev/null   # oculta "Created symlink"; los errores van a stderr
if ! systemctl is-active --quiet sshd; then
    systemctl start sshd
elif [ "$ssh_cambio" = 1 ]; then
    systemctl reload sshd   # reload: no corta sesiones abiertas
fi

echo "[T9] 4/4 Firewall nftables"
if put 644 "$DIR/nftables.service.d/10-arenalos.conf" /etc/systemd/system/nftables.service.d/10-arenalos.conf; then
    systemctl daemon-reload
fi
systemctl enable nftables >/dev/null   # oculta "Created symlink"; los errores van a stderr
if ! modulos_disponibles; then
    put 644 "$DIR/nftables.conf" /etc/nftables.conf || true   # put devuelve 1 si no hubo cambios
    echo "  AVISO: el kernel en ejecución ($(uname -r)) se actualizó y sus módulos ya no están;"
    echo "         el firewall queda configurado y habilitado (sin validar nft en vivo) y se carga al reiniciar"
else
    nft -c -f "$DIR/nftables.conf"
    nft_cambio=0
    if put 644 "$DIR/nftables.conf" /etc/nftables.conf; then
        nft_cambio=1
    fi
    # La tabla arenalos falta si nftables nunca se cargó o si una corrida anterior
    # se interrumpió entre copiar el archivo y aplicarlo. nft avisa por stderr
    # cuando la tabla no existe, que es justo lo que se está preguntando.
    if [ "$nft_cambio" = 1 ] || ! nft list table inet arenalos >/dev/null 2>&1; then
        systemctl restart nftables
        echo "  reglas cargadas"
    else
        echo "  reglas ya cargadas"
    fi
fi
echo "[T9] Listo"
