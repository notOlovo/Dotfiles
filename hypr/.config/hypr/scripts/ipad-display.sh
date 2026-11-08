#!/usr/bin/env bash
# iPad as a second screen: a Hyprland virtual monitor + Sunshine (Moonlight on the iPad).
#   ipad-display.sh          — off: pick a workspace and turn on; on: turn off
#   ipad-display.sh pick     — choose which workspace the iPad shows
#   ipad-display.sh status   — state for Waybar (JSON)
# Sunshine knows which monitor to capture: output_name = HEADLESS-1 in sunshine.conf.
# It also needs capture = wlr there: through the portal (the default) Sunshine hangs for 30 s
# on start and crashes on stop — xdg-desktop-portal-hyprland doesn't close the session

source ~/.config/theme/lang.sh       # t "English" "Русский"

name=HEADLESS-1
mode=2266x1488@60          # native iPad mini resolution
position=auto-right
scale=2
unit=app-dev.lizardbyte.app.Sunshine.service
signal=9                   # "signal" of the custom/ipad Waybar module
last="${XDG_STATE_HOME:-$HOME/.local/state}/ipad-display/workspace"

exists() { hyprctl monitors -j | jq -e --arg n "$name" 'any(.[]; .name == $n)' >/dev/null; }
streaming() { systemctl --user is-active --quiet "$unit" || pgrep -x sunshine >/dev/null; }

# The main (non-virtual) screen and the workspace currently shown on the iPad
home_monitor() { hyprctl monitors -j | jq -r --arg n "$name" '[.[] | select(.name != $n)][0].name'; }
ipad_workspace() { hyprctl monitors -j | jq -r --arg n "$name" '.[] | select(.name == $n) | .activeWorkspace.id'; }

notify() {
    notify-send -a "iPad" -i video-display \
        -h string:x-canonical-private-synchronous:ipad-display "$@"
}

refresh_bar() { pkill -RTMIN+$signal -x waybar; }

status() {
    local icon=$'\U000F04F6'                                   # tablet
    if exists && streaming; then
        printf '{"text":"%s","class":"on","tooltip":"%s"}\n' "$icon" \
            "$(t "iPad: second screen on · workspace $(ipad_workspace)\\n$mode · Sunshine is running\\nLeft click — turn off · Right click — another workspace" \
                 "iPad: второй экран включён · рабочее пространство $(ipad_workspace)\\n$mode · Sunshine работает\\nЛКМ — выключить · ПКМ — другое рабочее пространство")"
    elif exists; then
        printf '{"text":"%s","class":"warning","tooltip":"%s"}\n' "$icon" \
            "$(t "iPad: the monitor exists, Sunshine is not running\\nLeft click — turn off" "iPad: монитор есть, Sunshine не запущен\\nЛКМ — выключить")"
    else
        printf '{"text":"%s","class":"off","tooltip":"%s"}\n' "$icon" \
            "$(t "iPad: second screen off\\nLeft click — pick a workspace and turn on" "iPad: второй экран выключен\\nЛКМ — выбрать рабочее пространство и включить")"
    fi
}

# Rofi menu: existing workspaces with their windows + a new empty one.
# Prints the chosen number, or nothing (Esc).
choose() {
    local rows idx sel
    # "number<TAB>markup" — one line per workspace, sorted by number
    rows=$(jq -rn --argjson ws "$(hyprctl workspaces -j)" --argjson cl "$(hyprctl clients -j)" \
                 --arg ipad "$(exists && ipad_workspace)" \
                 --arg empty "$(t empty пусто)" --arg here "$(t "· on the iPad now" "· сейчас на iPad")" '
        def esc: gsub("&"; "&amp;") | gsub("<"; "&lt;") | gsub(">"; "&gt;");
        $ws | map(select(.id > 0)) | sort_by(.id)[] as $w
        | ([$cl[] | select(.workspace.id == $w.id) | .class] | unique | join(", ")) as $apps
        | "\($w.id)\t<b>\($w.id)</b>   \(if $apps == "" then $empty else $apps end | esc)"
          + "  <span alpha=\"45%\">\($w.lastwindowtitle | .[0:48] | esc)</span>"
          + (if ($w.id | tostring) == $ipad then "  <span alpha=\"60%\">\($here)</span>" else "" end)')

    local free=1
    while hyprctl workspaces -j | jq -e --argjson i "$free" 'any(.[]; .id == $i)' >/dev/null; do ((free++)); done
    rows+=$'\n'"$free"$'\t'"<b>+</b>   $(t "new empty workspace" "новое пустое рабочее пространство") <span alpha=\"45%\">($free)</span>"

    # Put the cursor on the previous choice
    idx=$(printf '%s\n' "$rows" | awk -F'\t' -v w="$(cat "$last" 2>/dev/null)" '$1 == w { print NR - 1; exit }')

    sel=$(printf '%s\n' "$rows" | rofi -dmenu -i -markup-rows -p $'\U000F04F6 ' \
            -mesg "$(t "Which workspace to show on the iPad" "Какое рабочее пространство показать на iPad")" \
            -selected-row "${idx:-0}" -display-columns 2 -display-column-separator $'\t' \
            -theme-str 'window { width: 640px; } listview { lines: 8; }') || return 1
    printf '%s\n' "${sel%%$'\t'*}"
}

# Move a workspace to the iPad (a new empty one is created right there)
show_on_ipad() {
    local ws=$1 home old
    home=$(home_monitor)
    old=$(ipad_workspace)
    [[ $ws == "$old" ]] && return

    if hyprctl workspaces -j | jq -e --argjson i "$ws" 'any(.[]; .id == $i)' >/dev/null; then
        hyprctl dispatch moveworkspacetomonitor "$ws" "$name" >/dev/null
        hyprctl dispatch focusmonitor "$name" >/dev/null
        hyprctl dispatch workspace "$ws" >/dev/null
    else
        hyprctl dispatch focusmonitor "$name" >/dev/null
        hyprctl dispatch workspace "$ws" >/dev/null
    fi
    # The previous iPad workspace (if it has windows) goes back to the main screen
    [[ -n $old ]] && hyprctl dispatch moveworkspacetomonitor "$old" "$home" >/dev/null 2>&1
    hyprctl dispatch focusmonitor "$home" >/dev/null

    mkdir -p "${last%/*}"
    echo "$ws" > "$last"
}

up() {
    local ws=$1
    # A manually started Sunshine would hold the service's ports
    pkill -x sunshine && sleep 1

    hyprctl output create headless "$name" >/dev/null
    hyprctl keyword monitor "$name, $mode, $position, $scale" >/dev/null
    show_on_ipad "$ws"

    # The service needs the session environment to capture Wayland
    systemctl --user import-environment WAYLAND_DISPLAY HYPRLAND_INSTANCE_SIGNATURE XDG_CURRENT_DESKTOP
    if systemctl --user start "$unit" && sleep 1 && streaming; then
        notify "$(t "Second screen on" "Второй экран включён")" "$(t "The iPad shows workspace $ws · connect from Moonlight" "На iPad — рабочее пространство $ws · подключитесь из Moonlight")"
    else
        notify -u critical "$(t "Sunshine failed to start" "Sunshine не запустился")" "$(t "The monitor is created. Log" "Монитор создан. Лог"): journalctl --user -u $unit"
    fi
}

down() {
    systemctl --user stop "$unit"
    pkill -x sunshine                                          # and one started outside the service
    hyprctl output remove "$name" >/dev/null                   # windows return to the main screen by themselves
    notify "$(t "Second screen off" "Второй экран выключен")" "$(t "Sunshine stopped, $name removed" "Sunshine остановлен, $name удалён")"
}

case $1 in
    status) status; exit ;;
esac

# A double click must not start two toggles at once
exec 9>"${XDG_RUNTIME_DIR:-/tmp}/ipad-display.lock"
flock -n 9 || exit 0

case $1 in
    pick)
        ws=$(choose) || exit 0
        if exists; then
            show_on_ipad "$ws"
            notify "iPad" "$(t "The iPad now shows workspace $ws" "Теперь на iPad — рабочее пространство $ws")"
        else
            up "$ws"
        fi ;;
    *)
        if exists; then down
        else ws=$(choose) || exit 0; up "$ws"
        fi ;;
esac
refresh_bar
