#!/bin/bash
# Encryption module for notes
#
# Responsibilities:
# - Provide symmetric AES-256 encrypt/decrypt helpers (`encrypt_note`, `decrypt_note`) for
#   quick passphrase-based encryption.
# - Provide an RSA-wrapped symmetric encryption workflow (`encrypt_note_rsa`, `decrypt_note_rsa`):
#   - Uses per-local-user RSA keypairs stored under `$NOTES_DIR/.keys/`.
#   - The private key is protected by an AES passphrase.
#   - Files encrypted with the RSA flow create two files: `<note>.enc` (content) and `<note>.enc.key` (RSA-wrapped symmetric key).
# - Provide `ensure_default_user_key` to help users bootstrap a simple RSA keypair on first interactive run.
#
# Security notes for contributors:
# - Private keys are stored encrypted with user-provided passphrases; treat `$NOTES_DIR/.keys/` as sensitive.
# - Current implementation occasionally passes passphrases via OpenSSL command options for usability; avoid exposing secrets in process listings in higher-security setups.


# Check if openssl is available
check_encryption_support() {
    if ! command -v openssl &> /dev/null; then
        return 1
    fi
    return 0
}

# key directory
KEY_DIR="$NOTES_DIR/.keys"

# Ensure key directory exists
ensure_key_dir() {
    mkdir -p "$KEY_DIR"
    chmod 700 "$KEY_DIR" 2>/dev/null || true
}

# Create a secure temporary file containing a passphrase.
# The file is created with mode 600 and the path is echoed. Caller MUST remove the file when done.
secure_tmp_passfile() {
    local pass="$1"
    local pf
    pf=$(mktemp) || return 1
    umask 077
    printf "%s" "$pass" > "$pf"
    chmod 600 "$pf" 2>/dev/null || true
    echo "$pf"
}

# Return private/public key path for username
key_paths() {
    local user="$1"
    echo "$KEY_DIR/${user}.pem" "$KEY_DIR/${user}.pub.pem"
}

# Ensure RSA keypair exists for a username; if not, prompt to create it.
# Usage: ensure_keypair <username>
ensure_keypair() {
    local user="$1"
    ensure_key_dir
    local priv="$KEY_DIR/${user}.pem"
    local pub="$KEY_DIR/${user}.pub.pem"

    if [ -f "$priv" ] && [ -f "$pub" ]; then
        return 0
    fi

    echo -e "${YELLOW}No RSA keypair found for user '$user'. Create now? [y/N]${RESET}"
    read -r create
    if [[ ! "$create" =~ ^[Yy] ]]; then
        return 1
    fi

    # prompt passphrase
    while true; do
        echo -e "${YELLOW}Enter passphrase to protect private key:${RESET}"
        read -rs pass
        echo ""
        if [ -z "$pass" ]; then
            echo -e "${RED}Passphrase cannot be empty${RESET}"
            continue
        fi
        echo -e "${YELLOW}Confirm passphrase:${RESET}"
        read -rs pass2
        echo ""
        if [ "$pass" != "$pass2" ]; then
            echo -e "${RED}Passphrases do not match${RESET}"
            continue
        fi
        break
    done

    # Generate RSA private key encrypted with passphrase
    # Use a temporary passfile to avoid exposing passphrases in process argv.
    local pf
    pf=$(secure_tmp_passfile "$pass") || { echo -e "${RED}Failed to create secure temp file${RESET}"; return 1; }
    if ! openssl genpkey -algorithm RSA -out "$priv" -pkeyopt rsa_keygen_bits:2048 -aes-256-cbc -pass file:"$pf" 2>/dev/null; then
        echo -e "${RED}Failed to generate RSA keypair${RESET}"
        rm -f "$pf"
        return 1
    fi

    # Extract public key
    if ! openssl rsa -in "$priv" -passin file:"$pf" -pubout -out "$pub" 2>/dev/null; then
        echo -e "${RED}Failed to extract public key${RESET}"
        rm -f "$priv"
        rm -f "$pf"
        return 1
    fi
    rm -f "$pf"

    chmod 600 "$priv" 2>/dev/null || true
    chmod 644 "$pub" 2>/dev/null || true
    echo -e "${GREEN}Keypair created: $priv and $pub${RESET}"
    return 0
}

# Encrypt a note using RSA-wrapped symmetric key
# Usage: encrypt_note_rsa <filepath> <username>
encrypt_note_rsa() {
    local filepath="$1"
    local user="$2"

    if [ ! -f "$filepath" ]; then
        send_notification "Notes App" "Note not found"
        return 1
    fi
    if ! check_encryption_support; then
        send_notification "Notes App" "OpenSSL not found. Encryption unavailable."
        return 1
    fi
    if [ -z "$user" ]; then
        echo -e "${YELLOW}Enter local username for keypair:${RESET}"
        read -r user
    fi
    if [ -z "$user" ]; then
        send_notification "Notes App" "No username provided"
        return 1
    fi

    ensure_key_dir
    local priv="$KEY_DIR/${user}.pem"
    local pub="$KEY_DIR/${user}.pub.pem"
    if [ ! -f "$pub" ]; then
        if ! ensure_keypair "$user"; then
            send_notification "Notes App" "Keypair creation cancelled"
            return 1
        fi
    fi

    # Generate a random symmetric key
    local symkey
    symkey=$(openssl rand -hex 32)

    local enc_file="${filepath}.enc"
    local key_file="${filepath}.key"

    # Encrypt file symmetrically with generated key.
    # Use -pass stdin and pipe the symmetric key on stdin to avoid exposing it in process args.
    if ! printf "%s" "$symkey" | openssl enc -aes-256-cbc -salt -pbkdf2 -in "$filepath" -out "$enc_file" -pass stdin 2>/dev/null; then
        send_notification "Notes App" "Encryption failed: symmetric step"
        return 1
    fi

    # Encrypt the symmetric key with recipient public key
    if ! echo -n "$symkey" | openssl rsautl -encrypt -pubin -inkey "$pub" -out "$key_file" 2>/dev/null; then
        rm -f "$enc_file"
        send_notification "Notes App" "Encryption failed: RSA step"
        return 1
    fi

    rm -f "$filepath"
    send_notification "Notes App" "Note encrypted (RSA) successfully"
    return 0
}

# Decrypt note encrypted with encrypt_note_rsa
# Usage: decrypt_note_rsa <enc_filepath> <username>
decrypt_note_rsa() {
    local enc_file="$1"
    local user="$2"
    local out_path="${enc_file%.enc}"
    local provided_pass="$3"

    if [ ! -f "$enc_file" ]; then
        send_notification "Notes App" "Encrypted note not found"
        return 1
    fi
    if ! check_encryption_support; then
        send_notification "Notes App" "OpenSSL not found. Decryption unavailable."
        return 1
    fi

    if [ -z "$user" ]; then
        echo -e "${YELLOW}Enter local username for keypair:${RESET}"
        read -r user
    fi
    if [ -z "$user" ]; then
        send_notification "Notes App" "No username provided"
        return 1
    fi

    ensure_key_dir
    local priv="$KEY_DIR/${user}.pem"
    local key_file="${enc_file}.key"

    if [ ! -f "$priv" ] || [ ! -f "$key_file" ]; then
        send_notification "Notes App" "Private key or symmetric key file not found"
        return 1
    fi

    # Determine passphrase (optional third arg for non-interactive use)
    local pass="${provided_pass:-}"
    if [ -z "$pass" ]; then
        echo -e "${YELLOW}Enter passphrase for private key:${RESET}"
        read -rs pass
        echo ""
    fi
    if [ -z "$pass" ]; then
        send_notification "Notes App" "Decryption cancelled"
        return 1
    fi

    # Use a temporary passfile to avoid exposing the passphrase in process listings
    local pf
    pf=$(secure_tmp_passfile "$pass") || { send_notification "Notes App" "Failed to create secure passfile"; return 1; }

    # Decrypt symmetric key using private key and passfile
    local symkey
    if ! symkey=$(openssl rsautl -decrypt -inkey "$priv" -passin file:"$pf" -in "$key_file" 2>/dev/null); then
        rm -f "$pf"
        send_notification "Notes App" "Failed to decrypt symmetric key (wrong passphrase?)"
        return 1
    fi
    rm -f "$pf"

    local temp_out="${enc_file}.dec.tmp"
    # Decrypt data using symmetric key provided on stdin to avoid exposure
    if ! printf "%s" "$symkey" | openssl enc -aes-256-cbc -d -pbkdf2 -in "$enc_file" -out "$temp_out" -pass stdin 2>/dev/null; then
        rm -f "$temp_out"
        send_notification "Notes App" "Failed to decrypt data (wrong key?)"
        return 1
    fi

    mv "$temp_out" "$out_path"
    send_notification "Notes App" "Note decrypted successfully"
    return 0
}

# Check if a file is encrypted (supports .enc symmetric or .enc + .key RSA)
is_encrypted() {
    local filepath="$1"
    [[ "$filepath" == *.enc ]]
}

# Auto-decrypt and display encrypted note. Prefer RSA companion key if present.
preview_encrypted_note() {
    local encrypted_file="$1"

    if ! is_encrypted "$encrypted_file"; then
        return 1
    fi

    local temp_decrypted="${NOTES_DIR}/.temp_decrypted_$$.md"

    # If companion .key exists, try RSA flow
    if [ -f "${encrypted_file}.key" ]; then
        # Prompt for username to locate private key
        echo -e "${YELLOW}Encrypted with RSA key. Enter local username to decrypt:${RESET}"
        read -r user
        if decrypt_note_rsa "$encrypted_file" "$user"; then
            mv "${encrypted_file%.enc}" "$temp_decrypted" 2>/dev/null || true
            # If decrypt_note_rsa placed file at ${encrypted_file%.enc}, use that
            if [ -f "${encrypted_file%.enc}" ]; then
                preview_note "${encrypted_file%.enc}"
                rm -f "${encrypted_file%.enc}"
            elif [ -f "$temp_decrypted" ]; then
                preview_note "$temp_decrypted"
                rm -f "$temp_decrypted"
            fi
            return 0
        else
            return 1
        fi
    else
        # Fall back to symmetric decryption
        if decrypt_note "$encrypted_file" "" "$temp_decrypted"; then
            preview_note "$temp_decrypted"
            rm -f "$temp_decrypted"
            return 0
        else
            return 1
        fi
    fi
}

# Ensure a default user key exists; if no keys present, prompt user to create a simple username/passphrase
# This is run at app startup to make encryption setup easy (non-hard). It will not overwrite existing keys.
ensure_default_user_key() {
    ensure_key_dir
    # check for any existing .pem files
    shopt -s nullglob 2>/dev/null
    local existing=($KEY_DIR/*.pem)
    shopt -u nullglob 2>/dev/null
    if [ ${#existing[@]} -gt 0 ]; then
        return 0
    fi

    # no keys found — prompt user briefly
    # If running non-interactively, skip
    if [ ! -t 0 ]; then
        return 1
    fi
    local default_user="${USER:-$(whoami)}"
    echo -e "${YELLOW}No encryption keypair found. Create a simple local account for note encryption? [Y/n]${RESET}"
    read -r ans
    if [[ "$ans" =~ ^[Nn] ]]; then
        return 1
    fi

    echo -e "${YELLOW}Choose a username for encryption [${default_user}]:${RESET}"
    read -r uname
    uname=${uname:-$default_user}

    # simple passphrase prompt (do not overcomplicate)
    while true; do
        echo -e "${YELLOW}Enter a passphrase to protect your private key (will be asked to decrypt notes):${RESET}"
        read -rs passwd
        echo ""
        if [ -z "$passwd" ]; then
            echo -e "${RED}Passphrase cannot be empty; try again or Ctrl+C to cancel.${RESET}"
            continue
        fi
        echo -e "${YELLOW}Confirm passphrase:${RESET}"
        read -rs passwd2
        echo ""
        if [ "$passwd" != "$passwd2" ]; then
            echo -e "${RED}Passphrases do not match; try again.${RESET}"
            continue
        fi
        break
    done

    # create keypair non-interactively using provided passphrase
    # create keypair non-interactively using provided passphrase
    # Use secure temporary passfile helper to avoid exposing passphrase on argv
    pf2=$(secure_tmp_passfile "$passwd") || { echo -e "${RED}Failed to create secure passfile${RESET}"; return 1; }
    if openssl genpkey -algorithm RSA -out "$KEY_DIR/${uname}.pem" -pkeyopt rsa_keygen_bits:2048 -aes-256-cbc -pass file:"$pf2" 2>/dev/null && \
       openssl rsa -in "$KEY_DIR/${uname}.pem" -passin file:"$pf2" -pubout -out "$KEY_DIR/${uname}.pub.pem" 2>/dev/null; then
        chmod 600 "$KEY_DIR/${uname}.pem" 2>/dev/null || true
        chmod 644 "$KEY_DIR/${uname}.pub.pem" 2>/dev/null || true
        rm -f "$pf2"
        echo -e "${GREEN}Encryption keypair created for user '$uname'.${RESET}"
        return 0
    else
        rm -f "$pf2"
        echo -e "${RED}Failed to create keypair.${RESET}"
        rm -f "$KEY_DIR/${uname}.pem" "$KEY_DIR/${uname}.pub.pem" 2>/dev/null || true
        return 1
    fi
}


# Create an RSA keypair non-interactively (utility function)
# Usage: create_keypair_noninteractive <username> <passphrase>
create_keypair_noninteractive() {
    local uname="$1"
    local passwd="$2"
    if [ -z "$uname" ] || [ -z "$passwd" ]; then
        return 1
    fi
    ensure_key_dir
    local priv="$KEY_DIR/${uname}.pem"
    local pub="$KEY_DIR/${uname}.pub.pem"
    if [ -f "$priv" ] || [ -f "$pub" ]; then
        return 1
    fi
    local pf
    pf=$(secure_tmp_passfile "$passwd") || return 1
    if ! openssl genpkey -algorithm RSA -out "$priv" -pkeyopt rsa_keygen_bits:2048 -aes-256-cbc -pass file:"$pf" 2>/dev/null; then
        rm -f "$pf"
        return 1
    fi
    if ! openssl rsa -in "$priv" -passin file:"$pf" -pubout -out "$pub" 2>/dev/null; then
        rm -f "$pf"
        rm -f "$priv"
        return 1
    fi
    chmod 600 "$priv" 2>/dev/null || true
    chmod 644 "$pub" 2>/dev/null || true
    rm -f "$pf"
    return 0
}

