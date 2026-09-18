export XDG_DATA_HOME="${HOME}"/.local/share/
export XDG_CONFIG_HOME=${HOME}/.config/
export XDG_STATE_HOME=${HOME}/.local/state/
export XDG_CACHE_HOME=${HOME}/.cache/
export DOTNET_CLI_HOME="${XDG_DATA_HOME}"/dotnet/
export GNUPGHOME="${XDG_DATA_HOME}"/gnupg/
export RUSTUP_HOME="${XDG_DATA_HOME}"/rustup/
export CARGO_HOME="${XDG_DATA_HOME}"/cargo/
export LESSHISTFILE="-"
export TS3_CONFIG_DIR="${XDG_CONFIG_HOME}/ts3client/"
export GTK2_RC_FILES="${XDG_CONFIG_HOME}/gtk-2.0/gtkrc-2.0"
export WGETRC="${XDG_CONFIG_HOME}/wget/wgetrc"
export GOPATH="${XDG_DATA_HOME}/go/"
export GOMODCACHE="${XDG_CACHE_HOME}/go/mod/"
export SCREENRC="${XDG_CONFIG_HOME}/screen/screenrc"
export SCREENDIR="${XDG_CACHE_HOME}/screen/"
export NPM_CONFIG_USERCONFIG="${XDG_CONFIG_HOME}/npm/npmrc"
export W3M_DIR="$XDG_STATE_HOME/w3m"
export CUDA_CACHE_PATH="$XDG_CACHE_HOME/nv"
export CLAUDE_CONFIG_DIR="$XDG_CONFIG_HOME/claude"
export BUN_INSTALL="${XDG_DATA_HOME}"/bun
export BUN_INSTALL_CACHE_DIR="${XDG_CACHE_HOME}"/bun

export EDITOR=/usr/bin/nvim
export STARSHIP_CONFIG=${HOME}/.config/starship/starship.toml

export PATH="$PATH:$HOME/.local/share/cargo/bin"
export PATH="$PATH:$HOME/.local/bin"
export PATH="$PATH:$BUN_INSTALL/bin"

export QT_QPA_PLATFORMTHEME=qt5ct:qt6ct

HISTFILE=~/.local/share/zsh/.histfile
HISTSIZE=10000
SAVEHIST=10000

typeset -g -A key

key[Home]="${terminfo[khome]}"
key[End]="${terminfo[kend]}"
key[Insert]="${terminfo[kich1]}"
key[Backspace]="${terminfo[kbs]}"
key[Delete]="${terminfo[kdch1]}"
key[Up]="${terminfo[kcuu1]}"
key[Down]="${terminfo[kcud1]}"
key[Left]="${terminfo[kcub1]}"
key[Right]="${terminfo[kcuf1]}"
key[PageUp]="${terminfo[kpp]}"
key[PageDown]="${terminfo[knp]}"
key[Shift-Tab]="${terminfo[kcbt]}"

[[ -n "${key[Home]}"      ]] && bindkey -- "${key[Home]}"       beginning-of-line
[[ -n "${key[End]}"       ]] && bindkey -- "${key[End]}"        end-of-line
[[ -n "${key[Insert]}"    ]] && bindkey -- "${key[Insert]}"     overwrite-mode
[[ -n "${key[Backspace]}" ]] && bindkey -- "${key[Backspace]}"  backward-delete-char
[[ -n "${key[Delete]}"    ]] && bindkey -- "${key[Delete]}"     delete-char
[[ -n "${key[Up]}"        ]] && bindkey -- "${key[Up]}"         up-line-or-history
[[ -n "${key[Down]}"      ]] && bindkey -- "${key[Down]}"       down-line-or-history
[[ -n "${key[Left]}"      ]] && bindkey -- "${key[Left]}"       backward-char
[[ -n "${key[Right]}"     ]] && bindkey -- "${key[Right]}"      forward-char
[[ -n "${key[PageUp]}"    ]] && bindkey -- "${key[PageUp]}"     beginning-of-buffer-or-history
[[ -n "${key[PageDown]}"  ]] && bindkey -- "${key[PageDown]}"   end-of-buffer-or-history
[[ -n "${key[Shift-Tab]}" ]] && bindkey -- "${key[Shift-Tab]}"  reverse-menu-complete

bindkey "^[[1;5C" forward-word
bindkey "^[[1;5D" backward-word

if (( ${+terminfo[smkx]} && ${+terminfo[rmkx]} )); then
	autoload -Uz add-zle-hook-widget
	function zle_application_mode_start { echoti smkx }
	function zle_application_mode_stop { echoti rmkx }
	add-zle-hook-widget -Uz zle-line-init zle_application_mode_start
	add-zle-hook-widget -Uz zle-line-finish zle_application_mode_stop
fi

if [[ -f /etc/gentoo-release ]]; then
  DISTRO="gentoo"
elif [[ -f /etc/arch-release ]]; then
  DISTRO="arch"
else
  DISTRO="unknown"
fi

autoload -Uz compinit promptinit
compinit
promptinit

zstyle ':completion:*' menu select
zstyle ':completion::complete:*' gain-privileges 1
zstyle ':completion::complete:*' use-cache 1

if [[ "$DISTRO" == "gentoo" ]]; then
  prompt gentoo
fi

if [[ "$DISTRO" == "gentoo" ]]; then
  source /usr/share/zsh/site-functions/zsh-syntax-highlighting.zsh
elif [[ "$DISTRO" == "arch" ]]; then
  source /usr/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
fi

if [[ "$DISTRO" == "gentoo" ]]; then
  source /usr/share/zsh/site-functions/zsh-autosuggestions.zsh
elif [[ "$DISTRO" == "arch" ]]; then
  source /usr/share/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh
fi

eval "$(starship init zsh)"

if [ -f ~/.dir_colors ]; then
    eval "$(dircolors -b ~/.dir_colors)"
elif [ -f /etc/dir_colors ]; then
    eval "$(dircolors -b /etc/dir_colors)"
else
    eval "$(dircolors -b)"
fi
alias ls='ls --color=auto'

shell_aliases_file=$ZDOTDIR/sh_aliases
if [ -f $shell_aliases_file ]; then
    . $shell_aliases_file
fi

FNM_PATH="${HOME}/.local/share//fnm"
if [ -d "$FNM_PATH" ]; then
  export PATH="${HOME}/.local/share//fnm:$PATH"
  eval "`fnm env`"
fi

export PATH="$HOME"/.opencode/bin:$PATH

[ -s "$BUN_INSTALL/_bun" ] && source "$BUN_INSTALL/_bun"
