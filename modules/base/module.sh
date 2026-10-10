#!/usr/bin/env bash
# base module: end-4's illogical-impulse ("ii") shell — Hyprland, quickshell and their
# dependencies. The hyprland, kitty and quickshell modules layer rice's files on top of it,
# so install.sh always runs this one first.
#   - not installed  → run end-4's installer at $RICE_END4_REF (Fedora/Arch; end-4 has no openSUSE)
#   - installed at another version → replace just its quickshell config with $RICE_END4_REF's,
#     because rice's bar/lock files are full copies of files from that commit
#   - installed at $RICE_END4_REF → nothing to do
# A stamp file in the config records the version, so re-runs are instant.

END4_REPO="https://github.com/end-4/dots-hyprland"
END4_SRC="$HOME/.cache/rice-end4" # our own checkout; end-4's ~/.cache/dots-hyprland is left alone
II="$HOME/.config/quickshell/ii"
STAMP="$II/.rice-end4-ref"

end4_checkout() {
  pkg_install git
  if [ -d "$END4_SRC/.git" ]; then
    run git -C "$END4_SRC" fetch --quiet origin || warn "could not fetch end-4 updates"
  else
    info "cloning $END4_REPO -> $END4_SRC"
    run git clone --quiet "$END4_REPO" "$END4_SRC"
  fi
  run git -C "$END4_SRC" checkout --quiet --force "$RICE_END4_REF"
}

stamp() { [ "$DRY_RUN" = "1" ] || echo "$RICE_END4_REF" >"$STAMP"; }

# ── already installed ────────────────────────────────────────────────────────
if [ -f "$II/shell.qml" ]; then
  if [ "$(cat "$STAMP" 2>/dev/null)" = "$RICE_END4_REF" ]; then
    skip "end-4 shell already at $RICE_END4_REF"
    return 0 2>/dev/null || exit 0
  fi
  # Installed with end-4's own installer from the commit rice was built on?
  for src in "$HOME/.cache/dots-hyprland" "$END4_SRC"; do
    if [ -d "$src/.git" ] && [[ "$(git -C "$src" rev-parse HEAD 2>/dev/null)" == "$RICE_END4_REF"* ]]; then
      stamp
      ok "end-4 shell is at $RICE_END4_REF"
      return 0 2>/dev/null || exit 0
    fi
  done

  info "end-4 shell is a different version — switching its quickshell config to $RICE_END4_REF"
  end4_checkout
  if [ "$DRY_RUN" = "1" ]; then
    skip "would copy $END4_SRC/dots/.config/quickshell/ii -> $II"
  else
    # --remove-destination replaces rice's symlinks instead of writing through them;
    # the quickshell module re-links them right after.
    cp -rT --remove-destination "$END4_SRC/dots/.config/quickshell/ii" "$II"
    stamp
    ok "quickshell config now at $RICE_END4_REF"
  fi
  return 0 2>/dev/null || exit 0
fi

# ── fresh install ────────────────────────────────────────────────────────────
if [ "${SKIP_DEPS:-0}" = "1" ]; then
  skip "dependency install disabled (--no-deps) — not installing end-4's shell"
  return 0 2>/dev/null || exit 0
fi
if [ "$RICE_OS" = "opensuse" ]; then
  warn "end-4's installer doesn't support openSUSE — install illogical-impulse by hand, then rerun ./install.sh"
  return 0 2>/dev/null || exit 0
fi

end4_checkout
# --force: no questions; --skip-sysupdate: don't upgrade the whole system as a side effect.
info "running end-4's installer (asks for sudo; takes a while on a fresh system)"
if [ "$DRY_RUN" = "1" ]; then
  skip "would run: $END4_SRC/setup install --force --skip-sysupdate"
else
  (cd "$END4_SRC" && ./setup install --force --skip-sysupdate)
  [ -f "$II/shell.qml" ] && stamp
fi
