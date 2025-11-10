#!/usr/bin/env bash
# Uninstall script for Dhio
# Removes shell rc alias blocks and the ~/.local/bin/dhio wrapper.
# Optionally removes the installation directory (prompt or --yes to force).

set -e

REMOVE_DIR=false
FORCE=false

while [ $# -gt 0 ]; do
  case "$1" in
    --yes|-y)
      FORCE=true; shift ;;
    --remove-dir)
      REMOVE_DIR=true; shift ;;
    --help|-h)
      cat <<EOF
Usage: uninstall.sh [--remove-dir] [--yes]

Options:
  --remove-dir   Also remove the installed Dhio directory (default: $HOME/.local/share/dhio)
  --yes, -y      Do not prompt for confirmation
  --help         Show this help
EOF
      exit 0
      ;;
    *)
      echo "Unknown arg: $1"; exit 1 ;;
  esac
done

DEFAULT_INSTALL_DIR="$HOME/.local/share/dhio"

confirm() {
  if [ "$FORCE" = true ]; then
    return 0
  fi
  read -r -p "$1 [y/N]: " ans
  case "$ans" in
    [Yy]*) return 0 ;;
    *) return 1 ;;
  esac
}

# Remove rc blocks
for rc in "$HOME/.bashrc" "$HOME/.zshrc"; do
  if [ -f "$rc" ] && grep -q "# >>> dhio configuration >>>" "$rc"; then
    if confirm "Remove dhio block from $rc?"; then
      awk 'BEGIN{skip=0} { if ($0=="# >>> dhio configuration >>>") {skip=1; next} if ($0=="# <<< dhio configuration <<<") {skip=0; next} if (!skip) print }' "$rc" > "${rc}.tmp" && mv "${rc}.tmp" "$rc"
      echo "Removed dhio block from $rc"
    else
      echo "Skipped $rc"
    fi
  fi
done

# Remove wrapper
WRAPPER="$HOME/.local/bin/dhio"
if [ -f "$WRAPPER" ]; then
  if confirm "Remove wrapper $WRAPPER?"; then
    rm -f "$WRAPPER"
    echo "Removed wrapper $WRAPPER"
  else
    echo "Skipped wrapper"
  fi
fi

# Optionally remove install dir
if [ "$REMOVE_DIR" = true ]; then
  INSTALL_DIR="$DEFAULT_INSTALL_DIR"
  if [ -d "$INSTALL_DIR" ]; then
    if confirm "Remove install directory $INSTALL_DIR and all files within?"; then
      rm -rf "$INSTALL_DIR"
      echo "Removed $INSTALL_DIR"
    else
      echo "Skipped removing install directory"
    fi
  else
    echo "Install directory $INSTALL_DIR not found"
  fi
fi

echo "Uninstall complete."
