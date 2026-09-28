#!/usr/bin/env bash
# zed module: the Zed editor plus its settings. Extensions are declared in
# settings.json (auto_install_extensions) so Zed pulls them on first launch.

MOD="${MODULE_DIR:-$RICE_DIR/modules/zed}"

# ── 1. zed itself ────────────────────────────────────────────────────────────
# Zed has no distro packages on Linux; the official script installs into
# ~/.local/zed.app and drops a CLI at ~/.local/bin/zed.
if [ "${SKIP_DEPS:-0}" = "1" ]; then
  skip "dependency install disabled (--no-deps)"
elif have zed; then
  skip "zed already installed ($(command -v zed))"
elif [ "$RICE_OS" = "macos" ]; then
  if have brew; then
    run brew install --cask zed
  else
    warn "no brew — install Zed from https://zed.dev/download"
  fi
else
  pkg_install curl
  info "installing zed from zed.dev"
  run sh -c 'curl -fsSL https://zed.dev/install.sh | sh'
  have zed || warn "~/.local/bin is not on PATH — add it to use the 'zed' command"
fi

# ── 2. config ────────────────────────────────────────────────────────────────
link_tree "$MOD/home"
