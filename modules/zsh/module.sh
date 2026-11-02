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
# The login shell lives in /etc/passwd ($SHELL is only what this session started with)
zsh_path="$(command -v zsh || true)"
user="$(id -un)"
login_shell="$(getent passwd "$user" | cut -d: -f7)"
if [ -z "$zsh_path" ]; then
  warn "zsh not installed — login shell unchanged"
elif [ "$login_shell" = "$zsh_path" ]; then
  skip "zsh is already your login shell"
else
  # usermod via sudo: no password prompt per user like chsh, and works when chsh isn't installed
  run $SUDO usermod -s "$zsh_path" "$user" && ok "login shell set to zsh (from your next login)" ||
    warn "could not change the login shell — run: chsh -s $zsh_path"
fi

if fc-list : family 2>/dev/null | grep -qi "nerd font"; then
  skip "Nerd Font installed (p10k glyphs)"
else
  warn "install a Nerd Font for the p10k prompt glyphs (./install.sh session installs JetBrainsMono Nerd Font)"
fi
