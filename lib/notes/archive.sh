#!/bin/bash
# Archive-related functions

archive_note() {
    local filepath="$1"
    if [ ! -f "$filepath" ]; then
        send_notification "Notes App" "Note not found"
        sleep 1
        return
    fi
    local heading
    heading=$(head -n 1 "$filepath" | sed 's/^#* *//')
    clear
    echo -e "${YELLOW}${BOLD}═══════════════════════════════════════${RESET}"
    echo -e "${YELLOW}${BOLD}     ARCHIVE NOTE${RESET}"
    echo -e "${YELLOW}${BOLD}═══════════════════════════════════════${RESET}\n"
    echo -e "${CYAN}Archive note: ${BOLD}$heading${RESET}"
    echo -e "\n${DIM}Note will be moved to archive (can be restored later)${RESET}\n"
    draw_footer "delete"
    while true; do
        key=$(get_key)
        case "$key" in
            y|Y)
                local basename=$(basename "$filepath")
                mv "$filepath" "$ARCHIVE_DIR/$basename"
                send_notification "Notes App" "Note archived: $heading"
                sleep 1
                return
                ;;
            n|N|esc) send_notification "Notes App" "Action cancelled"; sleep 1; return ;;
        esac
    done
}
