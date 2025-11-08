#!/bin/bash
# AES-256 Encryption module for notes

# Check if openssl is available
check_encryption_support() {
    if ! command -v openssl &> /dev/null; then
        return 1
    fi
    return 0
}

# Encrypt a note file
# Usage: encrypt_note filepath [password]
encrypt_note() {
    local filepath="$1"
    local password="${2:-}"
    
    if [ ! -f "$filepath" ]; then
        send_notification "Notes App" "Note not found"
        return 1
    fi
    
    if ! check_encryption_support; then
        send_notification "Notes App" "OpenSSL not found. Encryption unavailable."
        return 1
    fi
    
    # If no password provided, prompt for it
    if [ -z "$password" ]; then
        echo -e "${YELLOW}Enter encryption password:${RESET}"
        read -rs password
        echo ""
        if [ -z "$password" ]; then
            send_notification "Notes App" "Encryption cancelled"
            return 1
        fi
        echo -e "${YELLOW}Confirm password:${RESET}"
        read -rs password_confirm
        echo ""
        if [ "$password" != "$password_confirm" ]; then
            send_notification "Notes App" "Passwords do not match"
            return 1
        fi
    fi
    
    local encrypted_file="${filepath}.enc"
    local temp_file="${filepath}.tmp"
    
    # Encrypt using AES-256
    if openssl enc -aes-256-cbc -salt -pbkdf2 -in "$filepath" -out "$temp_file" -pass "pass:$password" 2>/dev/null; then
        mv "$temp_file" "$encrypted_file"
        rm -f "$filepath"
        send_notification "Notes App" "Note encrypted successfully"
        return 0
    else
        rm -f "$temp_file"
        send_notification "Notes App" "Encryption failed"
        return 1
    fi
}

# Decrypt a note file
# Usage: decrypt_note encrypted_filepath [password] [output_path]
decrypt_note() {
    local encrypted_file="$1"
    local password="${2:-}"
    local output_path="${3:-${encrypted_file%.enc}}"
    
    if [ ! -f "$encrypted_file" ]; then
        send_notification "Notes App" "Encrypted note not found"
        return 1
    fi
    
    if ! check_encryption_support; then
        send_notification "Notes App" "OpenSSL not found. Decryption unavailable."
        return 1
    fi
    
    # If no password provided, prompt for it
    if [ -z "$password" ]; then
        echo -e "${YELLOW}Enter decryption password:${RESET}"
        read -rs password
        echo ""
        if [ -z "$password" ]; then
            send_notification "Notes App" "Decryption cancelled"
            return 1
        fi
    fi
    
    local temp_file="${encrypted_file}.tmp"
    
    # Decrypt using AES-256
    if openssl enc -aes-256-cbc -d -pbkdf2 -in "$encrypted_file" -out "$temp_file" -pass "pass:$password" 2>/dev/null; then
        mv "$temp_file" "$output_path"
        send_notification "Notes App" "Note decrypted successfully"
        return 0
    else
        rm -f "$temp_file"
        send_notification "Notes App" "Decryption failed. Wrong password?"
        return 1
    fi
}

# Check if a file is encrypted
is_encrypted() {
    local filepath="$1"
    [[ "$filepath" == *.enc ]]
}

# Auto-decrypt and display encrypted note
preview_encrypted_note() {
    local encrypted_file="$1"
    
    if ! is_encrypted "$encrypted_file"; then
        return 1
    fi
    
    local temp_decrypted="${NOTES_DIR}/.temp_decrypted_$$.md"
    
    if decrypt_note "$encrypted_file" "" "$temp_decrypted"; then
        preview_note "$temp_decrypted"
        rm -f "$temp_decrypted"
        return 0
    else
        return 1
    fi
}

