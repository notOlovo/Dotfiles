#!/usr/bin/env bash
# Install the dotfiles on Arch Linux.
#   ./install.sh          — everything: packages, palette, stow links, waypaper, zsh, services
#   ./install.sh stow     — only relink the packages (after git pull or edits)
#   ./install.sh sddm     — the Cosmos login screen (needs sudo, changes the system DM)
# Files in the way of stow are moved to ~/.config-backup/<date>; nothing is deleted.
# Interface language: theme/.config/theme/settings.conf (language = en | ru).
set -euo pipefail

cd "$(dirname "$(readlink -f "$0")")"
dotfiles=$PWD

STOW=(hypr waybar kitty zsh rofi starship wlogout swaync quickshell theme gtk qt fastfetch)
NOFOLD=(sunshine)            # systemd doesn't read drop-ins through a symlinked directory
backup="$HOME/.config-backup/dotfiles-$(date +%F-%H%M%S)"

# Not in a Hyprland session (TTY, first install) — nothing to reload after rendering
[[ -z ${HYPRLAND_INSTANCE_SIGNATURE:-} ]] && export THEME_NO_RELOAD=1

say()  { printf '\033[1;34m::\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33m!!\033[0m %s\n' "$*" >&2; }
list() { grep -v '^\s*#' "$1" | sed '/^\s*$/d'; }

packages() {
    say "Packages from the repositories"
    list packages/pacman.txt | sudo pacman -S --needed -

    local aur=""
    command -v yay  >/dev/null && aur=yay
    command -v paru >/dev/null && aur=${aur:-paru}
    if [[ -n $aur ]]; then
        say "Packages from the AUR ($aur)"
        list packages/aur.txt | "$aur" -S --needed -
    else
        warn "No yay/paru — install these manually: $(list packages/aur.txt | tr '\n' ' ')"
    fi
}

# Generated files are not in git — render them from the palette (cosmos by default)
render() {
    say "Palette: $(theme/.config/theme/theme.py current)"
    theme/.config/theme/theme.py apply "$(theme/.config/theme/theme.py current)"
}

# Move foreign files out of the way of future links
backup_conflicts() {
    local pkg f rel target
    for pkg; do
        while IFS= read -r -d '' f; do
            rel=${f#"$pkg"/}
            target=$HOME/$rel
            [[ -e $target || -L $target ]] || continue
            [[ $(readlink -f "$target") == "$dotfiles"/* ]] && continue    # already our link
            mkdir -p "$backup/$(dirname "$rel")"
            mv "$target" "$backup/$rel"
            warn "~/$rel → $backup/$rel"
        done < <(find "$pkg" -type f -print0)
    done
}

link() {
    say "Stow links"
    backup_conflicts "${STOW[@]}" "${NOFOLD[@]}"
    stow -R -t "$HOME" "${STOW[@]}"
    stow -R --no-folding -t "$HOME" "${NOFOLD[@]}"
    command -v systemctl >/dev/null && systemctl --user daemon-reload 2>/dev/null || true
}

# waypaper rewrites its own config.ini, so it isn't in git — set the keys we need
waypaper_config() {
    say "waypaper: wallpaper folder and palette hook"
    python3 - "$dotfiles/wallpaper" <<'EOF'
import configparser, pathlib, sys
walls = pathlib.Path(sys.argv[1])
path = pathlib.Path.home() / ".config/waypaper/config.ini"
cfg = configparser.ConfigParser(interpolation=None)
cfg.read(path)
if not cfg.has_section("Settings"):
    cfg.add_section("Settings")
s = cfg["Settings"]
s["folder"] = str(walls)
s["backend"] = "swaybg"
s["fill"] = "fill"
s["post_command"] = '~/.config/theme/on-wallpaper.sh "$wallpaper"'
if not s.get("wallpaper"):
    first = next(iter(sorted(p for p in walls.iterdir() if p.suffix.lower() in (".jpg", ".jpeg", ".png", ".webp"))), None)
    if first:
        s["wallpaper"] = str(first)
path.parent.mkdir(parents=True, exist_ok=True)
with open(path, "w") as f:
    cfg.write(f)
EOF
}

shell() {
    [[ $(getent passwd "$USER" | cut -d: -f7) == */zsh ]] && return
    say "Default shell — zsh"
    chsh -s "$(command -v zsh)"
}

services() {
    say "System services: NetworkManager, Bluetooth"
    sudo systemctl enable --now NetworkManager.service bluetooth.service
}

sddm_theme() {
    say "SDDM login screen «Cosmos»"
    [[ -f sddm/cosmos/theme.conf ]] || render
    sddm/install.sh
    sudo systemctl enable sddm.service
}

case ${1:-all} in
    all)
        packages
        render
        link
        waypaper_config
        shell
        services
        say "Done. Login screen: ./install.sh sddm · then log in to Hyprland again"
        ;;
    stow) [[ -f hypr/.config/hypr/colors.conf ]] || render; link ;;
    sddm) sddm_theme ;;
    *)    sed -n '2,6p' "$0"; exit 1 ;;
esac
