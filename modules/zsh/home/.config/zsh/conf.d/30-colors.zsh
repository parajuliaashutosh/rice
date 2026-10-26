# Terminal tuning — autosuggestion + syntax-highlight palette (Tokyo Night accents, neutral greys).

# Autosuggestion ghost text — neutral grey
ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE='fg=#5e5e5e'
ZSH_AUTOSUGGEST_STRATEGY=(history completion)

# ── What you type is plain foreground ────────────────────────────────────────
# Everything on the command line renders in the foreground colour; only an
# unknown command stays red, so typos are still visible before you hit enter.
typeset -gA ZSH_HIGHLIGHT_STYLES

# Anything the highlighter doesn't have a specific rule for.
ZSH_HIGHLIGHT_STYLES[default]='fg=#d4d4d4'

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
  ZSH_HIGHLIGHT_STYLES[$_hl_white]='fg=#d4d4d4'
done
unset _hl_white

# The two deliberate exceptions.
ZSH_HIGHLIGHT_STYLES[unknown-token]='fg=#f7768e,bold'   # typo / unknown command
ZSH_HIGHLIGHT_STYLES[comment]='fg=#5e5e5e'              # dim, it isn't executed

# ── Terminal cursor: foreground ──────────────────────────────────────────────
# OSC 12 sets the cursor colour (kitty, foot, alacritty, wezterm, xterm…).
# Deferred to the first precmd so it never prints during p10k's instant prompt,
# then unhooks itself — it only needs to run once per shell.
_rice_cursor_color() {
  printf '\e]12;#d4d4d4\a'
  add-zsh-hook -d precmd _rice_cursor_color
  unfunction _rice_cursor_color
}
autoload -Uz add-zsh-hook
add-zsh-hook precmd _rice_cursor_color
