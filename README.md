# dotfiles — quiet deep space

**English** · [Русский](README.ru.md)

A Hyprland desktop for Arch Linux: a dark palette, rare neon blue and violet accents,
small roundings and almost no borders. Everything is deployed with **GNU Stow**,
recolored with one command and available in **English or Russian**.

| | |
|---|---|
| Compositor | Hyprland 0.56 + hypridle, hyprlock (fallback) |
| Desktop shell | Quickshell: widgets, popups, launcher, OSD, lock screen |
| Bar | Waybar |
| Terminal / shell | Kitty, zsh + Starship, eza, bat, fzf, zoxide |
| Notifications | swaync |
| Menus | Rofi (palettes and wallpapers), wlogout (power) |
| Wallpaper | waypaper + swaybg |
| Login screen | custom SDDM theme "Cosmos" (Qt6) |

## Features

- **Palette system.** Cosmos, Gruvbox, Monochrome, Catppuccin and "From wallpaper" (built from the current image). Switch from the Waybar icon and everything is recolored at once: Hyprland, Waybar, Kitty, Rofi, swaync, wlogout, zsh, Starship, GTK, Qt, Neovim, Quickshell and the login screen.
- **Interface language** — English or Russian, one line in a settings file (see below).
- **Desktop widgets** (Quickshell): a clock with an ArchWiki article, weather (Open-Meteo), calendar, system resources, media player. `Win+D` brings them above the windows. On small monitors the whole layout scales down.
- **Custom popups** instead of stock windows: sound, network, Bluetooth, clipboard. Also a keybind cheatsheet (`Win+/`) and a launcher (`Win+A`: fuzzy search, frequent apps, open windows, `>commands`).
- **OSD** for volume, brightness and the microphone. Battery warnings at 20, 10 and 5 %.
- **Idle:** the screen smoothly dims after 5 minutes, locks after 10, sleeps after 30.
- **Telegram** in a dropdown window on `Win+G`. It lives in the tray; notifications go through swaync.
- **iPad as a second screen:** a virtual monitor plus Sunshine, toggled from Waybar, with a choice of which workspace to show (see below).
- **Window snapping** to half of the screen; Waybar restarts itself if it crashes.

## Installation

Requires Arch Linux and, for AUR packages, `yay` or `paru`.

```sh
git clone https://github.com/notOlovo/Dotfiles ~/dotfiles
cd ~/dotfiles
./install.sh          # packages, palette, stow links, waypaper, zsh, NetworkManager and Bluetooth
./install.sh sddm     # optional: the "Cosmos" login screen (sudo, enables sddm.service)
```

Then log in to Hyprland again.

Any files in the way of the links are moved to `~/.config-backup/dotfiles-<date>/`. Nothing is deleted.

| Command | What it does |
|---|---|
| `./install.sh` | full install |
| `./install.sh stow` | only relink the packages (after `git pull`). The `restow` alias does the same |
| `./install.sh sddm` | install or update the login screen theme |

Package lists: [`packages/pacman.txt`](packages/pacman.txt) and [`packages/aur.txt`](packages/aur.txt).

## Language

The interface language lives in one file — [`theme/.config/theme/settings.conf`](theme/.config/theme/settings.conf):

```ini
language = en     # en | ru
```

Switch it with one command:

```sh
~/.config/theme/theme.py language ru
```

or from the launcher: `Win+A`, then `>language ru`. Quickshell switches live; Waybar, wlogout,
swaync, Rofi, hyprlock and the login screen are re-rendered. If you edit the file by hand,
run `~/.config/theme/theme.py apply` once afterwards.

How it works:
- **Quickshell** — `I18n.t("English", "Русский")` from [`services/I18n.qml`](quickshell/.config/quickshell/desktop/services/I18n.qml), which watches `settings.conf`.
- **Shell scripts** — `source ~/.config/theme/lang.sh`, then `t "English" "Русский"`.
- **Static configs** — templates with `{{t:English|Русский}}`, rendered by `theme.py`.
- **Keybind descriptions** in the cheatsheet — comments in `keybinds.conf` written as `# English | Русский`.

## Layout

Each top-level folder is a Stow package and is laid out into `~` as is.

| Package | Target | Contents |
|---|---|---|
| `hypr` | `~/.config/hypr` | `hyprland.conf`, `keybinds.conf`, `hypridle.conf`, `hyprlock.conf`, `scripts/` |
| `quickshell` | `~/.config/quickshell` | `desktop/` (widgets, menus, OSD) and `lock/` (lock screen) |
| `waybar` | `~/.config/waybar` | styles, `scripts/` (player, clipboard, restart) |
| `theme` | `~/.config/theme` | `theme.py`, `settings.conf`, `palettes/`, `templates/`, Rofi menu, wallpaper hook |
| `kitty`, `rofi`, `swaync`, `wlogout`, `starship`, `fastfetch` | `~/.config/…` | app configs |
| `zsh` | `~/.zshenv`, `~/.config/zsh` | `ZDOTDIR`, `.zshrc` |
| `gtk`, `qt` | `~/.config/gtk-3.0`, `qt5ct`, `qt6ct` | adw-gtk3-dark and Fusion with a custom palette |
| `sunshine` | `~/.config/systemd/user` | Sunshine drop-in (linked without folding the directory) |
| `sddm/` | `/usr/share/sddm/themes/cosmos` | login theme. Not Stow — installed by `install.sh sddm` |
| `wallpaper/` | — | wallpapers for waypaper and the theme menu |

## Palettes and generated files

Color files, plus the Waybar config, wlogout layout and swaync config, are **not stored in git**.
`theme.py` renders them from `theme/.config/theme/palettes/<name>.conf`, `settings.conf`
and the templates in `templates/`. To change the Waybar layout, edit `templates/waybar.jsonc`.

```sh
~/.config/theme/theme.py list            # available palettes
~/.config/theme/theme.py apply gruvbox   # apply one
~/.config/theme/theme.py wallpaper IMG   # build the "From wallpaper" palette from an image
```

A new palette is a copy of `palettes/cosmos.conf` with other values; it shows up in the menu right away.
Template placeholders: `{{blue}}` → `#5b8cff`, `{{blue.hex}}` → `5b8cff`, `{{blue.rgb}}` → `91, 140, 255`,
`{{lang}}` → `en`, `{{t:Text|Текст}}` → the string for the current language.

Wallpapers change from the theme icon in Waybar or in waypaper. After a change the
[`on-wallpaper.sh`](theme/.config/theme/on-wallpaper.sh) hook rebuilds the "From wallpaper"
palette (if selected) and updates the login screen background.
Put your own images into `wallpaper/` — only the default one is tracked by git.

## Keybinds

`Win+/` shows the full cheatsheet on screen.

| Keys | Action |
|---|---|
| `Win+T` / `Win+E` / `Win+F` | terminal / files / browser |
| `Win+A` | launcher |
| `Win+Shift+V` | clipboard history |
| `Win+G` | Telegram dropdown |
| `Win+D` | widgets above the windows |
| `Win+L` | lock |
| `Win+Q` | close window |
| `Win+V` / `Win+P` / `Win+C` | floating / pin / center |
| `Win+B` / `Win+Shift+B` | fullscreen / maximize keeping the bar |
| `Win+J` | rotate the split |
| `Win+arrows` | focus |
| `Win+Shift+arrows` | move window |
| `Win+Alt+arrows` | resize |
| `Win+Ctrl+←/→/↑/↓` | half screen left / right / maximize / back to tiling |
| `Win+1…0`, `Win+Shift+1…0` | workspace / move window there |
| `Win+Tab`, `Alt+Tab` | previous workspace, cycle windows |
| `Print`, `Win+Shift+S` | screenshot to clipboard, area to swappy |
| `Win+Shift+R` | rotate the screen by 180° |
| `Win+M` | exit Hyprland |

## Make it yours

| What | Where |
|---|---|
| Monitor and scale | `hypr/.config/hypr/hyprland.conf`, "Monitors" section (now `1.25`) |
| Weather city | `quickshell/.config/quickshell/desktop/services/Weather.qml`: `city`, `lat`, `lon`, `tz` |
| Apps in the binds | `$terminal`, `$browser`, `$fileManager` in `hyprland.conf` |
| Idle timeouts | `hypr/.config/hypr/hypridle.conf` |
| Icons and cursor | `gtk/.config/gtk-3.0/settings.ini`, `qt/.config/qt*ct/qt*ct.conf` (Tela-circle-grey, Bibata-Modern-Ice) |

## iPad as a second screen

[`ipad-display.sh`](hypr/.config/hypr/scripts/ipad-display.sh) creates the `HEADLESS-1` virtual monitor
and starts Sunshine as a user service. The tablet needs Moonlight.

1. Install `sunshine-bin` (AUR) and create a password once in the web UI at `https://localhost:47990`.
2. In `~/.config/sunshine/sunshine.conf` set:
   ```ini
   output_name = HEADLESS-1
   capture = wlr
   ```
   `capture = wlr` is required: through the portal Sunshine takes half a minute to start and crashes on stop.
3. The tablet icon in Waybar:
   - **left click** — pick a workspace and turn on, or turn off if it's already on;
   - **right click** — show another workspace on the iPad without interrupting the stream.

Resolution and scale are at the top of the script (now `2266x1488@60` for an iPad mini, scale `2`).
Tailscale is handy for connecting from anywhere.

## Updating

```sh
cd ~/dotfiles && git pull && ./install.sh stow
```
