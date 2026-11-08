#!/usr/bin/env bash
# Telegram in a dropdown window (special:telegram).
#   no arguments — show / hide
#   show         — only show (a click on a notification in swaync)

class_re='^(org.telegram.desktop|TelegramDesktop)$'
ws=special:telegram

has_window() { hyprctl clients -j  | jq -e --arg c "$class_re" 'any(.[]; .class | test($c))' >/dev/null; }
visible()    { hyprctl monitors -j | jq -e --arg w "$ws" 'any(.[]; .specialWorkspace.name == $w)' >/dev/null; }

launched=0
if ! has_window; then
    # From the tray or from scratch — the window moves to $ws by the windowrule
    Telegram >/dev/null 2>&1 &
    disown
    for _ in {1..50}; do has_window && break; sleep 0.1; done
    launched=1
fi

if [[ $1 == show || $launched == 1 ]]; then
    visible || hyprctl dispatch togglespecialworkspace telegram
else
    hyprctl dispatch togglespecialworkspace telegram
fi
