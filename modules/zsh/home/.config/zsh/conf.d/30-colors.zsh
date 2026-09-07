# 🇳🇵 Nepal terminal tuning — autosuggestion + syntax-highlight palette.

# Autosuggestion ghost text — muted crimson
ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE='fg=#7A5560'
ZSH_AUTOSUGGEST_STRATEGY=(history completion)

# ── What you type is white ───────────────────────────────────────────────────
# Everything on the command line renders white; only an unknown command stays
# red, so typos are still visible before you hit enter.
typeset -gA ZSH_HIGHLIGHT_STYLES

# Anything the highlighter doesn't have a specific rule for.
ZSH_HIGHLIGHT_STYLES[default]='fg=#FFFFFF'

for _hl_white in \
  command builtin function alias suffix-alias global-alias reserved-word \
  precommand commandseparator hashed-command arg0 \
  path path_pathseparator path_prefix path_prefix_pathseparator \
  single-quoted-argument double-quoted-argument dollar-quoted-argument \
  single-quoted-argument-unclosed double-quoted-argument-unclosed \
  dollar-quoted-argument-unclosed rc-quote \
  dollar-double-quoted-argument back-double-quoted-argument \
  back-dollar-quoted-argument back-quoted-argument \
  assign named-fd numeric-fd redirection \
  single-hyphen-option double-hyphen-option \
  history-expansion process-substitution process-substitution-delimiter \
  command-substitution command-substitution-delimiter \
  arithmetic-expansion \
  ; do
  ZSH_HIGHLIGHT_STYLES[$_hl_white]='fg=#FFFFFF'
done
unset _hl_white

# The two deliberate exceptions.
ZSH_HIGHLIGHT_STYLES[unknown-token]='fg=#FF4D6D,bold'   # typo / unknown command
ZSH_HIGHLIGHT_STYLES[comment]='fg=#6E6A6C'              # dim, it isn't executed

# ── Terminal cursor: white ───────────────────────────────────────────────────
# OSC 12 sets the cursor colour (kitty, foot, alacritty, wezterm, xterm…).
# Deferred to the first precmd so it never prints during p10k's instant prompt,
# then unhooks itself — it only needs to run once per shell.
_rice_white_cursor() {
  printf '\e]12;#FFFFFF\a'
  add-zsh-hook -d precmd _rice_white_cursor
  unfunction _rice_white_cursor
}
autoload -Uz add-zsh-hook
add-zsh-hook precmd _rice_white_cursor
