# ==========================================
#  ZSH — "quiet deep space"
#  ZDOTDIR=~/.config/zsh (set in ~/.zshenv)
# ==========================================

# ==========================================
# 1. ENVIRONMENT
# ==========================================
export EDITOR=nvim
export BAT_THEME=ansi     # bat uses the terminal colors — i.e. the current palette
export PATH="$HOME/.local/bin:$PATH"
typeset -U path   # no duplicates in PATH

# ==========================================
# 2. HISTORY
# ==========================================
HISTFILE=~/.zsh_history   # the old history is kept
HISTSIZE=10000
SAVEHIST=10000
setopt SHARE_HISTORY          # Shared history between windows
setopt HIST_IGNORE_DUPS       # Don't record duplicates
setopt HIST_IGNORE_SPACE      # Skip commands starting with a space
setopt HIST_REDUCE_BLANKS

setopt AUTO_CD                # cd without "cd"
setopt INTERACTIVE_COMMENTS

# ==========================================
# 3. COMPLETION
# ==========================================
mkdir -p "$XDG_CACHE_HOME/zsh"
autoload -Uz compinit
compinit -d "$XDG_CACHE_HOME/zsh/zcompdump"

zstyle ':completion:*' menu select
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Za-z}'
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"

# ==========================================
# 4. PLUGINS AND COLORS
# ==========================================
source /usr/share/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh 2>/dev/null
source /usr/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh 2>/dev/null

# Colors of highlighting, suggestions, fzf and the completion menu — from the active palette
source "$ZDOTDIR/colors.zsh"

[ -f /usr/share/fzf/key-bindings.zsh ] && source /usr/share/fzf/key-bindings.zsh
[ -f /usr/share/fzf/completion.zsh ]   && source /usr/share/fzf/completion.zsh

# ==========================================
# 5. ALIASES
# ==========================================
# ls → eza with icons
alias ls='eza --icons=always --group-directories-first'
alias ll='eza -la --icons=always --group-directories-first'
alias tree='eza --tree --icons=always'

# Safe delete/copy
alias rm='rm -i'
alias cp='cp -i'
alias mv='mv -i'

# Quick Arch update
alias update='sudo pacman -Syu'

# cat with highlighting (in pipes bat behaves like plain cat)
alias cat='bat --paging=never --style=plain'

# Dotfiles
alias dots='cd ~/dotfiles'
alias restow='~/dotfiles/install.sh stow'   # relink all packages (the list is in install.sh)

# ==========================================
# 6. LOOK
# ==========================================
fastfetch
eval "$(starship init zsh)"

# zoxide: z <part of a path> — jump to a frequent folder, zi — pick with fzf
eval "$(zoxide init zsh)"
