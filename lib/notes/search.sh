#!/bin/bash
# Search functions for Dhio Notes App

# Source the tags module
source "$(dirname "$0")/tags.sh"

# Fuzzy search notes by content/title
search_notes_fuzzy() {
    local notes=("$@")
    local search_term=""
    local selected_index=0
    local term_width=$(tput cols)

    while true; do
        clear
        echo -e "${BOLD}${CYAN}═══════════════════════════════════════${RESET}"
        echo -e "${BOLD}${CYAN}     SEARCH NOTES${RESET}"
        echo -e "${BOLD}${CYAN}═══════════════════════════════════════${RESET}\n"
        echo -e "${BOLD}${CYAN}Search:${RESET} ${YELLOW}${search_term}${RESET}\n"

        # Build filtered list
        local filtered_notes=()
        local match_lines=()  # Store matching lines for preview
        local idx=0

        for note in "${notes[@]}"; do
            if [ -f "$note" ]; then
                local heading=$(head -n 1 "$note" | sed 's/^#* *//')
                local filename=$(basename "$note")

                # Use awk to check for matches in content
                local has_match=$(awk -v term="$search_term" -v fname="$filename" -v head="$heading" 'BEGIN{
                    IGNORECASE=1
                    if (term == "" || fname ~ term || head ~ term) {
                        print "1"
                        exit
                    }
                }
                {
                    if ($0 ~ term) {
                        print "1"
                        exit
                    }
                }' "$note" 2>/dev/null)

                if [ -n "$has_match" ] || [ -z "$search_term" ]; then
                    filtered_notes+=("$note")

                    # Get first matching line for preview
                    if [ -n "$search_term" ]; then
                        local match_line=$(awk -v term="$search_term" 'BEGIN{IGNORECASE=1}
                        {
                            if ($0 ~ term) {
                                gsub(term, "'"$RED"'&'"$RESET"'")
                                print
                                exit
                            }
                        }' "$note" 2>/dev/null || echo "")

                        if [ -n "$match_line" ]; then
                            match_lines+=("$match_line")
                        else
                            match_lines+=("")
                        fi
                    else
                        match_lines+=("")
                    fi
                fi
            fi
        done

        # Display results
        if [ ${#filtered_notes[@]} -eq 0 ]; then
            echo -e "${DIM}No matches found${RESET}\n"
        else
            (( selected_index >= ${#filtered_notes[@]} )) && selected_index=0

            for i in "${!filtered_notes[@]}"; do
                local note="${filtered_notes[$i]}"
                local filename=$(basename "$note")
                local heading=$(head -n 1 "$note" | sed 's/^#* *//')
                local date=$(date -r "$note" "+%Y-%m-%d %H:%M")
                local tags=$(extract_tags "$note")

                # Highlight search term in heading and filename using awk
                if [ -n "$search_term" ]; then
                    heading=$(echo "$heading" | awk -v term="$search_term" -v red="$RED" -v reset="$RESET" 'BEGIN{IGNORECASE=1}{
                        gsub(term, red term reset)
                        print
                    }')

                    filename=$(echo "$filename" | awk -v term="$search_term" -v red="$RED" -v reset="$RESET" 'BEGIN{IGNORECASE=1}{
                        gsub(term, red term reset)
                        print
                    }')
                fi

                if [ $i -eq $selected_index ]; then
                    echo -e "${BLUE}→${RESET}    ${YELLOW}[$((i+1))]${RESET} ${BOLD}${heading}${RESET} ${DIM}${date}${RESET} ${DIM}(${filename})${RESET}"
                    echo -e "    ${TAG_COLOR}↳ ${tags}${RESET}"

                    # Show matching line preview if available
                    if [ -n "${match_lines[$i]}" ]; then
                        echo -e "    ${DIM}┃${RESET} ${match_lines[$i]}\n"
                    else
                        echo ""
                    fi
                else
                    echo -e "     ${YELLOW}[$((i+1))]${RESET} ${BOLD}${heading}${RESET} ${DIM}${date}${RESET} ${DIM}(${filename})${RESET}"
                    echo -e "    ${TAG_COLOR}↳ ${tags}${RESET}"

                    if [ -n "${match_lines[$i]}" ]; then
                        echo -e "    ${DIM}┃${RESET} ${match_lines[$i]}\n"
                    else
                        echo ""
                    fi
                fi
            done
        fi

        draw_footer "search"
        key=$(get_key)

        case "$key" in
            esc) return ;;
            up)
                ((selected_index--))
                ((selected_index < 0)) && selected_index=$((${#filtered_notes[@]} - 1))
                ;;
            down)
                ((selected_index++))
                ((selected_index >= ${#filtered_notes[@]})) && selected_index=0
                ;;
            $'\x7f')  # Backspace
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
