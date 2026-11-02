#!/usr/bin/env bash
# session module: what a bare Fedora (Everything "Minimal" / Server minimal) lacks for a desktop:
# audio (PipeWire), portals (screen sharing, file pickers), GPU drivers, Xwayland, wifi +
# bluetooth, fonts (incl. JetBrainsMono Nerd Font and Devanagari for the Nepali date), dark GTK,
# and login: on tty1, logging in starts Hyprland (no display manager, nothing extra in RAM).

MOD="${MODULE_DIR:-$RICE_DIR/modules/session}"
NERD_FONT_URL="https://github.com/ryanoasis/nerd-fonts/releases/latest/download/JetBrainsMono.tar.xz"
FONT_DIR="$HOME/.local/share/fonts/JetBrainsMonoNerd"

# ── 1. packages ──────────────────────────────────────────────────────────────
if [ "${SKIP_DEPS:-0}" = "1" ]; then
  skip "dependency install disabled (--no-deps)"
else
  # audio
  pkg_install pipewire wireplumber pipewire-pulseaudio pipewire-alsa pulseaudio-utils
  # graphics, portals, toolkits
  pkg_install mesa-dri-drivers mesa-vulkan-drivers xorg-x11-server-Xwayland qt6-qtwayland \
    xdg-desktop-portal xdg-desktop-portal-gtk xdg-utils xdg-user-dirs polkit gnome-keyring dconf
  # network, bluetooth, firmware (wifi cards and GPUs need it; minimal installs may not have it)
  pkg_install NetworkManager-wifi NetworkManager-tui network-manager-applet nm-connection-editor \
    bluez blueman linux-firmware
  # fonts, icons, cursor
  pkg_install fontconfig google-noto-sans-fonts google-noto-sans-devanagari-fonts \
    google-noto-color-emoji-fonts jetbrains-mono-fonts-all fontawesome-6-free-fonts \
    adwaita-icon-theme adwaita-cursor-theme
  # everyday tools the binds/bar use
  pkg_install btop tar xz

  # bluetooth isn't enabled on server installs
  if have systemctl && ! systemctl is-enabled bluetooth >/dev/null 2>&1; then
    run $SUDO systemctl enable --now bluetooth && ok "bluetooth service enabled"
  fi
fi

# ── 2. Nerd Font (icons in bar, launcher, lock screen, kitty) ────────────────
# Fedora doesn't package Nerd Fonts; take the official release from the nerd-fonts project.
if fc-list : family 2>/dev/null | grep -q "JetBrainsMono Nerd Font"; then
  skip "JetBrainsMono Nerd Font installed"
elif [ "$DRY_RUN" = "1" ]; then
  skip "would download JetBrainsMono Nerd Font to ${FONT_DIR/#$HOME/\~}"
else
  info "downloading JetBrainsMono Nerd Font"
  tmp="$(mktemp -d)"
  if curl -fsSL --max-time 300 -o "$tmp/font.tar.xz" "$NERD_FONT_URL" &&
    mkdir -p "$FONT_DIR" && tar -xJf "$tmp/font.tar.xz" -C "$FONT_DIR" --wildcards '*.ttf'; then
    fc-cache -f "$FONT_DIR" >/dev/null && ok "JetBrainsMono Nerd Font -> ${FONT_DIR/#$HOME/\~}"
  else
    warn "could not download the Nerd Font — icons will show as boxes (rerun ./install.sh session)"
  fi
  rm -rf "$tmp"
fi

# ── 3. config: dark GTK, user dirs ───────────────────────────────────────────
link_tree "$MOD/home"
have xdg-user-dirs-update && run xdg-user-dirs-update
# libadwaita/GTK4 apps follow this (through the GTK portal), not settings.ini
if have gsettings; then
  run gsettings set org.gnome.desktop.interface color-scheme prefer-dark 2>/dev/null || true
fi

# ── 4. login: tty1 → Hyprland ────────────────────────────────────────────────
# A source line in both profiles: bash is the login shell until you chsh to zsh.
line='[ -f "$HOME/.config/rice/hyprland-autostart.sh" ] && . "$HOME/.config/rice/hyprland-autostart.sh"'
for profile in "$HOME/.bash_profile" "$HOME/.zprofile"; do
  if grep -qF "rice/hyprland-autostart.sh" "$profile" 2>/dev/null; then
    skip "${profile/#$HOME/\~} already starts Hyprland on tty1"
  elif [ "$DRY_RUN" = "1" ]; then
    skip "would add the tty1 autostart line to ${profile/#$HOME/\~}"
  else
    printf '\n# rice: start Hyprland when logging in on tty1\n%s\n' "$line" >>"$profile"
    ok "${profile/#$HOME/\~}: logging in on tty1 starts Hyprland"
  fi
done

# A display manager would start its own session first; tty login is the whole point here.
for dm in gdm sddm lightdm greetd; do
  if systemctl is-enabled "$dm" >/dev/null 2>&1; then
    warn "$dm is enabled — it shows its own login screen. For tty1 login: sudo systemctl disable $dm && sudo systemctl set-default multi-user.target"
  fi
done
