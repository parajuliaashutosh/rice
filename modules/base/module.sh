#!/usr/bin/env bash
# base module: end-4's illogical-impulse ("ii") shell — Hyprland, quickshell and their
# dependencies. The hyprland, kitty and quickshell modules layer rice's files on top of it,
# so install.sh always runs this one first.
# Skipped when ii is already installed. end-4's installer supports Fedora and Arch only.

END4_REPO="https://github.com/end-4/dots-hyprland"
# The rice overrides are full copies of a few end-4 files, so pin the commit they were made on.
END4_REF="d192a25f"
END4_DIR="$HOME/.cache/dots-hyprland"

if [ -f "$HOME/.config/quickshell/ii/shell.qml" ]; then
  skip "end-4 illogical-impulse shell already installed"
  return 0 2>/dev/null || exit 0
fi

if [ "${SKIP_DEPS:-0}" = "1" ]; then
  skip "dependency install disabled (--no-deps) — not installing end-4's shell"
  return 0 2>/dev/null || exit 0
fi

if [ "$RICE_OS" = "opensuse" ]; then
  warn "end-4's installer doesn't support openSUSE — install illogical-impulse by hand, then rerun ./install.sh"
  return 0 2>/dev/null || exit 0
fi

pkg_install git
if [ -d "$END4_DIR/.git" ]; then
  skip "$END4_DIR present"
  run git -C "$END4_DIR" fetch --quiet origin
else
  info "cloning $END4_REPO -> $END4_DIR"
  run git clone --quiet "$END4_REPO" "$END4_DIR"
fi
run git -C "$END4_DIR" checkout --quiet "$END4_REF"

# --force: no questions; --skip-sysupdate: don't upgrade the whole system as a side effect.
# Its config files go in first; the rice modules after this replace a few with links.
info "running end-4's installer (asks for sudo; takes a while on a fresh system)"
if [ "$DRY_RUN" = "1" ]; then
  skip "would run: $END4_DIR/setup install --force --skip-sysupdate"
else
  (cd "$END4_DIR" && ./setup install --force --skip-sysupdate)
fi
