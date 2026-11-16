#!/usr/bin/env bash
# Mide el consumo en reposo de un escritorio y guarda el resultado en el repo.
# Uso: bash medir-escritorio.sh <candidato>
# Ejemplo: bash medir-escritorio.sh xfce
# Se ejecuta desde la consola de texto, con la sesión gráfica abierta y en reposo.

cand="${1:?Uso: bash medir-escritorio.sh <candidato>}"
destino="${LOGS_DIR:-/media/sf_arenalos/docs/logs/mediciones}"

sudo -v || exit 1
tmp="$(mktemp)"

{
  echo "Candidato: $cand | Host: $HOSTNAME"
  echo "== free -m =="
  free -m
  echo "== procesos =="
  ps -e --no-headers | wc -l
  echo "== PSS total =="
  sudo cat /proc/[0-9]*/smaps_rollup 2>/dev/null | awk '/^Pss:/{s+=$2} END{printf "%.0f MB\n", s/1024}'
  echo "== disco (/) =="
  df -h /
} > "$tmp"

cat "$tmp"
if mkdir -p "$destino" && cp "$tmp" "$destino/medicion-$cand.txt"; then
  echo "Guardado en $destino/medicion-$cand.txt"
else
  echo "No se pudo guardar en $destino (revisa la carpeta compartida)"
fi
rm -f "$tmp"
