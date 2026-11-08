# Interface language for shell scripts:  source ~/.config/theme/lang.sh
#   t "English" "Русский"   — prints the string for the current language
#   $ui_lang                — en | ru
ui_lang=$(sed -nE 's/^\s*language\s*=\s*([a-zA-Z]+).*/\1/p' \
    "${XDG_CONFIG_HOME:-$HOME/.config}/theme/settings.conf" 2>/dev/null | tr 'A-Z' 'a-z')
[[ $ui_lang == ru ]] || ui_lang=en

t() { if [[ $ui_lang == ru ]]; then printf '%s' "$2"; else printf '%s' "$1"; fi; }
