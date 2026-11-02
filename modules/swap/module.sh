#!/usr/bin/env bash
# swap module: same swap setup as the current laptop.
#   zram      Fedora's default (zram-generator-defaults): compressed swap in RAM,
#             min(RAM, 8 GB), priority 100 — used first, fast
#   swapfile  20 GB /swap/swapfile, priority 10, in /etc/fstab — overflow on disk
#   sysctl    vm.swappiness = 60 (/etc/sysctl.d/99-zz-laptop-swappiness.conf)
# The swapfile works on btrfs (Workstation/Everything default: its own /swap subvolume, no
# copy-on-write) and xfs/ext4 (Server default, often on LVM). It's skipped when the disk doesn't
# have the space. RICE_SWAPFILE_GB=8 ./install.sh swap picks another size; 0 = no swapfile.
# Idempotent: an active /swap/swapfile is left as it is.

SWAPFILE=/swap/swapfile
SWAP_GB="${RICE_SWAPFILE_GB:-20}"
SWAP_PRIO=10
SYSCTL_FILE=/etc/sysctl.d/99-zz-laptop-swappiness.conf
SWAPPINESS=60

[ "$RICE_OS" = "fedora" ] || { warn "swap module is written for Fedora (zram-generator) — skipping"; return 0 2>/dev/null || exit 0; }

# ── 1. zram ──────────────────────────────────────────────────────────────────
if [ "${SKIP_DEPS:-0}" != "1" ]; then
  pkg_install zram-generator zram-generator-defaults util-linux
fi
if swapon --show=NAME --noheadings 2>/dev/null | grep -q '^/dev/zram'; then
  skip "zram swap active ($(swapon --show=SIZE --noheadings /dev/zram0 2>/dev/null | xargs))"
elif [ -f /etc/systemd/zram-generator.conf ] || [ -f /usr/lib/systemd/zram-generator.conf ]; then
  run $SUDO systemctl daemon-reload
  run $SUDO systemctl start systemd-zram-setup@zram0.service &&
    ok "zram swap started (Fedora default: min(RAM, 8 GB))" ||
    warn "zram didn't start now — it will after a reboot"
else
  warn "no zram-generator config found — zram not set up"
fi

# ── 2. swapfile ──────────────────────────────────────────────────────────────
fstab_line="$SWAPFILE none swap defaults,pri=$SWAP_PRIO 0 0"

ensure_fstab() {
  if grep -qE "^\s*$SWAPFILE\s" /etc/fstab; then
    skip "$SWAPFILE already in /etc/fstab"
  elif [ "$DRY_RUN" = "1" ]; then
    skip "would add to /etc/fstab: $fstab_line"
  else
    echo "$fstab_line" | $SUDO tee -a /etc/fstab >/dev/null && ok "added $SWAPFILE to /etc/fstab"
  fi
}

if [ "$SWAP_GB" = "0" ]; then
  skip "RICE_SWAPFILE_GB=0 — no swapfile"
elif swapon --show=NAME --noheadings 2>/dev/null | grep -qx "$SWAPFILE"; then
  skip "$SWAPFILE active ($(swapon --show=SIZE --noheadings "$SWAPFILE" | xargs))"
  ensure_fstab
elif [ -f "$SWAPFILE" ]; then
  info "$SWAPFILE exists but isn't active — turning it on"
  ensure_fstab
  run $SUDO swapon -p "$SWAP_PRIO" "$SWAPFILE" && ok "$SWAPFILE on"
else
  fs="$(findmnt -no FSTYPE -T /)"
  free_gb="$(df --output=avail -BG / | tail -1 | tr -dc '0-9')"
  if [ "${free_gb:-0}" -lt $((SWAP_GB + 10)) ]; then
    warn "only ${free_gb} GB free on / — not creating a ${SWAP_GB} GB swapfile (needs ${SWAP_GB} + 10 GB)."
    warn "pick a smaller one: RICE_SWAPFILE_GB=8 ./install.sh swap"
  else
    info "creating ${SWAP_GB} GB $SWAPFILE on $fs"
    case "$fs" in
    btrfs)
      # its own subvolume, so snapshots of / don't include it; mkswapfile sets nodatacow
      pkg_install btrfs-progs
      if [ -e /swap ] && ! $SUDO btrfs subvolume show /swap >/dev/null 2>&1; then
        if [ -n "$(ls -A /swap 2>/dev/null)" ]; then
          die "/swap exists, isn't a btrfs subvolume and isn't empty — move it away and rerun"
        fi
        run $SUDO rmdir /swap
      fi
      [ -e /swap ] || run $SUDO btrfs subvolume create /swap
      run $SUDO btrfs filesystem mkswapfile --size "${SWAP_GB}g" "$SWAPFILE"
      ;;
    xfs | ext4)
      run $SUDO mkdir -p /swap
      run $SUDO fallocate -l "${SWAP_GB}G" "$SWAPFILE" ||
        run $SUDO dd if=/dev/zero of="$SWAPFILE" bs=1M count=$((SWAP_GB * 1024)) status=progress
      run $SUDO chmod 600 "$SWAPFILE"
      run $SUDO mkswap "$SWAPFILE" >/dev/null
      ;;
    *)
      warn "don't know how to make a swapfile on $fs — skipping"
      fs=""
      ;;
    esac
    if [ -n "$fs" ]; then
      # SELinux: give the file the swap label so swapon is allowed at boot
      have restorecon && run $SUDO restorecon -R /swap
      ensure_fstab
      run $SUDO swapon -p "$SWAP_PRIO" "$SWAPFILE" && ok "$SWAPFILE on (priority $SWAP_PRIO, after zram)"
    fi
  fi
fi

# ── 3. swappiness ────────────────────────────────────────────────────────────
if [ "$(cat "$SYSCTL_FILE" 2>/dev/null | grep -E '^\s*vm.swappiness' | tr -dc '0-9')" = "$SWAPPINESS" ]; then
  skip "vm.swappiness = $SWAPPINESS already in $SYSCTL_FILE"
elif [ "$DRY_RUN" = "1" ]; then
  skip "would write vm.swappiness = $SWAPPINESS to $SYSCTL_FILE"
else
  echo "vm.swappiness = $SWAPPINESS" | $SUDO tee "$SYSCTL_FILE" >/dev/null &&
    $SUDO sysctl -q -w vm.swappiness="$SWAPPINESS" && ok "vm.swappiness = $SWAPPINESS ($SYSCTL_FILE)"
fi

swapon --show 2>/dev/null | sed 's/^/      /'
