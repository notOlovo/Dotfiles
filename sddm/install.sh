#!/usr/bin/env bash
# Install/update the SDDM "Cosmos" login screen.
# SDDM runs before login and can't see ~/ (mode 700), so the theme, wallpaper and palette
# are copied to /usr/share/sddm/themes/cosmos. The background and palette are handed to the
# user — from then on sync.sh updates them without sudo on every wallpaper/palette change.
# Re-run only after editing Main.qml.
#   ./install.sh          — the current wallpaper from waypaper
#   ./install.sh IMAGE    — another image
set -euo pipefail

here=$(dirname "$(readlink -f "$0")")
src=$here/cosmos
dest=/usr/share/sddm/themes/cosmos

wall=${1:-$(awk -F' = ' '/^wallpaper/ {print $2}' "${XDG_CONFIG_HOME:-$HOME/.config}/waypaper/config.ini")}
wall=${wall/#\~/$HOME}
[[ -f $wall ]] || { echo "No such image: $wall" >&2; exit 1; }

sudo install -d "$dest"
sudo install -m 644 "$src/Main.qml" "$src/metadata.desktop" "$src/theme.conf" "$dest/"
sudo install -m 644 -o "$USER" /dev/null "$dest/background.jpg"
sudo chown "$USER" "$dest/theme.conf"
"$here/sync.sh" wall "$wall"

# Select the theme: our own file in conf.d + the same theme in kde_settings.conf (if any),
# so the result doesn't depend on the order the files are read
printf '[Theme]\nCurrent=cosmos\n' | sudo tee /etc/sddm.conf.d/zz-cosmos.conf >/dev/null
[[ -f /etc/sddm.conf.d/kde_settings.conf ]] &&
    sudo sed -i 's/^Current=.*/Current=cosmos/' /etc/sddm.conf.d/kde_settings.conf

echo "Done: the cosmos theme is installed ($dest), background — $(basename "$wall")"
echo "Preview without logging out: sddm-greeter-qt6 --test-mode --theme $dest"
