#!/usr/bin/env bash
# zsh module: oh-my-zsh + powerlevel10k + plugins, and the config tree.

MOD="${MODULE_DIR:-$RICE_DIR/modules/zsh}"

ZSH_DIR="$HOME/.oh-my-zsh"
ZSH_CUSTOM="$ZSH_DIR/custom"

# ── 1. system packages ───────────────────────────────────────────────────────
if [ "${SKIP_DEPS:-0}" = "1" ]; then
  skip "dependency install disabled (--no-deps)"
else
  pkg_install zsh git curl
fi

# ── 2. oh-my-zsh ─────────────────────────────────────────────────────────────
clone_or_update https://github.com/ohmyzsh/ohmyzsh.git "$ZSH_DIR" --depth=1

# ── 3. theme + plugins ───────────────────────────────────────────────────────
clone_or_update https://github.com/romkatv/powerlevel10k.git \
  "$ZSH_CUSTOM/themes/powerlevel10k" --depth=1
clone_or_update https://github.com/zsh-users/zsh-autosuggestions.git \
  "$ZSH_CUSTOM/plugins/zsh-autosuggestions" --depth=1
clone_or_update https://github.com/zsh-users/zsh-syntax-highlighting.git \
  "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting" --depth=1

# ── 4. config files ──────────────────────────────────────────────────────────
link_tree "$MOD/home"

# Machine-specific overrides live outside the repo and are sourced last.
if [ ! -e "$HOME/.zshrc.local" ]; then
  run cp "$MOD/zshrc.local.example" "$HOME/.zshrc.local"
  ok "created ~/.zshrc.local (machine-specific, not tracked)"
else
  skip "~/.zshrc.local already exists"
fi

# ── 5. default shell ─────────────────────────────────────────────────────────
zsh_path="$(command -v zsh || true)"
if [ -n "$zsh_path" ] && [ "${SHELL:-}" != "$zsh_path" ]; then
  warn "zsh is not your login shell — run: chsh -s $zsh_path"
fi

warn "install a Nerd Font for the p10k prompt glyphs (e.g. MesloLGS NF)"
