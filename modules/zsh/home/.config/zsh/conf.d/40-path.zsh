# PATH construction. Every entry is guarded so a laptop that lacks a toolchain
# just gets a shorter PATH instead of a broken one.

typeset -U path PATH   # keep PATH deduplicated

path_prepend() { [[ -d "$1" ]] && path=("$1" $path); }
path_append()  { [[ -d "$1" ]] && path+=("$1"); }

path_prepend "$HOME/.local/bin"
path_prepend "$HOME/bin"

path_append "$HOME/go/bin"
path_append "$HOME/.cargo/bin"
path_append "$HOME/.bun/bin"
path_append "$HOME/.opencode/bin"

export PATH
