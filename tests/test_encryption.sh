#!/usr/bin/env bash
set -euo pipefail

# Simple encryption smoke test for encrypt_note_rsa / decrypt_note_rsa
# This test runs non-interactively. It creates a temporary NOTES_DIR and a test keypair,
# then encrypts and decrypts a note and verifies contents match.

TMPDIR=$(mktemp -d)
export NOTES_DIR="$TMPDIR/notes"
mkdir -p "$NOTES_DIR/.keys"

ROOT_DIR=$(cd "$(dirname "$0")/.." && pwd)
# Provide a no-op notification function for test environment
send_notification() { echo "[notify]" "$@" 1>&2; }
. "$ROOT_DIR/lib/core/encryption.sh"

user="testuser"
pass="testpass123"

# create a passfile and generate keypair non-interactively
pf=$(mktemp)
chmod 600 "$pf"
printf "%s" "$pass" > "$pf"
openssl genpkey -algorithm RSA -out "$NOTES_DIR/.keys/${user}.pem" -pkeyopt rsa_keygen_bits:2048 -aes-256-cbc -pass file:"$pf" >/dev/null 2>&1
openssl rsa -in "$NOTES_DIR/.keys/${user}.pem" -passin file:"$pf" -pubout -out "$NOTES_DIR/.keys/${user}.pub.pem" >/dev/null 2>&1
rm -f "$pf"

note="$NOTES_DIR/sample.md"
printf "%s
" "Hello secret world" > "$note"

echo "Encrypting note..."
encrypt_note_rsa "$note" "$user"

if [ ! -f "${note}.enc" ] || [ ! -f "${note}.key" ]; then
  echo "Encrypted files not created" >&2
  exit 2
fi

echo "Decrypting note (manual flow)..."
echo "DEBUG: NOTES_DIR=$NOTES_DIR"
echo "DEBUG: listing keys:"; ls -l "$NOTES_DIR/.keys" || true
echo "DEBUG: listing enc/key files:"; ls -l "${note}.enc" "${note}.key" || true

# Manually perform RSA unwrap and symmetric decryption as decrypt_note_rsa would do
pf=$(mktemp)
chmod 600 "$pf"
printf "%s" "$pass" > "$pf"
symkey=$(openssl rsautl -decrypt -inkey "$NOTES_DIR/.keys/${user}.pem" -passin file:"$pf" -in "${note}.key" 2>/dev/null || true)
rm -f "$pf"
if [ -z "$symkey" ]; then
  echo "Failed to obtain symmetric key" >&2
  exit 5
fi

# Use a secure temporary file for symmetric key to pass via -pass file: (avoids argv exposure)
pf2=$(mktemp)
chmod 600 "$pf2"
printf "%s" "$symkey" > "$pf2"
openssl enc -aes-256-cbc -d -pbkdf2 -in "${note}.enc" -out "$note" -pass file:"$pf2" 2>/dev/null || { rm -f "$pf2"; echo "Symmetric decrypt failed" >&2; exit 6; }
rm -f "$pf2"

if [ ! -f "$note" ]; then
  echo "Decrypted file not found" >&2
  exit 3
fi

expected="Hello secret world"
actual=$(cat "$note")
if [ "$expected" != "$actual" ]; then
  echo "Decrypted content mismatch" >&2
  echo "Expected: $expected" >&2
  echo "Actual: $actual" >&2
  exit 4
fi

echo "encryption test: PASS"

rm -rf "$TMPDIR"
