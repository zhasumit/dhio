#!/usr/bin/env bash
# Simple installer for Dhio notes app.
# Usage: run this from the repo root: ./install.sh
# Or via curl (less recommended):
#   curl -sSL https://raw.githubusercontent.com/zhasumit/dhio/main/install.sh | bash

set -e

# Default install directory when running remote (curl | bash)
DEFAULT_REMOTE_INSTALL_DIR="$HOME/.local/share/dhio"

# If the first arg is 'uninstall', run uninstall flow
if [ "$1" = "uninstall" ]; then
  echo "Uninstalling Dhio (removing shell rc entries and wrapper)..."
  for rc in "$HOME/.bashrc" "$HOME/.zshrc"; do
    if [ -f "$rc" ] && grep -q "# >>> dhio configuration >>>" "$rc"; then
      awk 'BEGIN{skip=0} { if ($0=="# >>> dhio configuration >>>") {skip=1; next} if ($0=="# <<< dhio configuration <<<") {skip=0; next} if (!skip) print }' "$rc" > "${rc}.tmp" && mv "${rc}.tmp" "$rc"
      echo "Removed dhio block from $rc"
    fi
  done

  if [ -f "$HOME/.local/bin/dhio" ]; then
    rm -f "$HOME/.local/bin/dhio"
    echo "Removed wrapper $HOME/.local/bin/dhio"
  fi

  echo "Uninstall complete. Installed files (if any) in the install directory were not removed automatically.\nIf you installed via the one-line installer, you may want to remove $DEFAULT_REMOTE_INSTALL_DIR manually."
  exit 0
fi

# Determine INSTALL_DIR. If dhio.sh is present in cwd, use it; else attempt remote install into DEFAULT_REMOTE_INSTALL_DIR
INSTALL_DIR="$(pwd)"
DHIO_SCRIPT="$INSTALL_DIR/dhio.sh"

if [ ! -f "$DHIO_SCRIPT" ]; then
  echo "dhio.sh not found in current directory ($INSTALL_DIR)."
  echo "Attempting remote install: will download repository into $DEFAULT_REMOTE_INSTALL_DIR"
  INSTALL_DIR="$DEFAULT_REMOTE_INSTALL_DIR"
  if [ -f "$INSTALL_DIR/dhio.sh" ]; then
    echo "Dhio already appears installed at $INSTALL_DIR. Using existing install." 
  else
    mkdir -p "$INSTALL_DIR"
    tmpdir=$(mktemp -d)
    echo "Downloading repository archive..."
    if ! curl -sSL "https://github.com/zhasumit/dhio/archive/refs/heads/main.tar.gz" -o "$tmpdir/repo.tar.gz"; then
      echo "Failed to download repository archive" >&2
      rm -rf "$tmpdir"
      exit 1
    fi
    mkdir -p "$tmpdir/out"
    tar -xzf "$tmpdir/repo.tar.gz" -C "$tmpdir/out" || { echo "Failed to extract archive" >&2; rm -rf "$tmpdir"; exit 1; }
    extracted_dir=$(find "$tmpdir/out" -maxdepth 1 -type d -name "dhio*" | head -n1)
    if [ -z "$extracted_dir" ]; then
      echo "Unexpected archive layout; aborting" >&2
      rm -rf "$tmpdir"
      exit 1
    fi
    # copy contents into INSTALL_DIR
    cp -r "$extracted_dir/." "$INSTALL_DIR/" || { echo "Failed to copy files to $INSTALL_DIR" >&2; rm -rf "$tmpdir"; exit 1; }
    rm -rf "$tmpdir"
    echo "Installed Dhio into $INSTALL_DIR"
  fi
  DHIO_SCRIPT="$INSTALL_DIR/dhio.sh"
fi

# Make dhio.sh executable
chmod +x "$DHIO_SCRIPT"

add_rc() {
  local rcfile="$1"
  local marker="# >>> dhio configuration >>>"
  local endmarker="# <<< dhio configuration <<<"
  if [ -f "$rcfile" ]; then
    if grep -q "${marker}" "$rcfile"; then
      echo "dhio entry already present in $rcfile"
      return
    fi
  else
    touch "$rcfile"
  fi

  cat >> "$rcfile" <<EOF
$marker
# Dhio notes app
export DHIO_DIR="$INSTALL_DIR"
alias dhio="\"\$DHIO_DIR/dhio.sh\""
$endmarker
EOF
  echo "Appended dhio alias to $rcfile"
}

# Add to bashrc and zshrc
add_rc "$HOME/.bashrc"
add_rc "$HOME/.zshrc"

# Optionally add to PATH by creating a small wrapper in ~/.local/bin
LOCAL_BIN="$HOME/.local/bin"
mkdir -p "$LOCAL_BIN"
cat > "$LOCAL_BIN/dhio" <<'EOF'
#!/usr/bin/env bash
"$INSTALL_DIR/dhio.sh" "$@"
EOF
chmod +x "$LOCAL_BIN/dhio"

echo "Created wrapper $LOCAL_BIN/dhio. Ensure $LOCAL_BIN is in your PATH or restart your shell."

echo "Installation complete. Reload your shell or run 'source ~/.bashrc' (or ~/.zshrc) to use the 'dhio' command." 
