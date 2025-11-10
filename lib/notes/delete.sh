#!/bin/bash
# Note deletion functions

delete_note_interactive() {
    local notes=("$@")
    clear
    echo -e "${BOLD}${RED}$(printf '%*s' 40 '' | tr ' ' '-')${RESET}"
    echo -e "${BOLD}${RED}     Move to Bin${RESET}"
    echo -e "${BOLD}${RED}═══════════════════════════════════════${RESET}\n"
    echo -e "${YELLOW}Enter note number to delete:${RESET}\n"
    local count=1
    for note in "${notes[@]}"; do
        local heading=$(head -n 1 "$note" | sed 's/^#* *//')
        local tags=$(extract_tags "$note")
        echo -e "    ${YELLOW}[$count]${RESET} ${BOLD}${heading}${RESET} ${DIM}$(date -r "$note" "+%Y-%m-%d %H:%M")${RESET}"
        echo -e "      ${TAG_COLOR}🏷️ ${tags}${RESET}\n"
        ((count++))
    done
    draw_footer "delete"
    while true; do
        key=$(get_key)
        case "$key" in
            esc) send_notification "Notes App" "Action cancelled"; return ;;
            [0-9])
                local num=$key
                local index=$((num - 1))
                if [ $index -ge 0 ] && [ $index -lt ${#notes[@]} ]; then
                    delete_note "${notes[$index]}"
                    return
                fi
                ;;
        esac
    done
}

delete_note() {
    local filepath=$1
    if [ ! -f "$filepath" ]; then
        send_notification "Notes App" "Note not found"
        return
    fi
    local heading
    heading=$(head -n 1 "$filepath" | sed 's/^#* *//')
    local basename=$(basename "$filepath")
    mv "$filepath" "$NOTEBIN_DIR/$basename" 2>/dev/null
    if [ $? -eq 0 ]; then
        send_notification "Notes App" "$heading deleted (can be recovered later)"
    else
        send_notification "Notes App" "Failed to delete note"
    fi
}
