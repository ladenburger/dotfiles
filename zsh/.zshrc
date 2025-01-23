# $HOME cleanup
export XDG_DATA_HOME="${HOME}"/.local/share/
export XDG_CONFIG_HOME=${HOME}/.config
export XDG_STATE_HOME=${HOME}/.local/state
export XDG_CACHE_HOME=${HOME}/.cache
export DOTNET_CLI_HOME="${XDG_DATA_HOME}"/dotnet
export GNUPGHOME="${XDG_DATA_HOME}"/gnupg
export RUSTUP_HOME="${XDG_DATA_HOME}"/rustup
export CARGO_HOME="${XDG_DATA_HOME}"/cargo
export LESSHISTFILE="-"
export TS3_CONFIG_DIR="$XDG_CONFIG_HOME/ts3client"
export GTK2_RC_FILES="${XDG_CONFIG_HOME}/gtk-2.0/gtkrc-2.0"
export WGETRC="${XDG_CONFIG_HOME}/wget/wgetrc"
export GOPATH="${XDG_DATA_HOME}/go"
export GOMODCACHE="${XDG_CACHE_HOME}/go/mod"
export SCREENRC="${XDG_CONFIG_HOME}/screen/screenrc"
export SCREENDIR="${XDG_CACHE_HOME}/screen"

export EDITOR=/usr/bin/nvim
export STARSHIP_CONFIG=${HOME}/.config/starship/starship.toml

# remove csharp spyware-default
export DOTNET_CLI_TELEMETRY_OPTOUT=1

# sh history
HISTFILE=~/.local/share/zsh/.histfile
HISTSIZE=10000
SAVEHIST=10000

# create a zkbd compatible hash;
# to add other keys to this hash, see: man 5 terminfo
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

# setup key accordingly
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

# Finally, make sure the terminal is in application mode, when zle is
# active. Only then are the values from $terminfo valid.
if (( ${+terminfo[smkx]} && ${+terminfo[rmkx]} )); then
	autoload -Uz add-zle-hook-widget
	function zle_application_mode_start { echoti smkx }
	function zle_application_mode_stop { echoti rmkx }
	add-zle-hook-widget -Uz zle-line-init zle_application_mode_start
	add-zle-hook-widget -Uz zle-line-finish zle_application_mode_stop
fi

eval "$(starship init zsh)"

autoload -Uz compinit
compinit

zstyle ':completion:*' menu select
zstyle ':completion::complete:*' gain-privileges 1

source /usr/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
source /usr/share/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh

#########################
### Prompt and colors ###
#########################

## Color directories ###
if [ -f ~/.dir_colors ]; then
    eval "$(dircolors -b ~/.dir_colors)"
elif [ -f /etc/dir_colors ]; then
    eval "$(dircolors -b /etc/dir_colors)"
else
    eval "$(dircolors -b)"
fi
alias ls='ls --color=auto'


# Load Angular CLI autocompletion.
source <(ng completion script)

# Load aliases
shell_aliases_file=$ZDOTDIR/sh_aliases
if [ -f $shell_aliases_file ]; then
    . $shell_aliases_file
fi

# fnm
FNM_PATH="/home/benedikt/.local/share//fnm"
if [ -d "$FNM_PATH" ]; then
  export PATH="/home/benedikt/.local/share//fnm:$PATH"
  eval "`fnm env`"
fi
