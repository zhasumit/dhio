#!/bin/bash
# Formatting utilities for note display

# Format note line with justified date
# Usage: format_note_line_with_date heading date tags [selected] [current]
format_note_line_with_date() {
    local heading="$1"
    local date="$2"
    local tags="$3"
    local is_selected="${4:-false}"
    local is_current="${5:-false}"
    local term_width=$(tput cols)
    
    # Calculate available space
    local left_part=""
    if [ "$is_current" = "true" ]; then
        left_part="${BLUE}→${RESET}    ${YELLOW}[${6:-1}]${RESET} ${BOLD}${heading}${RESET}"
    else
        left_part="     ${YELLOW}[${6:-1}]${RESET} ${BOLD}${heading}${RESET}"
    fi
    
    # Remove ANSI codes for width calculation
    local left_plain=$(echo -e "$left_part" | sed 's/\x1b\[[0-9;]*m//g')
    local left_len=${#left_plain}
    local date_len=${#date}
    local padding=$((term_width - left_len - date_len))
    
    if [ $padding -gt 0 ]; then
        printf "%s%*s%s\n" "$left_part" $padding "" "${DIM}${date}${RESET}"
    else
        printf "%s %s\n" "$left_part" "${DIM}${date}${RESET}"
    fi
    
    # Tags with better spacing and icon
    if [ -n "$tags" ]; then
        echo -e "      ${TAG_COLOR}🏷️  ${tags}${RESET}"
    fi
}

