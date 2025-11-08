#!/bin/bash
# UI functions for Dhio Notes App
# Colors are loaded from theme system

# Draw footer menu
draw_footer() {
    local context="$1"
    local term_width=$(tput cols)
    echo -e "\n${PURPLE}$(printf '%*s' $term_width '' | tr ' ' '-')${RESET}"
    case "$context" in
        main)
            local items=("${PURPLE}[N]${RESET} New" "${PURPLE}[M]${RESET} Template" "${PURPLE}[A]${RESET} Archive" "${PURPLE}[T]${RESET} Tag" "${PURPLE}[D]${RESET} Delete" "${PURPLE}[R]${RESET} Restore" "${PURPLE}[/]${RESET} Search" "${PURPLE}[S]${RESET} Sort" "${PURPLE}[C]${RESET} Colors" "${PURPLE}[I]${RESET} Stats" "${PURPLE}[ESC]${RESET} Exit")
            ;;
        preview)
            local items=("${PURPLE}[E]${RESET} Edit" "${PURPLE}[A]${RESET} Archive" "${PURPLE}[D]${RESET} Delete" "${PURPLE}[X]${RESET} Export" "${PURPLE}[H]${RESET} History" "${PURPLE}[U]${RESET} Undo" "${PURPLE}[C1-9]${RESET} Copy" "${PURPLE}[ESC]${RESET} Back")
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
        restore)
            local items=("${PURPLE}[R]${RESET} Restore" "${PURPLE}[SPACE]${RESET} Select" "${PURPLE}[ESC]${RESET} Cancel")
            ;;
        notebin)
            local items=("${PURPLE}[SPACE]${RESET} Select" "${PURPLE}[↑↓]${RESET} Navigate" "${PURPLE}[ENTER]${RESET} Preview" "${PURPLE}[R]${RESET} Restore" "${PURPLE}[X/D]${RESET} Delete" "${PURPLE}[/]${RESET} Search" "${PURPLE}[ESC]${RESET} Back")
            ;;
        archive)
            local items=("${PURPLE}[SPACE]${RESET} Select" "${PURPLE}[↑↓]${RESET} Navigate" "${PURPLE}[ENTER]${RESET} Preview" "${PURPLE}[R]${RESET} Restore" "${PURPLE}[X/D]${RESET} Delete" "${PURPLE}[/]${RESET} Search" "${PURPLE}[ESC]${RESET} Back")
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
    echo -e "${PURPLE}$(printf '%*s' $term_width '' | tr ' ' '-')${RESET}"
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
        echo -e "$left_padding${TAG_COLOR}🏷️  ${tags}${RESET}"
    fi
}

# Center text in terminal
center_text() {
    local text="$1"
    local term_width=$(tput cols)
    local text_length=${#text}
    local padding=$(( (term_width - text_length) / 2 ))
    echo -e "$(printf '%*s' $padding '')${text}"
}

# Draw header with better styling
draw_header() {
    local title="$1"
    local icon="${2:-}"
    local term_width=$(tput cols)
    local box_width=$((term_width - 4))
    echo ""
    echo -e "${CYAN}┌$(printf '%*s' $box_width '' | tr ' ' '─')┐${RESET}"
    local title_with_icon="${icon} ${title}"
    local title_len=${#title_with_icon}
    local title_padding=$(( (box_width - title_len) / 2 ))
    echo -e "${CYAN}│${RESET}$(printf '%*s' $title_padding '')${BOLD}${YELLOW}${title_with_icon}${RESET}$(printf '%*s' $((box_width - title_len - title_padding)) '')${CYAN}│${RESET}"
    echo -e "${CYAN}└$(printf '%*s' $box_width '' | tr ' ' '─')┘${RESET}"
    echo ""
}
