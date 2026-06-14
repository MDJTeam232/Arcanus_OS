#!/usr/bin/env bash
set -euo pipefail

if [[ $# -ne 1 ]]; then
  echo "Usage: $0 <mounted-mint-rootfs>" >&2
  exit 2
fi

ROOTFS="${1%/}"
if [[ "$1" == "/" ]]; then
  ROOTFS="/"
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
OVERLAY="$REPO_ROOT/rootfs"
THEME_SRC="$REPO_ROOT/theme/arcanus-dark"

WALLPAPER="$REPO_ROOT/branding/wallpapers/arcanus-alpha-wallpaper.png"
LOGIN_WALLPAPER="$REPO_ROOT/branding/login/arcanus-login-wallpaper.png"
LOGO="$REPO_ROOT/branding/logos/arcanus-logo.png"
BOOT_LOGO="$REPO_ROOT/branding/boot/arcanus/arcanus-logo.png"

if [[ ! -d "$ROOTFS/etc" ]]; then
  echo "Rootfs path does not look valid: $ROOTFS" >&2
  exit 1
fi

copy_tree() {
  local source="$1"
  local target_root="$2"

  while IFS= read -r -d '' dir; do
    local rel="${dir#$source}"
    install -d "$target_root/$rel"
  done < <(find "$source" -type d -print0)

  while IFS= read -r -d '' file; do
    local rel="${file#$source/}"
    local target="$target_root/$rel"
    install -d "$(dirname "$target")"
    install -m 0644 "$file" "$target"
  done < <(find "$source" -type f ! -name ".DS_Store" -print0)
}

seed_existing_users() {
  local home_root="$ROOTFS/home"
  [[ -d "$home_root" ]] || return 0

  while IFS= read -r -d '' home_dir; do
    local autostart_dir="$home_dir/.config/autostart"
    local xfce_dir="$home_dir/.config/xfce4/xfconf/xfce-perchannel-xml"
    local owner

    install -d "$autostart_dir"
    install -m 0644 "$OVERLAY/etc/skel/.config/autostart/arcanus-welcome.desktop" "$autostart_dir/arcanus-welcome.desktop"

    install -d "$xfce_dir"
    install -m 0644 "$OVERLAY/etc/xdg/xfce4/xfconf/xfce-perchannel-xml/xfce4-desktop.xml" "$xfce_dir/xfce4-desktop.xml"
    install -m 0644 "$OVERLAY/etc/xdg/xfce4/xfconf/xfce-perchannel-xml/xsettings.xml" "$xfce_dir/xsettings.xml"

    if owner="$(stat -c "%u:%g" "$home_dir" 2>/dev/null || stat -f "%u:%g" "$home_dir" 2>/dev/null)"; then
      chown -R "$owner" "$autostart_dir" "$home_dir/.config/xfce4" 2>/dev/null || true
    fi
  done < <(find "$home_root" -mindepth 1 -maxdepth 1 -type d -print0)
}

copy_tree "$OVERLAY" "$ROOTFS"
seed_existing_users

install -d "$ROOTFS/usr/share/backgrounds/arcanus"
install -m 0644 "$WALLPAPER" "$ROOTFS/usr/share/backgrounds/arcanus/arcanus-alpha-wallpaper.png"
install -m 0644 "$LOGIN_WALLPAPER" "$ROOTFS/usr/share/backgrounds/arcanus/arcanus-login-wallpaper.png"

install -d "$ROOTFS/usr/share/icons/hicolor/scalable/apps"
cp "$REPO_ROOT/branding/icons/"*.svg "$ROOTFS/usr/share/icons/hicolor/scalable/apps/"

install -d "$ROOTFS/usr/share/pixmaps"
install -m 0644 "$LOGO" "$ROOTFS/usr/share/pixmaps/arcanus-logo.png"

install -d "$ROOTFS/usr/share/plymouth/themes/arcanus"
install -m 0644 "$BOOT_LOGO" "$ROOTFS/usr/share/plymouth/themes/arcanus/arcanus-logo.png"
install -m 0644 "$REPO_ROOT/branding/boot/arcanus/arcanus.plymouth" "$ROOTFS/usr/share/plymouth/themes/arcanus/arcanus.plymouth"
install -m 0644 "$REPO_ROOT/branding/boot/arcanus/arcanus.script" "$ROOTFS/usr/share/plymouth/themes/arcanus/arcanus.script"

install -d "$ROOTFS/usr/share/themes"
copy_tree "$THEME_SRC" "$ROOTFS/usr/share/themes/arcanus-dark"

install -d "$ROOTFS/usr/local/bin"
install -m 0755 "$REPO_ROOT/control-centre/arcanus-control-centre" "$ROOTFS/usr/local/bin/arcanus-control-centre"
install -m 0755 "$REPO_ROOT/control-centre/arcanus-welcome" "$ROOTFS/usr/local/bin/arcanus-welcome"

if [[ "$ROOTFS" == "/" ]]; then
  if command -v update-alternatives >/dev/null 2>&1 && [[ -d /usr/share/plymouth/themes ]]; then
    update-alternatives --install /usr/share/plymouth/themes/default.plymouth default.plymouth /usr/share/plymouth/themes/arcanus/arcanus.plymouth 200 || true
    update-alternatives --set default.plymouth /usr/share/plymouth/themes/arcanus/arcanus.plymouth || true
  fi

  if command -v update-initramfs >/dev/null 2>&1; then
    update-initramfs -u || true
  fi

  if command -v update-grub >/dev/null 2>&1; then
    update-grub || true
  fi
else
  cat <<'NOTE'
Branding was applied to an offline rootfs.

After first boot into that system, run:
  sudo update-alternatives --install /usr/share/plymouth/themes/default.plymouth default.plymouth /usr/share/plymouth/themes/arcanus/arcanus.plymouth 200
  sudo update-alternatives --set default.plymouth /usr/share/plymouth/themes/arcanus/arcanus.plymouth
  sudo update-initramfs -u
  sudo update-grub
NOTE
fi

echo "Applied Arcanus OS Alpha branding to $ROOTFS"
