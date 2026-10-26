#!/usr/bin/env bash
# apps module (optional): everyday apps — you pick which ones when it runs.
# Official packages first: the distro repo, then the vendor's own repo added the way the vendor
# documents it; Flathub/AUR only when there's no official package (Slack everywhere, OBS on
# openSUSE, Brave/Chrome/VS Code on Arch). Already-installed apps are skipped.
# To add an app: write an install_<name> function and add "<name>|<label>" to APPS.

APPS=(
  "brave|Brave"
  "chrome|Google Chrome"
  "firefox|Firefox"
  "vscode|VS Code"
  "docker|Docker (runs without sudo)"
  "kubectl|kubectl"
  "slack|Slack"
  "obs|OBS Studio"
  "libreoffice|LibreOffice (Writer, Calc, Impress)"
  "nvim|Neovim (with my LazyVim config)"
  "ollama|Ollama (run local LLMs)"
)

if [ "${SKIP_DEPS:-0}" = "1" ]; then
  skip "dependency install disabled (--no-deps) — nothing else to do"
  return 0 2>/dev/null || exit 0
fi

PM="$(pkg_manager)"

# app_installed <name> — already on this machine, from any source (distro, vendor, Flathub, AUR)?
app_installed() {
  case "$1" in
  brave) have brave-browser || have brave ;;
  chrome) have google-chrome-stable || have google-chrome ;;
  firefox) have firefox ;;
  vscode) have code ;;
  docker) have docker ;;
  kubectl) have kubectl ;;
  slack) have slack || flatpak info com.slack.Slack >/dev/null 2>&1 ;;
  obs) have obs || flatpak info com.obsproject.Studio >/dev/null 2>&1 ;;
  libreoffice) have libreoffice || have soffice ;;
  nvim) have nvim && [ -L "$HOME/.config/nvim/init.lua" ] ;;
  ollama) have ollama ;;
  *) return 1 ;;
  esac
}

# ── pick apps ────────────────────────────────────────────────────────────────
# Only apps that aren't installed yet are offered. RICE_APPS="brave docker" (or "all") skips
# the question, e.g. for scripted installs.
pick_missing RICE_APPS "apps" app_installed "${APPS[@]}"
[ -n "$PICKED" ] || { return 0 2>/dev/null || exit 0; }
selected="$PICKED"
info "apps: $selected"

# ── helpers ──────────────────────────────────────────────────────────────────
# add_rpm_repo <name> <url-of-.repo-file | inline contents>
# A URL is added with the vendor's documented command (dnf config-manager / zypper addrepo);
# inline contents are written to the repos dir, as Microsoft, Google and Kubernetes document.
add_rpm_repo() {
  local name="$1" src="$2" dir=/etc/yum.repos.d
  [ "$PM" = "zypper" ] && dir=/etc/zypp/repos.d
  if [ -f "$dir/$name.repo" ]; then
    skip "repo $name already configured"
    return 0
  fi
  info "adding repo $name"
  if [[ "$src" == https://* ]]; then
    if [ "$PM" = "zypper" ]; then
      run $SUDO zypper --non-interactive --gpg-auto-import-keys addrepo --refresh "$src"
    elif dnf --version 2>/dev/null | grep -q dnf5; then
      pkg_install dnf-plugins-core
      run $SUDO dnf config-manager addrepo --from-repofile="$src"
    else
      pkg_install dnf-plugins-core
      run $SUDO dnf config-manager --add-repo "$src"
    fi
  elif [ "$DRY_RUN" = "1" ]; then
    skip "would write $dir/$name.repo"
  else
    printf '%s\n' "$src" | $SUDO tee "$dir/$name.repo" >/dev/null
    [ "$PM" = "zypper" ] && $SUDO zypper --non-interactive --gpg-auto-import-keys refresh "$name" >/dev/null
  fi
}

# aur_install <pkg>... — uses paru/yay, bootstrapping yay-bin if neither is present.
aur_install() {
  local helper="" h missing=() p
  for p in "$@"; do pacman -Qi "$p" >/dev/null 2>&1 || missing+=("$p"); done
  [ ${#missing[@]} -eq 0 ] && { skip "already installed: $*"; return 0; }
  for h in paru yay; do have "$h" && helper="$h" && break; done
  if [ -z "$helper" ]; then
    info "no AUR helper — bootstrapping yay-bin"
    pkg_install base-devel git
    local tmp
    tmp="$(mktemp -d)"
    run git clone --quiet --depth 1 https://aur.archlinux.org/yay-bin.git "$tmp/yay-bin"
    [ "$DRY_RUN" = "1" ] || (cd "$tmp/yay-bin" && makepkg -si --noconfirm) || warn "could not build yay"
    rm -rf "$tmp"
    helper="yay"
  fi
  run "$helper" -S --needed --noconfirm "${missing[@]}" || warn "could not install from AUR: ${missing[*]}"
}

# flathub_install <app-id> [native-command] — skipped if installed either way.
flathub_install() {
  local app="$1" native="${2:-}"
  if [ -n "$native" ] && have "$native"; then
    skip "$native already installed"
    return 0
  fi
  pkg_install flatpak
  if flatpak info "$app" >/dev/null 2>&1; then
    skip "$app already installed"
    return 0
  fi
  run $SUDO flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo
  run $SUDO flatpak install -y --noninteractive flathub "$app"
}

# ── one installer per app ────────────────────────────────────────────────────
install_brave() {
  case "$PM" in
  pacman) aur_install brave-bin ;; # Brave's script doesn't cover Arch
  *)
    # Brave's own installer (handles the dnf/zypper repo setup itself).
    if have brave-browser || have brave; then
      skip "brave already installed"
    elif [ "$DRY_RUN" = "1" ]; then
      skip "would run Brave's installer: curl -fsS https://dl.brave.com/install.sh | sh"
    else
      curl -fsS https://dl.brave.com/install.sh | sh
    fi
    ;;
  esac
}

install_chrome() {
  case "$PM" in
  pacman) aur_install google-chrome ;;
  *)
    add_rpm_repo google-chrome "[google-chrome]
name=google-chrome
baseurl=https://dl.google.com/linux/chrome/rpm/stable/x86_64
enabled=1
gpgcheck=1
gpgkey=https://dl.google.com/linux/linux_signing_key.pub"
    pkg_install google-chrome-stable
    ;;
  esac
}

install_firefox() {
  case "$PM" in
  zypper) pkg_install MozillaFirefox ;;
  *) pkg_install firefox ;;
  esac
}

install_vscode() {
  case "$PM" in
  pacman) aur_install visual-studio-code-bin ;;
  *)
    add_rpm_repo vscode "[code]
name=Visual Studio Code
baseurl=https://packages.microsoft.com/yumrepos/vscode
enabled=1
autorefresh=1
type=rpm-md
gpgcheck=1
gpgkey=https://packages.microsoft.com/keys/microsoft.asc"
    pkg_install code
    ;;
  esac
}

install_docker() {
  case "$PM" in
  dnf)
    add_rpm_repo docker-ce https://download.docker.com/linux/fedora/docker-ce.repo
    # Docker CE can lag behind a brand-new Fedora release; fall back to Fedora's moby-engine
    pkg_try docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin ||
      pkg_install moby-engine docker-compose docker-buildx
    ;;
  *) pkg_install docker docker-compose docker-buildx ;;
  esac

  have docker || [ "$DRY_RUN" = "1" ] || { warn "docker not installed — skipping docker setup"; return 0; }
  if systemctl is-enabled --quiet docker 2>/dev/null && systemctl is-active --quiet docker 2>/dev/null; then
    skip "docker service already enabled and running"
  else
    run $SUDO systemctl enable --now docker
  fi
  getent group docker >/dev/null || run $SUDO groupadd docker
  local user="${SUDO_USER:-$USER}"
  if id -nG "$user" | tr ' ' '\n' | grep -qx docker; then
    skip "$user already in the docker group"
  else
    run $SUDO usermod -aG docker "$user"
    warn "added $user to the docker group — log out and back in (or run: newgrp docker) to use docker without sudo"
  fi
}

install_kubectl() {
  case "$PM" in
  pacman) pkg_install kubectl ;;
  *)
    pkg_is_installed kubectl && { skip "packages already present: kubectl"; return 0; }
    # kubectl repos are per minor version; follow whatever is current stable
    local minor
    minor="$(curl -fsSL https://dl.k8s.io/release/stable.txt 2>/dev/null | grep -oE '^v[0-9]+\.[0-9]+' || true)"
    if [ -z "$minor" ]; then
      warn "could not look up the current Kubernetes release — skipping kubectl"
      return 0
    fi
    add_rpm_repo kubernetes "[kubernetes]
name=Kubernetes
baseurl=https://pkgs.k8s.io/core:/stable:/$minor/rpm/
enabled=1
gpgcheck=1
gpgkey=https://pkgs.k8s.io/core:/stable:/$minor/rpm/repodata/repomd.xml.key"
    pkg_install kubectl
    ;;
  esac
}

install_slack() {
  flathub_install com.slack.Slack slack
}

install_obs() {
  case "$PM" in
  zypper) flathub_install com.obsproject.Studio obs ;; # only Packman ships it on openSUSE
  *) pkg_install obs-studio ;;
  esac
}

install_libreoffice() {
  case "$PM" in
  pacman) pkg_install libreoffice-fresh ;;
  *) pkg_install libreoffice-writer libreoffice-calc libreoffice-impress ;;
  esac
}

# Neovim plus what LazyVim needs (git for lazy.nvim, a C compiler for treesitter, ripgrep/fd
# for pickers), then the config from apps/nvim. Plugins install on first launch.
install_nvim() {
  pkg_install neovim git gcc make unzip ripgrep
  case "$PM" in
  dnf) pkg_install fd-find ;;
  *) pkg_install fd ;;
  esac
  link_tree "$RICE_DIR/modules/apps/nvim"
}

# Ollama — local LLM runner. Arch (extra) and openSUSE ship an official package; Fedora has none,
# so there we use Ollama's own install script (it also creates the ollama user and systemd service).
# Afterwards the service is enabled so `ollama run <model>` works without starting a server by hand.
install_ollama() {
  case "$PM" in
  pacman) pkg_install ollama ;;
  zypper) pkg_install ollama ;;
  dnf)
    if have ollama; then
      skip "ollama already installed"
    elif [ "$DRY_RUN" = "1" ]; then
      skip "would run Ollama's installer: curl -fsSL https://ollama.com/install.sh | sh"
    else
      curl -fsSL https://ollama.com/install.sh | sh
    fi
    ;;
  esac

  have ollama || [ "$DRY_RUN" = "1" ] || { warn "ollama not installed — skipping service setup"; return 0; }
  # The Fedora script already enables the service; the distro packages ship it stopped.
  if systemctl list-unit-files ollama.service >/dev/null 2>&1; then
    if systemctl is-enabled --quiet ollama 2>/dev/null && systemctl is-active --quiet ollama 2>/dev/null; then
      skip "ollama service already enabled and running"
    else
      run $SUDO systemctl enable --now ollama
    fi
  else
    skip "no ollama systemd service (it runs on demand)"
  fi
}

# ── install ──────────────────────────────────────────────────────────────────
pkg_install curl
for app in $selected; do
  echo
  info "── $app ──"
  "install_$app"
done
