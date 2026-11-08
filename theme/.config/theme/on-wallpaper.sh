#!/usr/bin/env bash
# waypaper hook (post_command in ~/.config/waypaper/config.ini) — runs after every wallpaper
# change, wherever it came from: the theme menu, the waypaper window, waypaper --wallpaper.
#   the "From wallpaper" palette (if selected) is rebuilt for the new image
#   the SDDM login screen background is updated (no sudo, see sddm/install.sh)
#   on-wallpaper.sh IMAGE

# Detach from waypaper/Waybar: a Waybar reload would kill the process group
if [[ -z $ONWALL_DETACHED ]]; then
    ONWALL_DETACHED=1 exec setsid -f "$0" "$@"
fi

img=${1/#\~/$HOME}
[[ -f $img ]] || exit 0

dir=$(dirname "$(readlink -f "$0")")              # dotfiles/theme/.config/theme
dotfiles=$(readlink -f "$dir/../../..")
state=${XDG_STATE_HOME:-$HOME/.local/state}/theme
mkdir -p "$state"

# One at a time, and only if the image is really new: waypaper --restore at login
# and the per-monitor runs call the hook too
exec 9>"$state/on-wallpaper.lock"
flock 9
[[ $(cat "$state/last-wallpaper" 2>/dev/null) == "$img" ]] && exit 0
echo "$img" > "$state/last-wallpaper"

[[ $("$dir/theme.py" current) == wallpaper ]] && "$dir/theme.py" wallpaper "$img"
"$dotfiles/sddm/sync.sh" wall "$img"
