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
)

if [ "${SKIP_DEPS:-0}" = "1" ]; then
  skip "dependency install disabled (--no-deps) — nothing else to do"
  return 0 2>/dev/null || exit 0
fi

PM="$(pkg_manager)"

# ── pick apps ────────────────────────────────────────────────────────────────
# RICE_APPS="brave docker" (or "all") skips the question, e.g. for scripted installs.
selected="${RICE_APPS:-}"
if [ -z "$selected" ]; then
  if [ ! -t 0 ]; then
    warn "no terminal to ask which apps to install — skipping (set RICE_APPS=\"all\" or a list)"
    return 0 2>/dev/null || exit 0
  fi
  echo
  i=1
  for entry in "${APPS[@]}"; do
    printf '   %d) %s\n' "$i" "${entry#*|}"
    i=$((i + 1))
  done
  read -r -p "Install which apps? numbers like '1 4 5', 'a' for all, Enter for none: " reply
  case "$reply" in
  a | A | all) selected="all" ;;
  *)
    for n in $reply; do
      [[ "$n" =~ ^[0-9]+$ ]] && [ "$n" -ge 1 ] && [ "$n" -le ${#APPS[@]} ] &&
        selected+=" ${APPS[$((n - 1))]%%|*}"
    done
    ;;
  esac
fi
[ "$selected" = "all" ] && selected="$(for e in "${APPS[@]}"; do printf '%s ' "${e%%|*}"; done)"
if [ -z "${selected// /}" ]; then
  skip "no apps selected"
  return 0 2>/dev/null || exit 0
fi
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
  pacman) aur_install brave-bin ;;
  *)
    add_rpm_repo brave-browser https://brave-browser-rpm-release.s3.brave.com/brave-browser.repo
    pkg_install brave-browser
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

# ── install ──────────────────────────────────────────────────────────────────
pkg_install curl
for app in $selected; do
  echo
  info "── $app ──"
  "install_$app"
done
