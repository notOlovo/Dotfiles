# dotfiles — тихий глубокий космос

[English](README.md) · **Русский**

Hyprland-рабочий стол для Arch Linux: тёмная палитра, редкие неоновые акценты синего и фиолетового,
маленькие скругления и минимум рамок. Всё раскладывается через **GNU Stow**, перекрашивается одной
командой и работает **на русском или английском**.

| | |
|---|---|
| Композитор | Hyprland 0.56 + hypridle, hyprlock (запасной) |
| Оболочка рабочего стола | Quickshell: виджеты, всплывающие меню, запускатель, OSD, экран блокировки |
| Панель | Waybar |
| Терминал / shell | Kitty, zsh + Starship, eza, bat, fzf, zoxide |
| Уведомления | swaync |
| Меню | Rofi (палитры и обои), wlogout (питание) |
| Обои | waypaper + swaybg |
| Экран входа | своя тема SDDM «Cosmos» (Qt6) |

## Возможности

- **Система палитр.** Cosmos, Gruvbox, Monochrome, Catppuccin и «Из обоев» (собирается по текущей картинке). Переключаются из иконки в Waybar и сразу перекрашивают всё: Hyprland, Waybar, Kitty, Rofi, swaync, wlogout, zsh, Starship, GTK, Qt, Neovim, Quickshell и экран входа.
- **Язык интерфейса** — русский или английский, одна строка в файле настроек (см. ниже).
- **Виджеты на обоях** (Quickshell): часы со статьёй из ArchWiki, погода (Open-Meteo), календарь, ресурсы системы, плеер. `Win+D` поднимает их поверх окон. На маленьких мониторах раскладка уменьшается целиком.
- **Свои всплывающие меню** вместо стандартных окон: звук, сеть, Bluetooth, буфер обмена. Ещё есть шпаргалка хоткеев (`Win+/`) и запускатель (`Win+A`: нечёткий поиск, частые приложения, открытые окна, `>команды`).
- **OSD** громкости, яркости и микрофона. Предупреждения о батарее на 20, 10 и 5 %.
- **Бездействие:** через 5 минут экран плавно тускнеет, через 10 — блокировка, через 30 — сон.
- **Telegram** в выпадающем окне по `Win+G`. Работает в трее, уведомления приходят через swaync.
- **iPad как второй экран:** виртуальный монитор плюс Sunshine. Включается иконкой в Waybar, можно выбрать, какое рабочее пространство показать (см. ниже).
- **Прилипание окон** к половине экрана, а Waybar перезапускается сам, если упадёт.

## Установка

Нужны Arch Linux и, для AUR-пакетов, `yay` или `paru`.

```sh
git clone https://github.com/notOlovo/Dotfiles ~/dotfiles
cd ~/dotfiles
./install.sh          # пакеты, палитра, ссылки stow, waypaper, zsh, NetworkManager и Bluetooth
./install.sh sddm     # необязательно: экран входа «Cosmos» (sudo, включает sddm.service)
```

Затем перезайдите в сессию Hyprland.

Все файлы, которые мешают ссылкам, переезжают в `~/.config-backup/dotfiles-<дата>/`. Ничего не удаляется.

| Команда | Что делает |
|---|---|
| `./install.sh` | полная установка |
| `./install.sh stow` | только перелинковать пакеты (после `git pull`). То же делает алиас `restow` |
| `./install.sh sddm` | поставить или обновить тему экрана входа |

Списки пакетов лежат в [`packages/pacman.txt`](packages/pacman.txt) и [`packages/aur.txt`](packages/aur.txt).

## Язык

Язык интерфейса задаётся в одном файле — [`theme/.config/theme/settings.conf`](theme/.config/theme/settings.conf):

```ini
language = en     # en | ru
```

Переключить одной командой:

```sh
~/.config/theme/theme.py language ru
```

или из запускателя: `Win+A`, затем `>language ru`. Quickshell переключается на лету; Waybar,
wlogout, swaync, Rofi, hyprlock и экран входа рендерятся заново. Если правите файл руками,
после этого один раз выполните `~/.config/theme/theme.py apply`.

Как это устроено:
- **Quickshell** — `I18n.t("English", "Русский")` из [`services/I18n.qml`](quickshell/.config/quickshell/desktop/services/I18n.qml), который следит за `settings.conf`.
- **Скрипты** — `source ~/.config/theme/lang.sh`, дальше `t "English" "Русский"`.
- **Статичные конфиги** — шаблоны с `{{t:English|Русский}}`, их рендерит `theme.py`.
- **Описания хоткеев** в шпаргалке — комментарии в `keybinds.conf` вида `# English | Русский`.

## Структура

Каждая папка верхнего уровня — пакет Stow, он раскладывается в `~` как есть.

| Пакет | Куда | Что внутри |
|---|---|---|
| `hypr` | `~/.config/hypr` | `hyprland.conf`, `keybinds.conf`, `hypridle.conf`, `hyprlock.conf`, `scripts/` |
| `quickshell` | `~/.config/quickshell` | `desktop/` (виджеты, меню, OSD) и `lock/` (экран блокировки) |
| `waybar` | `~/.config/waybar` | стили, `scripts/` (плеер, буфер, перезапуск) |
| `theme` | `~/.config/theme` | `theme.py`, `settings.conf`, `palettes/`, `templates/`, меню Rofi, хук смены обоев |
| `kitty`, `rofi`, `swaync`, `wlogout`, `starship`, `fastfetch` | `~/.config/…` | конфиги приложений |
| `zsh` | `~/.zshenv`, `~/.config/zsh` | `ZDOTDIR`, `.zshrc` |
| `gtk`, `qt` | `~/.config/gtk-3.0`, `qt5ct`, `qt6ct` | adw-gtk3-dark и Fusion со своей палитрой |
| `sunshine` | `~/.config/systemd/user` | drop-in для Sunshine (линкуется без «сворачивания» папки) |
| `sddm/` | `/usr/share/sddm/themes/cosmos` | тема входа. Не Stow, ставится через `install.sh sddm` |
| `wallpaper/` | — | обои для waypaper и меню темы |

## Палитры и генерируемые файлы

Цветовые файлы, а также конфиг Waybar, раскладка wlogout и конфиг swaync **не хранятся в git**.
Их рендерит `theme.py` из `theme/.config/theme/palettes/<имя>.conf`, `settings.conf` и шаблонов
в `templates/`. Чтобы поменять модули Waybar, правьте `templates/waybar.jsonc`.

```sh
~/.config/theme/theme.py list            # доступные палитры
~/.config/theme/theme.py apply gruvbox   # применить
~/.config/theme/theme.py wallpaper IMG   # собрать палитру «Из обоев» по картинке
```

Новая палитра — это копия `palettes/cosmos.conf` с другими значениями. Она сразу появится в меню.
Подстановки в шаблонах: `{{blue}}` → `#5b8cff`, `{{blue.hex}}` → `5b8cff`, `{{blue.rgb}}` → `91, 140, 255`,
`{{lang}}` → `ru`, `{{t:Text|Текст}}` → строка на текущем языке.

Обои меняются через иконку темы в Waybar или через waypaper. После смены хук
[`on-wallpaper.sh`](theme/.config/theme/on-wallpaper.sh) пересобирает палитру «Из обоев», если она
выбрана, и обновляет фон экрана входа. Свои картинки кладите в `wallpaper/` — в git хранятся только
обои по умолчанию.

## Горячие клавиши

`Win+/` показывает полную шпаргалку прямо на экране.

| Клавиши | Действие |
|---|---|
| `Win+T` / `Win+E` / `Win+F` | терминал / файлы / браузер |
| `Win+A` | запускатель |
| `Win+Shift+V` | история буфера обмена |
| `Win+G` | Telegram в выпадающем окне |
| `Win+D` | виджеты поверх окон |
| `Win+L` | заблокировать |
| `Win+Q` | закрыть окно |
| `Win+V` / `Win+P` / `Win+C` | плавающее / закрепить / по центру |
| `Win+B` / `Win+Shift+B` | полный экран / развернуть с панелью |
| `Win+J` | сменить направление разделения |
| `Win+стрелки` | фокус |
| `Win+Shift+стрелки` | переместить окно |
| `Win+Alt+стрелки` | изменить размер |
| `Win+Ctrl+←/→/↑/↓` | половина экрана слева / справа / развернуть / вернуть в тайлинг |
| `Win+1…0`, `Win+Shift+1…0` | рабочее пространство / перенести окно туда |
| `Win+Tab`, `Alt+Tab` | прошлое пространство, переключение окон |
| `Print`, `Win+Shift+S` | скриншот экрана в буфер, области в swappy |
| `Win+Shift+R` | повернуть экран на 180° |
| `Win+M` | выйти из Hyprland |

## Под себя

| Что | Где |
|---|---|
| Монитор и масштаб | `hypr/.config/hypr/hyprland.conf`, раздел «Monitors» (сейчас `1.25`) |
| Город погоды | `quickshell/.config/quickshell/desktop/services/Weather.qml`: `city`, `lat`, `lon`, `tz` |
| Программы в биндах | переменные `$terminal`, `$browser`, `$fileManager` в `hyprland.conf` |
| Время бездействия | `hypr/.config/hypr/hypridle.conf` |
| Иконки и курсор | `gtk/.config/gtk-3.0/settings.ini`, `qt/.config/qt*ct/qt*ct.conf` (Tela-circle-grey, Bibata-Modern-Ice) |

## iPad как второй экран

[`ipad-display.sh`](hypr/.config/hypr/scripts/ipad-display.sh) создаёт виртуальный монитор `HEADLESS-1`
и запускает Sunshine как user-сервис. На планшете нужен Moonlight.

1. Поставьте `sunshine-bin` (AUR) и один раз создайте пароль в веб-интерфейсе `https://localhost:47990`.
2. В `~/.config/sunshine/sunshine.conf` пропишите:
   ```ini
   output_name = HEADLESS-1
   capture = wlr
   ```
   `capture = wlr` обязателен. Через портал Sunshine запускается полминуты и падает при остановке.
3. Иконка планшета в Waybar:
   - **ЛКМ** — выбрать рабочее пространство и включить, или выключить, если экран уже работает;
   - **ПКМ** — показать на iPad другое рабочее пространство, не прерывая трансляцию.

Разрешение и масштаб задаются в начале скрипта (сейчас `2266x1488@60` для iPad mini, масштаб `2`).
Удалённо удобно подключаться через Tailscale.

## Обновление

```sh
cd ~/dotfiles && git pull && ./install.sh stow
```
