#!/bin/bash
# Note deletion functions

delete_note_interactive() {
    local notes=("$@")
    clear
    echo -e "${BOLD}${RED}═══════════════════════════════════════${RESET}"
    echo -e "${BOLD}${RED}     Move to Bin${RESET}"
    echo -e "${BOLD}${RED}═══════════════════════════════════════${RESET}\n"
    echo -e "${YELLOW}Enter note number to delete:${RESET}\n"
    local count=1
    for note in "${notes[@]}"; do
        local heading=$(head -n 1 "$note" | sed 's/^#* *//')
        local tags=$(extract_tags "$note")
        echo -e "    ${YELLOW}[$count]${RESET} ${BOLD}${heading}${RESET} ${DIM}$(date -r "$note" "+%Y-%m-%d %H:%M")${RESET}"
        echo -e "    ${TAG_COLOR}   ↳ ${tags}${RESET}\n"
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
        sleep 1
        return
    fi
    local heading
    heading=$(head -n 1 "$filepath" | sed 's/^#* *//')
    clear
    echo -e "${YELLOW}${BOLD}═══════════════════════════════════════${RESET}"
    echo -e "${YELLOW}${BOLD}     MOVE TO BIN${RESET}"
    echo -e "${YELLOW}${BOLD}═══════════════════════════════════════${RESET}\n"
    echo -e "${CYAN}Move to bin: ${BOLD}$heading${RESET}"
    echo -e "\n${DIM}Note will be moved to notebin (can be restored later)${RESET}\n"
    draw_footer "delete"
    while true; do
        key=$(get_key)
        case "$key" in
            y|Y)
                local basename=$(basename "$filepath")
                mv "$filepath" "$NOTEBIN_DIR/$basename"
                send_notification "Notes App" "Note moved to bin: $heading"
                sleep 1
                return
                ;;
            n|N|esc) send_notification "Notes App" "Action cancelled"; sleep 1; return ;;
        esac
    done
}
