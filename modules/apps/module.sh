#!/usr/bin/env bash
# apps module: everyday apps for a fresh install — Brave, Chrome, Firefox, VS Code, Docker,
# kubectl, Slack, OBS Studio.
# Fedora (dnf), openSUSE (zypper) and Arch (pacman + AUR) only; anything else is skipped.
# Official packages first: distro repos, then each vendor's own repo added the way the vendor
# documents it; Flathub/AUR only when there's no official package. Slack comes from Flathub everywhere;
# OBS is the distro package on Fedora/Arch and Flathub on openSUSE (only Packman ships it there).
# To add more: plain distro packages go in EXTRA_PKGS, Flathub apps in FLATPAKS.

EXTRA_PKGS=(git curl jq)
FLATPAKS=(com.slack.Slack)

if [ "${SKIP_DEPS:-0}" = "1" ]; then
  skip "dependency install disabled (--no-deps) — nothing else to do"
  return 0 2>/dev/null || exit 0
fi

PM="$(pkg_manager)"
case "$PM" in
dnf | zypper | pacman) ;;
*)
  skip "apps module supports Fedora, openSUSE and Arch only"
  return 0 2>/dev/null || exit 0
  ;;
esac

SUDO=""
[ "$(id -u)" -ne 0 ] && SUDO="sudo"

# ── helpers ──────────────────────────────────────────────────────────────────
# add_rpm_repo <name> <url-of-.repo-file | inline contents>
# A URL is added with each vendor's documented command (dnf config-manager / zypper addrepo);
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
      run $SUDO zypper --non-interactive addrepo "$src"
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
  fi
}

# aur_install <pkg>... — uses paru/yay, bootstrapping yay-bin if neither is present.
aur_install() {
  local helper="" h
  for h in paru yay; do have "$h" && helper="$h" && break; done
  if [ -z "$helper" ]; then
    info "no AUR helper — bootstrapping yay-bin"
    pkg_install base-devel git
    local tmp
    tmp="$(mktemp -d)"
    clone_or_update https://aur.archlinux.org/yay-bin.git "$tmp/yay-bin" --depth 1
    [ "$DRY_RUN" = "1" ] || (cd "$tmp/yay-bin" && makepkg -si --noconfirm)
    rm -rf "$tmp"
    helper="yay"
  fi
  local missing=() p
  for p in "$@"; do pacman -Qi "$p" >/dev/null 2>&1 || missing+=("$p"); done
  [ ${#missing[@]} -eq 0 ] && { skip "already installed: $*"; return 0; }
  run "$helper" -S --needed --noconfirm "${missing[@]}"
}

# ── 1. vendor repos (rpm distros) ────────────────────────────────────────────
if [ "$PM" != "pacman" ]; then
  have curl || pkg_install curl

  add_rpm_repo brave-browser https://brave-browser-rpm-release.s3.brave.com/brave-browser.repo

  add_rpm_repo google-chrome "[google-chrome]
name=google-chrome
baseurl=https://dl.google.com/linux/chrome/rpm/stable/x86_64
enabled=1
gpgcheck=1
gpgkey=https://dl.google.com/linux/linux_signing_key.pub"

  add_rpm_repo vscode "[code]
name=Visual Studio Code
baseurl=https://packages.microsoft.com/yumrepos/vscode
enabled=1
autorefresh=1
type=rpm-md
gpgcheck=1
gpgkey=https://packages.microsoft.com/keys/microsoft.asc"

  # kubectl repos are per minor version; follow whatever is current stable
  k8s_minor="$(curl -fsSL https://dl.k8s.io/release/stable.txt 2>/dev/null | grep -oE '^v[0-9]+\.[0-9]+')"
  if [ -n "$k8s_minor" ]; then
    add_rpm_repo kubernetes "[kubernetes]
name=Kubernetes
baseurl=https://pkgs.k8s.io/core:/stable:/$k8s_minor/rpm/
enabled=1
gpgcheck=1
gpgkey=https://pkgs.k8s.io/core:/stable:/$k8s_minor/rpm/repodata/repomd.xml.key"
  else
    warn "could not look up the current Kubernetes release — skipping kubectl repo"
  fi

  # Docker's own repo on Fedora; openSUSE ships docker in its main repos
  [ "$PM" = "dnf" ] && add_rpm_repo docker-ce https://download.docker.com/linux/fedora/docker-ce.repo

  [ "$PM" = "zypper" ] && run $SUDO zypper --non-interactive --gpg-auto-import-keys refresh
fi

# ── 2. packages ──────────────────────────────────────────────────────────────
pkg_install "${EXTRA_PKGS[@]}" flatpak

case "$PM" in
dnf)
  pkg_install brave-browser google-chrome-stable firefox code kubectl obs-studio
  # Docker CE can lag behind a brand-new Fedora release; fall back to Fedora's moby-engine
  pkg_install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin ||
    pkg_install moby-engine docker-compose docker-buildx
  ;;
zypper)
  pkg_install brave-browser google-chrome-stable MozillaFirefox code kubectl docker docker-compose docker-buildx
  FLATPAKS+=(com.obsproject.Studio)
  ;;
pacman)
  pkg_install firefox obs-studio docker docker-compose docker-buildx kubectl
  aur_install brave-bin google-chrome visual-studio-code-bin
  ;;
esac

# ── 3. Flathub apps ──────────────────────────────────────────────────────────
if have flatpak || [ "$DRY_RUN" = "1" ]; then
  run $SUDO flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo
  for app in "${FLATPAKS[@]}"; do
    if flatpak info "$app" >/dev/null 2>&1; then
      skip "$app already installed"
    elif { [ "$app" = "com.slack.Slack" ] && have slack; } || { [ "$app" = "com.obsproject.Studio" ] && have obs; }; then
      skip "$app already installed natively"
    else
      run $SUDO flatpak install -y --noninteractive flathub "$app"
    fi
  done
fi

# ── 4. docker without sudo ───────────────────────────────────────────────────
if have docker || [ "$DRY_RUN" = "1" ]; then
  run $SUDO systemctl enable --now docker
  getent group docker >/dev/null || run $SUDO groupadd docker
  user="${SUDO_USER:-$USER}"
  if id -nG "$user" | tr ' ' '\n' | grep -qx docker; then
    skip "$user already in the docker group"
  else
    run $SUDO usermod -aG docker "$user"
    warn "added $user to the docker group — log out and back in (or run: newgrp docker) to use docker without sudo"
  fi
fi
