#!/usr/bin/env bash
# Data for the clipboard menu (Quickshell).
#   clipboard.sh list        — lines "id<TAB>kind<TAB>thumbnail<TAB>preview", kind: text|link|image
#   clipboard.sh copy ID     — put an entry into the clipboard
#   clipboard.sh delete ID   — delete an entry
#   clipboard.sh wipe        — clear the history

thumbs="${XDG_CACHE_HOME:-$HOME/.cache}/cliphist/thumbs"
mkdir -p "$thumbs"

# A cliphist line for an image: "42<TAB>[[ binary data 1.2 MiB png 1920x1080 ]]"
image_re='^\[\[ binary data (.*) (png|jpe?g|bmp|webp|gif) ([0-9]+x[0-9]+) \]\]'
link_re='^(https?|ftp)://[^ ]+$'

case $1 in
    list)
        cliphist -preview-width 400 list | while IFS=$'\t' read -r id preview; do
            if [[ $preview =~ $image_re ]]; then
                thumb="$thumbs/$id.${BASH_REMATCH[2]}"
                [[ -f $thumb ]] || printf '%s\t\n' "$id" | cliphist decode > "$thumb"
                printf '%s\timage\t%s\t%s · %s\n' "$id" "$thumb" "${BASH_REMATCH[3]}" "${BASH_REMATCH[1]}"
            elif [[ $preview =~ $link_re ]]; then
                printf '%s\tlink\t\t%s\n' "$id" "$preview"
            else
                printf '%s\ttext\t\t%s\n' "$id" "$preview"
            fi
        done
        ;;
    copy)
        printf '%s\t\n' "$2" | cliphist decode | wl-copy
        ;;
    delete)
        printf '%s\t\n' "$2" | cliphist delete
        find "${thumbs:?}" -maxdepth 1 -name "${2:?}.*" -delete
        ;;
    wipe)
        cliphist wipe
        find "${thumbs:?}" -mindepth 1 -maxdepth 1 -delete
        ;;
esac
