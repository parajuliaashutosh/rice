# Quality-of-life aliases.

alias ll='ls -lah --color=auto --group-directories-first'
alias la='ls -A --color=auto'
alias ..='cd ..'
alias ...='cd ../..'

alias gs='git status -sb'
alias gl='git log --oneline --graph --decorate -20'
alias gd='git diff'
# NOTE: overrides oh-my-zsh's git plugin, where gp = 'git push'.
alias gp='git pull --ff-only'

alias reload='exec zsh'
alias rice='cd $RICE_DIR'

# kubernetes contexts
alias k9sremit='k9s --kubeconfig=$HOME/.kube/hamropatro-remit'
alias k9spay='k9s --kubeconfig=$HOME/.kube/hamropatro-pay'
alias k9shome='k9s --kubeconfig=$HOME/.kube/config-homelab'
alias hpk9s='k9s --kubeconfig="$HOME/.kube/hp-dev" --namespace dev'
