#!/bin/bash
# Common utility functions for Dhio Notes App
#
# Purpose:
# - Provide small shared helpers used across the app (I/O helpers, key reading, highlighting,
#   simple text sanitizers, and convenience functions used by scripts and the UI).
#
# Public functions (examples):
# - init_notes_dir: create notes directories used by the app
# - get_key: read a single key from the terminal (arrow keys, esc detection)
# - copy_code_block: copy small text to clipboard (xclip/xsel/pbcopy fallback)
# - highlight_search_term: highlight occurrences of a search term in a string using awk
# - strip_ansi / strip_cr: small filters to remove ANSI sequences or stray CR characters
# - show_line <file> <linenumber> [context]: print a specific line with optional nearby context


# Initialize notes directory
init_notes_dir() {
    mkdir -p "$NOTES_DIR"
    mkdir -p "$NOTEBIN_DIR"
    mkdir -p "$ARCHIVE_DIR"
    mkdir -p "$HISTORY_DIR"
    mkdir -p "$TEMPLATES_DIR"
    mkdir -p "$EXPORT_DIR"
}

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
        if [[ $key2 == "[A" ]]; then echo "up";
        elif [[ $key2 == "[B" ]]; then echo "down";
        elif [[ $key2 == "[C" ]]; then echo "right";
        elif [[ $key2 == "[D" ]]; then echo "left";
        else echo "esc"; fi
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

# Highlight search term in text (centralized highlighting function)
highlight_search_term() {
    local text="$1"
    local term="$2"
    if [ -z "$term" ] || [ -z "$text" ]; then
        echo -n "$text"
        return
    fi
    # Use awk for case-insensitive highlighting
    echo -n "$text" | awk -v term="$term" -v red="$RED" -v reset="$RESET" 'BEGIN{IGNORECASE=1}{
        gsub(term, red term reset)
        print
    }'
}

# Strip ANSI sequences from input (returns plain text). Uses awk to remove common CSI sequences.
strip_ansi() {
    # Read from stdin
    awk '{ gsub(/\x1b\[[0-9;]*[A-Za-z]/, ""); print }'
}

# Remove stray carriage returns and control characters except ANSI ESC sequences that start CSI
strip_cr() {
    awk '{ gsub(/\r/, ""); print }'
}

# Show a specific line (with its line number) from a file.
# Usage: show_line <file> <linenumber> [context]
show_line() {
    local file="$1"
    local lineno="$2"
    local context="${3:-0}"
    [ -z "$file" ] && return 1
    [ ! -f "$file" ] && return 2
    if ! [[ "$lineno" =~ ^[0-9]+$ ]]; then
        echo "Invalid line number"
        return 3
    fi

    local start=$(( lineno - context ))
    [ $start -lt 1 ] && start=1
    local end=$(( lineno + context ))

    awk -v s=$start -v e=$end 'NR>=s && NR<=e { printf "%6d | %s\n", NR, $0 }' "$file" | strip_cr
}

# Compute a right-aligned date part for a heading line.
# Usage: compute_date_part "<heading_part_with_ansi>" "<date_string>" [show_checkbox]
# Prints the properly padded date (or a dimmed close date if not enough space).
compute_date_part() {
    local heading_part="$1"
    local date="$2"
    local show_checkbox="${3:-true}"
    local term_width=$(tput cols)

    # Remove ANSI sequences to measure visible length
    local heading_plain=$(echo -e "$heading_part" | sed 's/\x1b\[[0-9;]*m//g')
    local heading_len=${#heading_plain}

    local checkbox_space=4
    if [ "$show_checkbox" = "false" ]; then
        checkbox_space=2
    fi
    local reserved_space=$((checkbox_space + 3))

    local date_padding=$((term_width - heading_len - ${#date} - reserved_space))
    if [ $date_padding -gt 0 ]; then
        printf "%*s%s" $date_padding "" "$date"
    else
        # Not enough room; show compact dimmed date
        printf "  %s%s%s" "$DIM" "$date" "$RESET"
    fi
}

