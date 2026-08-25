# ~/.zshrc — managed by rice (git@github.com:parajuliaashutosh/rice.git)
#
# This file stays deliberately thin: it enables the p10k instant prompt, then
# sources every fragment in ~/.config/zsh/conf.d in lexical order.
# Add new config as a new numbered file there — don't grow this one.

# ── p10k instant prompt ──────────────────────────────────────────────────────
# Must stay near the top. Anything that may print or prompt goes ABOVE this.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

export ZDOTDIR_CONF="${XDG_CONFIG_HOME:-$HOME/.config}/zsh"

for _rc in "$ZDOTDIR_CONF"/conf.d/*.zsh(N); do
  source "$_rc"
done
unset _rc

# ── machine-specific overrides (never committed) ─────────────────────────────
[[ -f ~/.zshrc.local ]] && source ~/.zshrc.local

# ── p10k prompt config ───────────────────────────────────────────────────────
# To customise, run `p10k configure` or edit ~/.p10k.zsh (tracked by rice).
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh
