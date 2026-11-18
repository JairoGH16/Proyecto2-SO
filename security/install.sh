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

echo "[T9] 1/4 Usuarios, grupos y directorio compartido con ACL"
bash "$DIR/setup-usuarios-acl.sh" >/dev/null && echo "  listo"

echo "[T9] 2/4 sudoers restringido"
visudo -cf "$DIR/sudoers.d/50-arenalos-ops" >/dev/null
put 440 "$DIR/sudoers.d/50-arenalos-ops" /etc/sudoers.d/50-arenalos-ops || true

echo "[T9] 3/4 SSH endurecido"
if put 644 "$DIR/sshd_config.d/10-arenalos.conf" /etc/ssh/sshd_config.d/10-arenalos.conf; then
    if sshd -t; then
        systemctl reload sshd 2>/dev/null || true    # reload: no corta sesiones abiertas
    else
        rm -f /etc/ssh/sshd_config.d/10-arenalos.conf
        echo "  ERROR: sshd -t falló; se retiró la configuración"; exit 1
    fi
fi
systemctl enable --now sshd >/dev/null 2>&1

echo "[T9] 4/4 Firewall nftables"
nft -c -f "$DIR/nftables.conf"
if put 644 "$DIR/nftables.service.d/10-arenalos.conf" /etc/systemd/system/nftables.service.d/10-arenalos.conf; then
    systemctl daemon-reload
fi
if put 644 "$DIR/nftables.conf" /etc/nftables.conf; then
    systemctl enable nftables >/dev/null 2>&1
    systemctl restart nftables
else
    systemctl enable --now nftables >/dev/null 2>&1
fi
echo "[T9] Listo"
