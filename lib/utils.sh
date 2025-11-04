#!/bin/bash
# Utility functions

# Send notification
send_notification() {
    local title="$1"
    local message="$2"
    if command -v notify-send &> /dev/null; then
        notify-send "$title" "$message"
    fi
}

# Get single key press
get_key() {
    local key
    IFS= read -rsn1 key 2>/dev/null
    if [[ $key == $'\x1b' ]]; then
        read -rsn2 -t 0.1 key2
        if [[ $key2 == "[A" ]]; then echo "up"
        elif [[ $key2 == "[B" ]]; then echo "down"
        elif [[ $key2 == "[C" ]]; then echo "right"
        elif [[ $key2 == "[D" ]]; then echo "left"
        else echo "esc"
        fi
    else
        echo "$key"
    fi
}

# Copy code block to clipboard
copy_code_block() {
    local code_content="$1"
    if command -v xclip &> /dev/null; then
        echo -n "$code_content" | xclip -selection clipboard
        return 0
    elif command -v xsel &> /dev/null; then
        echo -n "$code_content" | xsel --clipboard
        return 0
    elif command -v pbcopy &> /dev/null; then
        echo -n "$code_content" | pbcopy
        return 0
    elif command -v clip.exe &> /dev/null; then
        echo -n "$code_content" | clip.exe
        return 0
    else
        echo "$code_content" > "$CODE_TEMP"
        return 1
    fi
}

# Initialize notes directory
init_notes_dir() {
    mkdir -p "$NOTES_DIR"
    mkdir -p "$NOTEBIN_DIR"
}
