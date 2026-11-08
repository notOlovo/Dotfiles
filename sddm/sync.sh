#!/usr/bin/env bash
# Update the login screen without sudo. install.sh hands two theme files in
# /usr/share/sddm/themes/cosmos to the user — the background and theme.conf (palette and
# language); without the rights we quietly exit.
#   sync.sh conf          — palette and language (theme.py after a change)
#   sync.sh wall IMAGE    — background (on-wallpaper.sh after a wallpaper change)
dest=/usr/share/sddm/themes/cosmos
src=$(dirname "$(readlink -f "$0")")/cosmos

# Blur the background in advance: the login screen needs no GPU effects, works on any GPU
blur() {
    magick "$1[0]" -resize 1920x1080^ -gravity center -extent 1920x1080 \
           -blur 0x16 -modulate 75,85 -quality 90 "$2"
}

case $1 in
    conf)
        [[ -w $dest/theme.conf ]] && cat "$src/theme.conf" > "$dest/theme.conf" ;;
    wall)
        [[ -w $dest/background.jpg && -f $2 ]] || exit 0
        tmp=$(mktemp --suffix=.jpg)
        trap 'rm -f "$tmp"' EXIT
        blur "$2" "$tmp" && cat "$tmp" > "$dest/background.jpg" ;;
    *)  echo "usage: sync.sh conf | wall IMG" >&2; exit 1 ;;
esac
