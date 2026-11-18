#!/usr/bin/env bash
# Comandos libres de los Temas 2 y 4 y la herramienta de memoria como comando. Idempotente.
set -euo pipefail
[ "$(id -u)" -eq 0 ] || { echo "Ejecutar como root (sudo)"; exit 1; }
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(dirname "$DIR")"

install -Dm755 "$REPO_DIR/bin/riesgo-oom" /usr/local/bin/riesgo-oom
install -Dm755 "$REPO_DIR/bin/servicios-limites" /usr/local/bin/servicios-limites
install -Dm755 "$REPO_DIR/src/memoria/memoria.py" /usr/local/bin/memoria
echo "Instalados: riesgo-oom, servicios-limites, memoria"
