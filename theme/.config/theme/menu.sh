#!/usr/bin/env bash
# Theme menu (Rofi), opened by the Waybar icon.
#   menu.sh            — main menu
#   menu.sh palette    — choose a palette
#   menu.sh wallpaper  — choose a wallpaper from ~/dotfiles/wallpaper

# A Waybar reload (a palette change does one) kills the process group started by a bar
# click — together with swaybg and this script. Move to our own session.
if [[ -z $THEME_MENU_DETACHED ]]; then
    THEME_MENU_DETACHED=1 exec setsid -f "$0" "$@"
fi

dir=$(dirname "$(readlink -f "$0")")              # dotfiles/theme/.config/theme
source "$dir/lang.sh"                             # t "English" "Русский"
theme="$dir/theme.py"
walls="$(readlink -f "$dir/../../..")/wallpaper"
thumbs="${XDG_CACHE_HOME:-$HOME/.cache}/theme/thumbs"

menu() {
    rofi -dmenu -i -markup-rows "$@"
}

# The current wallpaper — from the waypaper config
current_wallpaper() {
    local w
    w=$(awk -F' = ' '/^wallpaper/ {print $2}' "${XDG_CONFIG_HOME:-$HOME/.config}/waypaper/config.ini")
    echo "${w/#\~/$HOME}"
}

palette() {
    local cur rows sel idx=0 i=0
    cur=$("$theme" current)

    # "name<TAB>●●●●●  Title" — the dots are painted in the palette colors
    while IFS=$'\t' read -r name title colors; do
        [[ $name == wallpaper ]] && continue          # "From wallpaper" — a separate row below
        dots=""
        for c in $colors; do dots+="<span foreground='$c'>●</span>"; done
        mark=""
        [[ $name == "$cur" ]] && { mark="  <span alpha='50%'>· $(t current текущая)</span>"; idx=$i; }
        rows+="$name"$'\t'"$dots  $title$mark"$'\n'
        ((i++))
    done < <("$theme" list)

    # The palette that adapts to the wallpaper on every change
    mark=""
    [[ $cur == wallpaper ]] && { mark="  <span alpha='50%'>· $(t current текущая)</span>"; idx=$i; }
    rows+="wallpaper"$'\t'"<span alpha='70%'>$(printf '\U000F0E09')</span>  $(t "From wallpaper" "Из обоев")$mark"$'\n'

    sel=$(printf '%s' "$rows" | menu -p $'\U000F03D8 ' -selected-row "$idx" \
        -display-columns 2 -display-column-separator $'\t' \
        -theme-str 'window { width: 420px; } listview { lines: 6; }') || exit 0

    name=${sel%%$'\t'*}
    if [[ $name == wallpaper ]]; then
        "$theme" wallpaper "$(current_wallpaper)"
        notify-send -a "$(t Theme Тема)" -i preferences-desktop-theme "$(t Palette Палитра)" "$(t "From wallpaper" "Из обоев")"
    else
        "$theme" apply "$name"
        notify-send -a "$(t Theme Тема)" -i preferences-desktop-theme "$(t Palette Палитра)" "${name^}"
    fi
}

wallpaper() {
    local f base sel
    mkdir -p "$thumbs"

    # 16:10 thumbnails — once per file, otherwise large PNGs slow Rofi down
    sel=$(for f in "$walls"/*.{jpg,jpeg,png,webp}; do
            [[ -f $f ]] || continue
            base=$(basename "$f")
            thumb="$thumbs/${base%.*}.jpg"
            [[ -f $thumb && $thumb -nt $f ]] ||
                magick "$f[0]" -thumbnail 320x200^ -gravity center -extent 320x200 -quality 85 "$thumb"
            printf '%s\0icon\x1f%s\n' "$base" "$thumb"
        done | menu -show-icons -p $'\U000F0E09 ' \
            -theme-str 'window { width: 860px; }
                        listview { columns: 3; lines: 3; spacing: 10px; }
                        element { orientation: vertical; padding: 10px; spacing: 6px; }
                        element-icon { size: 200px; horizontal-align: 0.5; }
                        element-text { horizontal-align: 0.5; }') || exit 0

    # The waypaper hook (on-wallpaper.sh) updates the "From wallpaper" palette and the login screen
    waypaper --wallpaper "$walls/$sel" >/dev/null 2>&1 &
}

case $1 in
    palette)   palette ;;
    wallpaper) wallpaper ;;
    *)
        p=$(t Palette Палитра) w=$(t Wallpaper Обои)
        choice=$(printf '%s\n' $'\U000F03D8  '"$p" $'\U000F0E09  '"$w" |
                 menu -p $'\U000F0E70 ' -theme-str 'window { width: 300px; } listview { lines: 2; }') || exit 0
        case $choice in
            *"$p") palette ;;
            *"$w") wallpaper ;;
        esac
        ;;
esac
