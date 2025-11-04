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

# Draw footer menu
draw_footer() {
    local context="$1"
    local term_width=$(tput cols)
    printf "\n${PURPLE}%${term_width}s${RESET}\n" | tr ' ' '-'
    case "$context" in
        main)
            local items=("${PURPLE}[N]${RESET} New" "${PURPLE}[A]${RESET} Archive" "${PURPLE}[D]${RESET} Delete" "${PURPLE}[R]${RESET} Restore" "${PURPLE}[/]${RESET} Search" "${PURPLE}[ESC]${RESET} Exit")
            ;;
        preview)
            local items=("${PURPLE}[E]${RESET} Edit" "${PURPLE}[A]${RESET} Archive" "${PURPLE}[D]${RESET} Delete" "${PURPLE}[C1-9]${RESET} Copy code" "${PURPLE}[ESC]${RESET} Back")
            ;;
        search)
            local items=("${PURPLE}Type${RESET} to filter" "${PURPLE}[↑↓]${RESET} Navigate" "${PURPLE}[ENTER]${RESET} Open" "${PURPLE}[ESC]${RESET} Cancel")
            ;;
        delete)
            local items=("${PURPLE}[Y]${RESET} Yes" "${PURPLE}[N]${RESET} No" "${PURPLE}[ESC]${RESET} Cancel")
            ;;
        notebin)
            local items=("${PURPLE}[SPACE]${RESET} Select" "${PURPLE}[↑↓]${RESET} Navigate" "${PURPLE}[R]${RESET} Restore" "${PURPLE}[D]${RESET} Delete" "${PURPLE}[X]${RESET} Purge" "${PURPLE}[ESC]${RESET} Back")
            ;;
        archive)
            local items=("${PURPLE}[SPACE]${RESET} Select" "${PURPLE}[↑↓]${RESET} Navigate" "${PURPLE}[R]${RESET} Restore" "${PURPLE}[D]${RESET} Delete" "${PURPLE}[X]${RESET} Purge" "${PURPLE}[ESC]${RESET} Back")
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

# Format note line with justified layout
format_note_line() {
    local num="$1"
    local heading="$2"
    local date="$3"
    local selected="$4"
    local term_width=$(tput cols)
    local num_part="${YELLOW}[$num]${RESET} ${BOLD}"
    local date_part="${RESET}${DIM}$date${RESET}"
    local select_indicator=""
    if [ "$selected" = "true" ]; then
        select_indicator="${GREEN}[✓]${RESET} "
    else
        select_indicator="${GRAY}[ ]${RESET} "
    fi
    local num_len=$((${#num} + 3))
    local date_len=${#date}
    local select_len=4
    local available_width=$((term_width - num_len - date_len - select_len - 3))
    local display_heading="$heading"
    if [ ${#heading} -gt $available_width ]; then
        display_heading="${heading:0:$((available_width - 3))}..."
    fi
    local padding_len=$((term_width - num_len - select_len - ${#display_heading} - date_len - 3))
    local padding=$(printf '%*s' "$padding_len" '')
    echo -e "${select_indicator}${YELLOW}[$num]${RESET} ${BOLD}${display_heading}${RESET}${padding}${DIM}$date${RESET}"
}

# Center text in terminal
center_text() {
    local text="$1"
    local term_width=$(tput cols)
    local text_length=${#text}
    local padding=$(( (term_width - text_length) / 2 ))
    printf "%${padding}s%s\n" "" "$text"
}
