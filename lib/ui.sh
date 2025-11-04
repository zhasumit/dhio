#!/bin/bash
# UI functions for Dhio Notes App

# Colors - Tokyo Night theme
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
BOLD='\033[1m'
DIM='\033[2m'
STRIKETHROUGH='\033[9m'
PURPLE='\033[38;5;141m'
DARK_PURPLE='\033[38;5;98m'
GRAY='\033[38;5;240m'
RESET='\033[0m'
# Tag styling
TAG_COLOR='\033[38;5;208m'  # Orange
TAG_BG='\033[48;5;238m'    # Light gray background

# Draw footer menu
draw_footer() {
    local context="$1"
    local term_width=$(tput cols)
    printf "\n${PURPLE}%${term_width}s${RESET}\n" | tr ' ' '-'
    case "$context" in
        main)
            local items=("${PURPLE}[N]${RESET} New" "${PURPLE}[A]${RESET} Archive" "${PURPLE}[T]${RESET} Filter by Tag" "${PURPLE}[D]${RESET} Delete" "${PURPLE}[R]${RESET} Restore" "${PURPLE}[/]${RESET} Search" "${PURPLE}[ESC]${RESET} Exit")
            ;;
        preview)
            local items=("${PURPLE}[E]${RESET} Edit" "${PURPLE}[A]${RESET} Archive" "${PURPLE}[D]${RESET} Delete" "${PURPLE}[C1-9]${RESET} Copy code" "${PURPLE}[ESC]${RESET} Back")
            ;;
        search)
            local items=("${PURPLE}Type${RESET} to search" "${PURPLE}[↑↓]${RESET} Navigate" "${PURPLE}[ENTER]${RESET} Open" "${PURPLE}[ESC]${RESET} Cancel")
            ;;
        tagsearch)
            local items=("${PURPLE}Type${RESET} to filter by tag" "${PURPLE}[↑↓]${RESET} Navigate" "${PURPLE}[ENTER]${RESET} Open" "${PURPLE}[ESC]${RESET} Cancel")
            ;;
        delete)
            local items=("${PURPLE}[Y]${RESET} Yes" "${PURPLE}[N]${RESET} No" "${PURPLE}[ESC]${RESET} Cancel")
            ;;
        notebin)
            local items=("${PURPLE}[SPACE]${RESET} Select" "${PURPLE}[↑↓]${RESET} Navigate" "${PURPLE}[R]${RESET} Restore" "${PURPLE}[D]${RESET} Delete" "${PURPLE}[X]${RESET} Purge" "${PURPLE}[/]${RESET} Search" "${PURPLE}[ESC]${RESET} Back")
            ;;
        archive)
            local items=("${PURPLE}[SPACE]${RESET} Select" "${PURPLE}[↑↓]${RESET} Navigate" "${PURPLE}[R]${RESET} Restore" "${PURPLE}[D]${RESET} Delete" "${PURPLE}[X]${RESET} Purge" "${PURPLE}[/]${RESET} Search" "${PURPLE}[ESC]${RESET} Back")
            ;;
    esac
    local num_items=${#items[@]}
    local item_lengths=0
    for item in "${items[@]}"; do
        local plain=$(echo -e "$item" | sed 's/\x1b\[[0-9;]*m//g')
        item_lengths=$((item_lengths + ${#plain}))
    done
    local total_spacing=$((term_width - item_lengths))
    local spacing=$((total_spacing / (num_items + 1)))
    printf "%${spacing}s" ""
    for i in "${!items[@]}"; do
        printf "%b" "${items[$i]}"
        if [ $i -lt $((num_items - 1)) ]; then
            printf "%${spacing}s" ""
        fi
    done
    echo ""
    printf "${PURPLE}%${term_width}s${RESET}\n" | tr ' ' '-'
}

# Format note line with improved layout
format_note_line() {
    local num="$1"
    local heading="$2"
    local date="$3"
    local selected="$4"
    local tags="$5"
    local term_width=$(tput cols)
    local left_padding="    "  # 4 spaces on the left
    local num_part="${left_padding}${YELLOW}[$num]${RESET} ${BOLD}${heading}${RESET}"
    local date_part="${DIM}$date${RESET}"
    local select_indicator=""
    if [ "$selected" = "true" ]; then
        select_indicator="${GREEN}[✓]${RESET} "
    else
        select_indicator="${GRAY}[ ]${RESET} "
    fi
    # Print note line
    printf "%s%s\n" "${select_indicator}${num_part}" "${date_part}"
    # Print tags on new line with indentation
    if [ -n "$tags" ]; then
        printf "%s${TAG_COLOR}↳ %s${RESET}\n" "$left_padding" "$tags"
    fi
}

# Center text in terminal
center_text() {
    local text="$1"
    local term_width=$(tput cols)
    local text_length=${#text}
    local padding=$(( (term_width - text_length) / 2 ))
    printf "%${padding}s%s\n" "" "$text"
}
