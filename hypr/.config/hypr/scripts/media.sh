#!/usr/bin/env bash
# Media keys: the action + an on-screen indicator (Quickshell OSD).
#   media.sh volume up|down|mute
#   media.sh mic mute
#   media.sh brightness up|down

osd() { qs ipc -c desktop call osd "$@" >/dev/null 2>&1; }

case "$1 $2" in
    "volume up")       wpctl set-mute @DEFAULT_AUDIO_SINK@ 0
                       wpctl set-volume -l 1.0 @DEFAULT_AUDIO_SINK@ 5%+ ;;
    "volume down")     wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%- ;;
    "volume mute")     wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle ;;
    "mic mute")        wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle; osd mic; exit ;;
    "brightness up")   brightnessctl -q set 5%+ ;;
    "brightness down") brightnessctl -q set 5%- ;;
    *) echo "usage: media.sh volume up|down|mute | mic mute | brightness up|down" >&2; exit 1 ;;
esac

osd "$1"
