# oh-my-zsh: theme + plugins.

export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME="powerlevel10k/powerlevel10k"

# Standard plugins live in $ZSH/plugins, custom ones in $ZSH/custom/plugins.
# Keep this list lean — every plugin costs startup time.
plugins=(
  git
  sudo
  docker
  kubectl
  npm
  golang
  command-not-found
  colored-man-pages
  zsh-autosuggestions
  zsh-syntax-highlighting
)

[[ -r "$ZSH/oh-my-zsh.sh" ]] && source "$ZSH/oh-my-zsh.sh"
