#!/usr/bin/env bash
# Clipboard icon for Waybar: the entry count in the tooltip, a class for highlighting
source ~/.config/theme/lang.sh       # t "English" "Русский"
count=$(cliphist list 2>/dev/null | wc -l)

if (( count > 0 )); then
    printf '{"text":"󰅌","tooltip":"%s","class":"filled"}\n' \
        "$(t "Clipboard: $count\\nLeft click — history · Right click — clear" "Буфер обмена: $count\\nЛКМ — история · ПКМ — очистить")"
else
    printf '{"text":"󰅌","tooltip":"%s","class":"empty"}\n' "$(t "Clipboard is empty" "Буфер обмена пуст")"
fi
