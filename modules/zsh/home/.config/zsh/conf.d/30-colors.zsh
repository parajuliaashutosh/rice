# 🇳🇵 Nepal terminal tuning — autosuggestion + syntax-highlight palette.

# Autosuggestion ghost text — muted crimson
ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE='fg=#7A5560'
ZSH_AUTOSUGGEST_STRATEGY=(history completion)

# Syntax highlighting in flag colours
typeset -gA ZSH_HIGHLIGHT_STYLES
ZSH_HIGHLIGHT_STYLES[command]='fg=#DC143C,bold'
ZSH_HIGHLIGHT_STYLES[builtin]='fg=#DC143C,bold'
ZSH_HIGHLIGHT_STYLES[function]='fg=#DC143C,bold'
ZSH_HIGHLIGHT_STYLES[alias]='fg=#DC143C,bold'
ZSH_HIGHLIGHT_STYLES[precommand]='fg=#DC143C,underline'
ZSH_HIGHLIGHT_STYLES[path]='fg=#9BB4E8,underline'
ZSH_HIGHLIGHT_STYLES[single-quoted-argument]='fg=#8FD98F'
ZSH_HIGHLIGHT_STYLES[double-quoted-argument]='fg=#8FD98F'
ZSH_HIGHLIGHT_STYLES[unknown-token]='fg=#FF4D6D,bold'
ZSH_HIGHLIGHT_STYLES[comment]='fg=#6E6A6C'
