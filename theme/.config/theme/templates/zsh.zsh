# zsh palette: {{name}}
# GENERATED from theme/palettes — don't edit by hand.

ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE='fg={{muted}}'

typeset -gA ZSH_HIGHLIGHT_STYLES
ZSH_HIGHLIGHT_STYLES[command]='fg={{blue}}'
ZSH_HIGHLIGHT_STYLES[builtin]='fg={{blue}}'
ZSH_HIGHLIGHT_STYLES[alias]='fg={{blue}}'
ZSH_HIGHLIGHT_STYLES[function]='fg={{blue}}'
ZSH_HIGHLIGHT_STYLES[precommand]='fg={{violet}},italic'
ZSH_HIGHLIGHT_STYLES[reserved-word]='fg={{violet}}'
ZSH_HIGHLIGHT_STYLES[unknown-token]='fg={{rose}}'
ZSH_HIGHLIGHT_STYLES[path]='fg={{text}},underline'
ZSH_HIGHLIGHT_STYLES[single-quoted-argument]='fg={{cyan}}'
ZSH_HIGHLIGHT_STYLES[double-quoted-argument]='fg={{cyan}}'
ZSH_HIGHLIGHT_STYLES[single-hyphen-option]='fg={{subtle}}'
ZSH_HIGHLIGHT_STYLES[double-hyphen-option]='fg={{subtle}}'
ZSH_HIGHLIGHT_STYLES[comment]='fg={{muted}},italic'

zstyle ':completion:*:descriptions' format '%F{{{violet}}}── %d ──%f'

export FZF_DEFAULT_OPTS="
  --height 40% --layout reverse --border rounded --info inline
  --prompt '❯ ' --pointer '▌' --marker '•'
  --color bg:-1,bg+:{{surface}},fg:{{subtle}},fg+:{{bright}}
  --color hl:{{blue}},hl+:{{blue}},border:{{overlay}},gutter:-1
  --color prompt:{{violet}},pointer:{{blue}},marker:{{cyan}},info:{{muted}},spinner:{{violet}}"
