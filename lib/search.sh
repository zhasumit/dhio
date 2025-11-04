#!/bin/bash
# Search functionality

# Fuzzy search notes
search_notes_fuzzy() {
    local notes=("$@")
    local search_term=""
    local selected_index=0
    while true; do
        clear
        echo -e "${BOLD}${CYAN}═══════════════════════════════════════${RESET}"
        echo -e "${BOLD}${CYAN}     FUZZY SEARCH${RESET}"
        echo -e "${BOLD}${CYAN}═══════════════════════════════════════${RESET}\n"
        echo -e "${BOLD}${CYAN}Search:${RESET} ${YELLOW}${search_term}${RESET}\n"
        local filtered_notes=()
        for n in "${notes[@]}"; do
            if [ -f "$n" ]; then
                if [ -z "$search_term" ]; then
                    filtered_notes+=("$n")
                else
                    if grep -iq -- "$search_term" "$n" 2>/dev/null; then
                        filtered_notes+=("$n")
                    fi
                fi
            fi
        done
        if [ ${#filtered_notes[@]} -eq 0 ]; then
            echo -e "${DIM}No matches${RESET}\n"
        else
            (( selected_index >= ${#filtered_notes[@]} )) && selected_index=0
            local idx=0
            for note in "${filtered_notes[@]}"; do
                local title
                title=$(head -n 1 "$note" | sed 's/^#* *//')
                if [ $idx -eq $selected_index ]; then
                    echo -e "${BLUE}[x]${RESET} ${BOLD}$title${RESET}"
                else
                    echo -e "${BLUE}[ ]${RESET} ${BOLD}$title${RESET}"
                fi
                local match_line=""
                if [ -n "$search_term" ]; then
                    match_line=$(grep -i -m 1 -- "$search_term" "$note" 2>/dev/null || true)
                fi
                if [ -n "$match_line" ]; then
                    match_line="${match_line#"${match_line%%[![:space:]]*}"}"
                    local term_width
                    term_width=$(tput cols)
                    local preview="${match_line:0:$((term_width-6))}"
                    preview=$(echo "$preview" | awk -v term="$search_term" -v red="$RED" -v reset="$RESET" '
                        BEGIN { IGNORECASE=1 }
                        {
                            if (term == "") { print; next }
                            gsub(term, red "&" reset)
                            print
                        }' )
                    echo -e "   ${DIM}+${RESET} ${preview}\n"
                else
                    echo ""
                fi
                ((idx++))
            done
        fi
        draw_footer "search"
        key=$(get_key)
        case "$key" in
            esc) return ;;
            up) ((selected_index--)); ((selected_index < 0)) && selected_index=$((${#filtered_notes[@]} - 1)) ;;
            down) ((selected_index++)); ((selected_index >= ${#filtered_notes[@]})) && selected_index=0 ;;
            $'\x7f')
                if [ -n "$search_term" ]; then
                    search_term="${search_term:0:-1}"
                    selected_index=0
                fi
                ;;
            "")
                if [ ${#filtered_notes[@]} -gt 0 ]; then
                    preview_note "${filtered_notes[$selected_index]}"
                    return
                fi
                ;;
            *)
                if [[ "$key" =~ [[:print:]] ]]; then
                    search_term+="$key"
                    selected_index=0
                fi
                ;;
        esac
    done
}
