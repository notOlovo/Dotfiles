#!/usr/bin/env python3
"""Palette and language switcher.

palettes/<name>.conf + settings.conf + templates/*  →  generated files inside the
dotfiles packages, then a live reload of Hyprland, Waybar, Kitty, swaync and friends.

    theme.py list             — palettes: name<TAB>title<TAB>accents separated by spaces
    theme.py current          — active palette
    theme.py apply [NAME]     — apply a palette (default: the active one, i.e. re-render)
    theme.py wallpaper IMG    — build the "From wallpaper" palette from an image and apply it
    theme.py language [en|ru] — print or set the interface language (settings.conf)

THEME_NO_RELOAD=1 — only write the files, reload nothing.

Template placeholders:
    {{blue}}            → #5b8cff
    {{blue.hex}}        → 5b8cff        (Hyprland: rgb(...), rgba(...ee))
    {{blue.rgb}}        → 91, 140, 255  (CSS: rgba(..., 0.5))
    {{lang}}            → en | ru
    {{t:Text|Текст}}    → the string for the current language
"""

import os
import re
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent            # dotfiles/theme/.config/theme
DOTFILES = ROOT.parents[2]
PALETTES = ROOT / "palettes"
TEMPLATES = ROOT / "templates"
SETTINGS = ROOT / "settings.conf"
STATE = Path(os.environ.get("XDG_STATE_HOME", Path.home() / ".local/state")) / "theme" / "current"
LANGUAGES = ("en", "ru")

# template → files inside dotfiles (stow links them into ~/.config)
TARGETS = {
    "hypr.conf":      ["hypr/.config/hypr/colors.conf"],
    "waybar.css":     ["waybar/.config/waybar/colors.css"],
    "waybar.jsonc":   ["waybar/.config/waybar/config.jsonc"],
    "kitty.conf":     ["kitty/.config/kitty/colors.conf"],
    "rofi.rasi":      ["rofi/.config/rofi/colors.rasi"],
    "wlogout.css":    ["wlogout/.config/wlogout/colors.css"],
    "wlogout.layout": ["wlogout/.config/wlogout/layout"],
    "swaync.css":     ["swaync/.config/swaync/colors.css"],
    "swaync.json":    ["swaync/.config/swaync/config.json"],
    "zsh.zsh":        ["zsh/.config/zsh/colors.zsh"],
    "starship.toml":  ["starship/.config/starship.toml"],
    "gtk.css":        ["gtk/.config/gtk-3.0/gtk.css", "gtk/.config/gtk-4.0/gtk.css"],
    "qtct.conf":      ["qt/.config/qt5ct/colors/theme.conf", "qt/.config/qt6ct/colors/theme.conf"],
    # The Neovim config lives outside dotfiles and reads its palette from ~/.config/theme/generated
    "nvim.lua":       ["theme/.config/theme/generated/nvim.lua"],
    # Login screen: sddm/sync.sh copies it into the system (sddm/install.sh grants the rights)
    "sddm.conf":      ["sddm/cosmos/theme.conf"],
}

# Quickshell watches waybar/colors.css and settings.conf by itself; Rofi and wlogout read
# their files on launch. Waybar goes last: its reload kills processes started from a bar click.
RELOAD = [
    ["hyprctl", "reload"],
    ["pkill", "-SIGUSR1", "-x", "kitty"],
    ["pkill", "-SIGUSR1", "-x", "nvim"],          # colorscheme.lua recolors itself on this signal
    ["swaync-client", "-R"],                      # config (texts)
    ["swaync-client", "-rs"],                     # style
    # GTK3 re-reads gtk.css only when the theme changes — toggle it back and forth
    ["gsettings", "set", "org.gnome.desktop.interface", "gtk-theme", "Adwaita"],
    ["gsettings", "set", "org.gnome.desktop.interface", "gtk-theme", "adw-gtk3-dark"],
    [str(DOTFILES / "sddm/sync.sh"), "conf"],     # login screen palette and language (no sudo)
    ["pkill", "-SIGUSR2", "-x", "waybar"],
]


def read_conf(path):
    """key = value lines; # starts a comment (also at the end of a line)."""
    conf = {}
    for line in Path(path).read_text().splitlines():
        line = line.split("#", 1)[0].strip() if not line.lstrip().startswith("#") else ""
        if "=" in line:
            key, value = (s.strip() for s in line.split("=", 1))
            conf[key] = value
    return conf


def load(name):
    # Palette values are colors like #5b8cff — "#" is not a comment there
    pal = {}
    for line in (PALETTES / f"{name}.conf").read_text().splitlines():
        line = line.strip()
        if not line or line.startswith("#") or "=" not in line:
            continue
        key, value = (s.strip() for s in line.split("=", 1))
        pal[key] = value
    return pal


def language():
    try:
        lang = read_conf(SETTINGS).get("language", "en").lower()
    except FileNotFoundError:
        lang = "en"
    return lang if lang in LANGUAGES else "en"


def render(text, pal, lang):
    # {{t:English|Русский}} first — the strings may contain anything but "|" and "}}"
    text = re.sub(r"\{\{t:(.*?)\|(.*?)\}\}",
                  lambda m: m.group(2) if lang == "ru" else m.group(1), text)

    def sub(m):
        key, fmt = m.group(1), m.group(2)
        if key == "lang":
            return lang
        if key not in pal:
            sys.exit(f"theme: palette has no key '{key}'")
        value = pal[key]
        if fmt == "hex":
            return value.lstrip("#")
        if fmt == "rgb":
            h = value.lstrip("#")
            return ", ".join(str(int(h[i:i + 2], 16)) for i in (0, 2, 4))
        return value

    return re.sub(r"\{\{(\w+)(?:\.(hex|rgb))?\}\}", sub, text)


def current():
    try:
        return STATE.read_text().strip()
    except FileNotFoundError:
        return "cosmos"


def apply(name):
    if not (PALETTES / f"{name}.conf").exists():
        sys.exit(f"theme: no palette '{name}'")
    pal = load(name)
    lang = language()

    for tpl, outs in TARGETS.items():
        text = render((TEMPLATES / tpl).read_text(), pal, lang)
        for out in outs:
            (DOTFILES / out).parent.mkdir(parents=True, exist_ok=True)   # fresh clone: no files yet
            # Write over the existing file (same inode) so file watchers see the change
            with open(DOTFILES / out, "w") as f:
                f.write(text)

    STATE.parent.mkdir(parents=True, exist_ok=True)
    STATE.write_text(name + "\n")

    if os.environ.get("THEME_NO_RELOAD"):         # install outside a session / tests
        return
    for cmd in RELOAD:
        try:
            subprocess.run(cmd, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
        except FileNotFoundError:
            pass        # program not installed (or a fresh install) — nothing to reload


def set_language(lang):
    if lang not in LANGUAGES:
        sys.exit(f"theme: language must be one of: {', '.join(LANGUAGES)}")
    text = SETTINGS.read_text()
    text, n = re.subn(r"(?m)^(\s*language\s*=\s*)\S+", rf"\g<1>{lang}", text)
    if not n:
        text += f"\nlanguage = {lang}\n"
    with open(SETTINGS, "w") as f:                # same inode — Quickshell switches live
        f.write(text)
    apply(current())


def main():
    cmd = sys.argv[1] if len(sys.argv) > 1 else "list"
    if cmd == "list":
        for p in sorted(PALETTES.glob("*.conf")):
            pal = load(p.stem)
            accents = " ".join(pal[k] for k in ("base", "blue", "violet", "cyan", "rose", "text"))
            print(f"{p.stem}\t{pal.get('name', p.stem)}\t{accents}")
    elif cmd == "current":
        print(current())
    elif cmd == "apply" and len(sys.argv) <= 3:
        apply(sys.argv[2] if len(sys.argv) == 3 else current())
    elif cmd == "wallpaper" and len(sys.argv) == 3:
        from wallcolors import generate
        (PALETTES / "wallpaper.conf").write_text(generate(sys.argv[2]))
        apply("wallpaper")
    elif cmd == "language" and len(sys.argv) == 2:
        print(language())
    elif cmd == "language" and len(sys.argv) == 3:
        set_language(sys.argv[2].lower())
    else:
        sys.exit(__doc__)


if __name__ == "__main__":
    main()
