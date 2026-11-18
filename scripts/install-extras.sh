#!/usr/bin/env bash
# Extras de ArenalOS: aplicaciones por defecto, navegador, fondo de SDDM y reloj.
set -euo pipefail
: "${REPO_DIR:?falta REPO_DIR}"

BG=/usr/share/backgrounds/xfce/arenal.jpg

# 1. Aplicaciones por defecto para todos los usuarios
RIS=$(basename "$(ls /usr/share/applications/*ristretto*.desktop | head -n 1)")
{
  echo '[Default Applications]'
  echo 'inode/directory=thunar.desktop'
  for t in $(grep -E '^(video|audio)/' /usr/share/mime/types); do echo "$t=vlc.desktop"; done
  for t in $(grep -E '^image/' /usr/share/mime/types); do echo "$t=$RIS"; done
  for t in text/html x-scheme-handler/http x-scheme-handler/https; do echo "$t=firefox.desktop"; done
} > /etc/xdg/mimeapps.list
install -d /etc/xdg/xfce4
# Solo se cambia el navegador; el resto de helpers.rc (terminal, gestor de archivos...)
# se deja como venga en el sistema.
HELPERS=/etc/xdg/xfce4/helpers.rc
touch "$HELPERS"
if grep -q '^WebBrowser=' "$HELPERS"; then
  sed -i 's/^WebBrowser=.*/WebBrowser=firefox/' "$HELPERS"
else
  echo 'WebBrowser=firefox' >> "$HELPERS"
fi

# 2. Fondo de la pantalla de login (SDDM, tema maldives) con la foto del volcán
T=/usr/share/sddm/themes/maldives
install -Dm644 "$BG" "$T/arenal.jpg"
printf '[General]\nbackground=arenal.jpg\ntype=image\n' > "$T/theme.conf.user"
install -d /etc/sddm.conf.d
printf '[Theme]\nCurrent=maldives\n' > /etc/sddm.conf.d/10-arenalos-theme.conf

# 3. Reloj arriba al centro del escritorio (Conky). El bloqueo lo da xfce4-screensaver,
#    que se inicia solo y muestra hora y fecha en su ventana de desbloqueo.
install -d /etc/arenalos
cat > /etc/arenalos/reloj.conf <<'CONKY'
conky.config = {
  alignment = 'top_middle',
  gap_y = 50,
  own_window = true,
  own_window_type = 'dock',
  own_window_hints = 'undecorated,below,sticky,skip_taskbar,skip_pager',
  own_window_transparent = false,
  own_window_argb_visual = true,
  own_window_argb_value = 0,
  double_buffer = true,
  update_interval = 1,
  use_xft = true,
  font = 'DejaVu Sans:size=22',
  default_color = 'white',
  draw_shades = true,
  default_shade_color = 'black',
  minimum_width = 900,
  maximum_width = 900,
}
conky.text = [[
${alignc}${font DejaVu Sans:bold:size=90}${time %H:%M}${font}
${alignc}${time %A, %d de %B de %Y}
]]
CONKY
printf '[Desktop Entry]\nType=Application\nName=Reloj ArenalOS\nExec=sh -c "sleep 3; exec conky -c /etc/arenalos/reloj.conf"\nX-GNOME-Autostart-enabled=true\n' > /etc/xdg/autostart/arenalos-reloj.desktop
