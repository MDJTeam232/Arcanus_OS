#!/usr/bin/env bash
set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ERRORS=0
WARNINGS=0

# Profile selection (defaults to desktop)
PROFILE="desktop"
if [[ $# -gt 0 ]]; then
  case "$1" in
    --desktop) PROFILE="desktop" ;;
    --tablet)  PROFILE="tablet" ;;
    *) echo "Unknown option: $1 (Use --desktop or --tablet)" >&2; exit 2 ;;
  esac
fi

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

pass() {
  echo -e "${GREEN}OK${NC} $1"
}

warn() {
  echo -e "${YELLOW}WARN${NC} $1"
  WARNINGS=$((WARNINGS + 1))
}

fail() {
  echo -e "${RED}FAIL${NC} $1"
  ERRORS=$((ERRORS + 1))
}

require_file() {
  local path="$1"
  [[ -f "$PROJECT_ROOT/$path" ]] && pass "$path" || fail "$path missing"
}

require_dir() {
  local path="$1"
  [[ -d "$PROJECT_ROOT/$path" ]] && pass "$path" || fail "$path missing"
}

contains() {
  local path="$1"
  local text="$2"
  if [[ -f "$PROJECT_ROOT/$path" ]] && grep -q "$text" "$PROJECT_ROOT/$path"; then
    pass "$path contains '$text'"
  else
    fail "$path does not contain '$text'"
  fi
}

echo "Arcanus OS Alpha - scaffold verification [$PROFILE]"
echo "================================================="
echo

echo "Project structure"
echo "-----------------"
for dir in \
  "branding/wallpapers" \
  "branding/icons" \
  "branding/logos" \
  "rootfs" \
  "control-centre" \
  "docs"; do
  require_dir "$dir"
done

# Profile-specific directory structures
if [[ "$PROFILE" == "desktop" ]]; then
  for dir in "branding/boot" "branding/login" "theme/arcanus-dark" "build/mint"; do
    require_dir "$dir"
  done
fi
echo

echo "Branding assets"
echo "---------------"
require_file "branding/logos/arcanus-logo.png"
require_file "branding/wallpapers/arcanus-alpha-wallpaper.png"

if [[ "$PROFILE" == "desktop" ]]; then
  require_file "branding/boot/arcanus/arcanus-logo.png"
  require_file "branding/boot/arcanus/arcanus.plymouth"
  require_file "branding/boot/arcanus/arcanus.script"
  require_file "branding/login/arcanus-login-wallpaper.png"
fi
echo

echo "Rootfs overlay"
echo "--------------"
require_file "rootfs/etc/os-release"
require_file "rootfs/usr/lib/os-release"
require_file "rootfs/etc/lsb-release"
require_file "rootfs/etc/issue"
require_file "rootfs/etc/issue.net"
require_file "rootfs/etc/motd"
require_file "rootfs/etc/hostname"

contains "rootfs/etc/os-release" "Arcanus OS"
contains "rootfs/etc/issue" "Arcanus OS Alpha"
contains "rootfs/etc/motd" "ARCANUS OS"

if [[ "$PROFILE" == "desktop" ]]; then
  require_file "rootfs/etc/casper.conf"
  require_file "rootfs/etc/lightdm/slick-greeter.conf.d/99-arcanus.conf"
  require_file "rootfs/etc/xdg/xfce4/xfconf/xfce-perchannel-xml/xfce4-desktop.xml"
  require_file "rootfs/etc/xdg/xfce4/xfconf/xfce-perchannel-xml/xsettings.xml"
fi
echo

echo "Theme and applications"
echo "----------------------"
require_file "control-centre/arcanus-control-centre"
require_file "control-centre/arcanus-welcome"
require_file "rootfs/usr/share/applications/arcanus-control-centre.desktop"
require_file "rootfs/etc/skel/.config/autostart/arcanus-welcome.desktop"

if [[ "$PROFILE" == "desktop" ]]; then
  require_file "theme/arcanus-dark/index.theme"
  require_file "theme/arcanus-dark/gtk-3.0/gtk.css"
fi
echo

echo "Scripts"
echo "-------"
require_file "scripts/apply-branding.sh"
require_file "scripts/package-artifact.sh"
require_file "scripts/verify-setup.sh"

[[ -x "$PROJECT_ROOT/scripts/apply-branding.sh" ]] && pass "apply-branding.sh executable" || warn "apply-branding.sh is not executable"
[[ -x "$PROJECT_ROOT/scripts/package-artifact.sh" ]] && pass "package-artifact.sh executable" || warn "package-artifact.sh is not executable"
[[ -x "$PROJECT_ROOT/scripts/verify-setup.sh" ]] && pass "verify-setup.sh executable" || warn "verify-setup.sh is not executable"

if [[ "$PROFILE" == "desktop" ]]; then
  require_file "build/build-iso.sh"
  [[ -x "$PROJECT_ROOT/build/build-iso.sh" ]] && pass "build-iso.sh executable" || warn "build-iso.sh is not executable"
fi
echo

echo "Scope guard"
echo "-----------"
# Standard exclusions; skip gracefully when ripgrep is unavailable (e.g. bare hosts)
if command -v rg >/dev/null 2>&1; then
  if rg -n "Arcanus Vault|Vault OS|AV Vault|av-vault|X96Q|Armbian" "$PROJECT_ROOT" \
    -g '!dist/**' \
    -g '!.git/**' \
    -g '!scripts/verify-setup.sh' \
    -g '!*.png' \
    -g '!*.jpg' \
    -g '!*.DS_Store' >/tmp/arcanus-scope-hits.txt; then
    warn "legacy Vault/Armbian terms still exist"
    sed -n '1,40p' /tmp/arcanus-scope-hits.txt
  else
    pass "no legacy Vault/Armbian terms found in active text files"
  fi
else
  warn "ripgrep (rg) not installed; skipped legacy scope scan"
fi
echo

if [[ "$ERRORS" -gt 0 ]]; then
  echo "Verification failed: $ERRORS error(s), $WARNINGS warning(s)"
  exit 1
fi

echo "Verification passed: $WARNINGS warning(s)"
