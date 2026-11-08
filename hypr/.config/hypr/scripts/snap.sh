#!/usr/bin/env bash
# Snap a window to half of the screen, like in Windows.
#   snap.sh left|right|top|bottom — half of the screen (the window becomes floating)
#   snap.sh max                   — the whole work area
#   snap.sh tile                  — back to tiling
# Accounts for Waybar (reserved), gaps and the monitor scale.

dir=$1

if [[ $dir == tile ]]; then
    hyprctl dispatch settiled >/dev/null
    exit 0
fi

gap_out=$(hyprctl getoption general:gaps_out -j | jq -r '.custom' | cut -d' ' -f1)
gap_in=$(hyprctl getoption general:gaps_in -j | jq -r '.custom' | cut -d' ' -f1)

# x y w h — the focused monitor's work area in logical pixels
read -r ax ay aw ah < <(hyprctl monitors -j | jq -r --argjson g "$gap_out" '
    .[] | select(.focused)
    | (if .transform % 2 == 1 then [.height, .width] else [.width, .height] end) as [$pw, $ph]
    | ($pw / .scale | floor) as $w | ($ph / .scale | floor) as $h
    | .reserved as [$rl, $rt, $rr, $rb]
    | "\(.x + $rl + $g) \(.y + $rt + $g) \($w - $rl - $rr - 2*$g) \($h - $rt - $rb - 2*$g)"')

mid=$(( gap_in * 2 ))         # the same gap between halves as between tiles
hw=$(( (aw - mid) / 2 ))
hh=$(( (ah - mid) / 2 ))

case $dir in
    left)   x=$ax;              y=$ay;              w=$hw; h=$ah ;;
    right)  x=$(( ax+hw+mid )); y=$ay;              w=$hw; h=$ah ;;
    top)    x=$ax;              y=$ay;              w=$aw; h=$hh ;;
    bottom) x=$ax;              y=$(( ay+hh+mid )); w=$aw; h=$hh ;;
    max)    x=$ax;              y=$ay;              w=$aw; h=$ah ;;
    *) echo "usage: snap.sh left|right|top|bottom|max|tile" >&2; exit 1 ;;
esac

[[ $(hyprctl activewindow -j | jq -r '.floating') == true ]] || hyprctl dispatch setfloating >/dev/null

hyprctl --batch "dispatch resizeactive exact $w $h; dispatch moveactive exact $x $y" >/dev/null
