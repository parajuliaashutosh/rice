#!/usr/bin/env bash
# nvim module: Neovim with a LazyVim config. lazy.nvim bootstraps itself and
# pulls the plugins pinned in lazy-lock.json on first launch.

MOD="${MODULE_DIR:-$RICE_DIR/modules/nvim}"

# ── 1. neovim + what LazyVim needs ───────────────────────────────────────────
# git for lazy.nvim, a C compiler for treesitter parsers, ripgrep/fd for pickers.
if [ "${SKIP_DEPS:-0}" = "1" ]; then
  skip "dependency install disabled (--no-deps)"
else
  pkg_install neovim git gcc make unzip ripgrep
  case "$(pkg_manager)" in
    dnf) pkg_install fd-find ;;
    *) pkg_install fd ;;
  esac
fi

# ── 2. config ────────────────────────────────────────────────────────────────
link_tree "$MOD/home"
