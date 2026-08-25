# Base environment. Sourced first so later fragments can rely on it.

export RICE_DIR="${RICE_DIR:-$HOME/rice}"

export EDITOR="${EDITOR:-nvim}"
(( $+commands[nvim] )) || export EDITOR=vim
export VISUAL="$EDITOR"
export PAGER="${PAGER:-less}"

export LANG="${LANG:-en_US.UTF-8}"

export XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
export XDG_CACHE_HOME="${XDG_CACHE_HOME:-$HOME/.cache}"
export XDG_DATA_HOME="${XDG_DATA_HOME:-$HOME/.local/share}"
