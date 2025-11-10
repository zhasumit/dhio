#!/usr/bin/env bash
# Simple installer for Dhio notes app.
# Usage: run this from the repo root: ./install.sh
# Or via curl (less recommended):
#   curl -sSL https://raw.githubusercontent.com/zhasumit/dhio/main/install.sh | bash

set -e

# Allow overriding tarball URL and expected sha256 via env or args:
# Usage: ./install.sh [--tarball-url URL] [--sha256 HEX] [uninstall]
TARBALL_URL="https://github.com/zhasumit/dhio/archive/refs/heads/main.tar.gz"
EXPECTED_SHA256=""
GPG_PUBKEY_URL=""
GPG_SIG_URL=""

while [ "$#" -gt 0 ]; do
  case "$1" in
    --tarball-url) TARBALL_URL="$2"; shift 2 ;;
    --sha256) EXPECTED_SHA256="$2"; shift 2 ;;
    --gpg-pubkey-url) GPG_PUBKEY_URL="$2"; shift 2 ;;
    --sig-url|--gpg-sig-url) GPG_SIG_URL="$2"; shift 2 ;;
    uninstall) break ;;
    *) break ;;
  esac
done

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
    tarball_path="$tmpdir/repo.tar.gz"
    if ! curl -sSL "$TARBALL_URL" -o "$tarball_path"; then
      echo "Failed to download repository archive from $TARBALL_URL" >&2
      rm -rf "$tmpdir"
      exit 1
    fi
    # Optional GPG verification (if both pubkey and sig URLs provided)
    if [ -n "$GPG_PUBKEY_URL" ] && [ -n "$GPG_SIG_URL" ]; then
      if ! command -v gpg >/dev/null 2>&1; then
        echo "GPG not found: cannot verify tarball signature. Install gnupg or omit GPG args." >&2
        rm -rf "$tmpdir"
        exit 1
      fi
      echo "Downloading GPG public key and signature..."
      pubkey_path="$tmpdir/pubkey.asc"
      sig_path="$tmpdir/sig.asc"
      if ! curl -sSL "$GPG_PUBKEY_URL" -o "$pubkey_path"; then
        echo "Failed to download GPG public key from $GPG_PUBKEY_URL" >&2
        rm -rf "$tmpdir"
        exit 1
      fi
      if ! curl -sSL "$GPG_SIG_URL" -o "$sig_path"; then
        echo "Failed to download signature from $GPG_SIG_URL" >&2
        rm -rf "$tmpdir"
        exit 1
      fi

      # Use a temporary GNUPGHOME so we don't pollute the user's keyring
      GNUPGHOME=$(mktemp -d)
      chmod 700 "$GNUPGHOME"
      export GNUPGHOME
      gpg --import "$pubkey_path" >/dev/null 2>&1 || { echo "Failed to import public key" >&2; rm -rf "$GNUPGHOME" "$tmpdir"; exit 1; }
      # Verify signature (detached) against tarball
      if ! gpg --verify "$sig_path" "$tarball_path" >/dev/null 2>&1; then
        echo "GPG signature verification failed" >&2
        rm -rf "$GNUPGHOME" "$tmpdir"
        exit 1
      fi
      echo "GPG signature verification OK"
      # cleanup GNUPGHOME (do not remove $tmpdir yet as we still need it)
      rm -rf "$GNUPGHOME"
      unset GNUPGHOME
    fi
    # If a sha256 was provided, verify it
    if [ -n "$EXPECTED_SHA256" ]; then
      echo "Verifying archive SHA256..."
      calc=$(sha256sum "$tmpdir/repo.tar.gz" | awk '{print $1}')
      if [ "$calc" != "$EXPECTED_SHA256" ]; then
        echo "SHA256 mismatch: expected $EXPECTED_SHA256 but got $calc" >&2
        rm -rf "$tmpdir"
        exit 1
      fi
      echo "SHA256 verified"
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
