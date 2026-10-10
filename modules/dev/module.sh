#!/usr/bin/env bash
# dev module: language toolchains — you pick which ones; only missing ones are offered.
#   node   — nvm + the current Node LTS (nvm has no distro package; official installer)
#   java   — SDKMAN + its default Java (an LTS Temurin build; official installer)
#   python — uv (distro package; Astral's installer as fallback)
#   go     — Go (distro package)
# The official installers are told not to edit ~/.zshrc (it's a rice link);
# modules/zsh/.../conf.d/50-tools.zsh loads nvm and SDKMAN instead.
# RICE_DEV="node go" (or "all") skips the question.

TOOLS=(
  "node|Node.js LTS (nvm)"
  "java|Java (SDKMAN)"
  "python|Python tooling (uv)"
  "go|Go"
)
NVM_VERSION="v0.40.3"
NVM_DIR="$HOME/.nvm"
SDKMAN_DIR="$HOME/.sdkman"

if [ "${SKIP_DEPS:-0}" = "1" ]; then
  skip "dependency install disabled (--no-deps) — nothing else to do"
  return 0 2>/dev/null || exit 0
fi

tool_installed() {
  case "$1" in
  node) [ -s "$NVM_DIR/nvm.sh" ] && [ -n "$(ls -A "$NVM_DIR/versions/node" 2>/dev/null)" ] ;;
  java) [ -e "$SDKMAN_DIR/candidates/java/current" ] ;;
  python) have uv ;;
  go) have go ;;
  *) return 1 ;;
  esac
}

pick_missing RICE_DEV "dev tools" tool_installed "${TOOLS[@]}"
[ -n "$PICKED" ] || { return 0 2>/dev/null || exit 0; }
info "dev tools: $PICKED"

install_node() {
  pkg_install curl
  if [ -s "$NVM_DIR/nvm.sh" ]; then
    skip "nvm already installed"
  elif [ "$DRY_RUN" = "1" ]; then
    skip "would install nvm $NVM_VERSION"
  else
    # PROFILE=/dev/null: don't append to ~/.zshrc
    curl -fsSL "https://raw.githubusercontent.com/nvm-sh/nvm/$NVM_VERSION/install.sh" | PROFILE=/dev/null bash
  fi
  if [ "$DRY_RUN" = "1" ]; then
    skip "would run: nvm install --lts"
  else
    # nvm isn't strict-mode safe, so run it in a plain bash
    bash -c ". '$NVM_DIR/nvm.sh' && nvm install --lts && nvm alias default 'lts/*'" ||
      warn "nvm could not install Node LTS"
  fi
}

install_java() {
  pkg_install curl zip unzip tar
  if [ -s "$SDKMAN_DIR/bin/sdkman-init.sh" ]; then
    skip "SDKMAN already installed"
  elif [ "$DRY_RUN" = "1" ]; then
    skip "would install SDKMAN"
  else
    # rcupdate=false: don't edit ~/.zshrc
    curl -fsSL "https://get.sdkman.io?rcupdate=false" | bash
  fi
  if [ "$DRY_RUN" = "1" ]; then
    skip "would run: sdk install java"
  else
    bash -c "export sdkman_auto_answer=true; . '$SDKMAN_DIR/bin/sdkman-init.sh' && sdk install java" ||
      warn "SDKMAN could not install Java"
  fi
}

install_python() {
  pkg_try uv && return 0
  if [ "$DRY_RUN" = "1" ]; then
    skip "would install uv with Astral's installer"
  else
    # UV_NO_MODIFY_PATH: ~/.local/bin is already on PATH via the zsh config
    curl -LsSf https://astral.sh/uv/install.sh | env UV_NO_MODIFY_PATH=1 sh || warn "could not install uv"
  fi
}

install_go() {
  case "$RICE_OS" in
  fedora) pkg_install golang ;;
  *) pkg_install go ;;
  esac
}

for t in $PICKED; do
  echo
  info "── $t ──"
  "install_$t"
done
