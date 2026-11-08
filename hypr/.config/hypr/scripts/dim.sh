#!/usr/bin/env bash
# Smooth screen dimming on idle (hypridle).
#   dim.sh on   — remember the brightness and smoothly lower it to 10%
#   dim.sh off  — smoothly restore the original brightness

run="${XDG_RUNTIME_DIR:-/tmp}"
saved="$run/dim-brightness"
fader="$run/dim-fader.pid"

current() { brightnessctl -m | cut -d, -f4 | tr -d '%'; }

# fade FROM TO STEPS — a smooth transition, ~30 ms per step
fade() {
    local from=$1 to=$2 steps=$3 i
    for ((i = 1; i <= steps; i++)); do
        brightnessctl -q set "$(( from + (to - from) * i / steps ))%"
        sleep 0.03
    done
}

# A previous transition is still running (e.g. the mouse moved mid-dim) — stop it
[[ -f $fader ]] && kill "$(<"$fader")" 2>/dev/null
echo $$ > "$fader"

case $1 in
    on)
        cur=$(current)
        [[ -f $saved ]] || echo "$cur" > "$saved"
        (( cur > 10 )) && fade "$cur" 10 40
        ;;
    off)
        [[ -f $saved ]] || exit 0
        orig=$(<"$saved")
        rm -f "$saved"
        fade "$(current)" "$orig" 12
        ;;
esac

rm -f "$fader"
