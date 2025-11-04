#!/bin/bash
# Tag extraction and handling functions

# Extract tags from a note using awk (returns space-separated string)
extract_tags() {
    local note_path="$1"
    awk '/@[a-zA-Z0-9_-]+/ {
        for (i=1; i<=NF; i++) {
            if ($i ~ /^@[a-zA-Z0-9_-]+$/) {
                tags[$i] = 1
            }
        }
    }
    END {
        for (tag in tags) {
            printf "%s ", tag
        }
    }' "$note_path" | sed 's/ $//'
}

# Tag search (fuzzy finder style with awk)
tag_search() {
    local search_term=""
    local selected_index=0
    local term_width=$(tput cols)

    while true; do
        clear
        echo -e "${BOLD}${CYAN}═══════════════════════════════════════${RESET}"
        echo -e "${BOLD}${CYAN}     FILTER BY TAG${RESET}"
        echo -e "${BOLD}${CYAN}═══════════════════════════════════════${RESET}\n"
        echo -e "${BOLD}${CYAN}Search:${RESET} ${YELLOW}${search_term}${RESET}\n"

        # Build filtered list
        local filtered_notes=()
        local match_lines=()

        for note in "$NOTES_DIR"/*.md; do
            if [ -f "$note" ] && ! [[ "$note" =~ /archive/ ]] && ! [[ "$note" =~ /notebin/ ]]; then
                local filename=$(basename "$note")
                local heading=$(head -n 1 "$note" | sed 's/^#* *//')
                local note_tags=$(extract_tags "$note")

                # Case-insensitive check using awk
                local has_match=$(awk -v term="@$search_term" -v fname="$filename" -v head="$heading" -v tags="$note_tags" 'BEGIN{
                    IGNORECASE=1
                    if (term == "" || fname ~ term || head ~ term || tags ~ term) print "1"
                }')

                if [ -z "$search_term" ] || [ -n "$has_match" ]; then
                    filtered_notes+=("$note")
                fi
            fi
        done

        if [ ${#filtered_notes[@]} -eq 0 ]; then
            echo -e "${DIM}No matches${RESET}\n"
        else
            (( selected_index >= ${#filtered_notes[@]} )) && selected_index=0

            for i in "${!filtered_notes[@]}"; do
                local note="${filtered_notes[$i]}"
                local filename=$(basename "$note")
                local heading=$(head -n 1 "$note" | sed 's/^#* *//')
                local note_tags=$(extract_tags "$note")
                local date=$(date -r "$note" "+%Y-%m-%d %H:%M")
                local display_tags="$note_tags"

                # Highlight search term in tags using awk
                if [ -n "$search_term" ]; then
                    display_tags=$(echo "$note_tags" | awk -v term="@$search_term" -v red="$RED" -v reset="$RESET" 'BEGIN{IGNORECASE=1}{
                        gsub(term, red term reset)
                        print
                    }')

                    # Highlight term in filename and heading
                    filename=$(echo "$filename" | awk -v term="$search_term" -v red="$RED" -v reset="$RESET" 'BEGIN{IGNORECASE=1}{
                        gsub(term, red term reset)
                        print
                    }')

                    heading=$(echo "$heading" | awk -v term="$search_term" -v red="$RED" -v reset="$RESET" 'BEGIN{IGNORECASE=1}{
                        gsub(term, red term reset)
                        print
                    }')
                fi

                if [ $i -eq $selected_index ]; then
                    echo -e "${BLUE}→${RESET}    ${YELLOW}[$((i+1))]${RESET} ${BOLD}${heading}${RESET} ${DIM}${date}${RESET} ${DIM}(${filename})${RESET}"
                    echo -e "    ${TAG_COLOR}↳ ${display_tags}${RESET}\n"
                else
                    echo -e "     ${YELLOW}[$((i+1))]${RESET} ${BOLD}${heading}${RESET} ${DIM}${date}${RESET} ${DIM}(${filename})${RESET}"
                    echo -e "    ${TAG_COLOR}↳ ${display_tags}${RESET}\n"
                fi
            done
        fi

        draw_footer "tagsearch"
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
