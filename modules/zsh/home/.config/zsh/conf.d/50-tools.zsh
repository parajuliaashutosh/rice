# Toolchain / SDK activation. Each block is a no-op when the tool is absent,
# so this file is safe to carry to any machine.

# ── Android SDK + JDK ────────────────────────────────────────────────────────
if [[ -d "$HOME/Android/Sdk" ]]; then
  export ANDROID_HOME="$HOME/Android/Sdk"
  path_prepend "$ANDROID_HOME/platform-tools"
  path_prepend "$ANDROID_HOME/emulator"
  path_prepend "$ANDROID_HOME/cmdline-tools/latest/bin"
fi
if [[ -d "/opt/android-studio/jbr" ]]; then
  export JAVA_HOME="/opt/android-studio/jbr"
  path_prepend "$JAVA_HOME/bin"
fi

# ── bun ──────────────────────────────────────────────────────────────────────
if [[ -d "$HOME/.bun" ]]; then
  export BUN_INSTALL="$HOME/.bun"
  [[ -s "$BUN_INSTALL/_bun" ]] && source "$BUN_INSTALL/_bun"   # completions
fi

# ── railway ──────────────────────────────────────────────────────────────────
[[ -s "$HOME/.railway/env" ]] && source "$HOME/.railway/env"

# ── mise (runtime version manager) ───────────────────────────────────────────
if [[ -x "$HOME/.local/bin/mise" ]]; then
  eval "$("$HOME/.local/bin/mise" activate zsh)"
elif (( $+commands[mise] )); then
  eval "$(mise activate zsh)"
fi

# ── sdkman ───────────────────────────────────────────────────────────────────
# Upstream insists this goes last; keep it at the bottom of this file.
export SDKMAN_DIR="$HOME/.sdkman"
[[ -s "$SDKMAN_DIR/bin/sdkman-init.sh" ]] && source "$SDKMAN_DIR/bin/sdkman-init.sh"

export PATH
