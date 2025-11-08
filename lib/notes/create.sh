#!/bin/bash
# Note creation functions

create_note() {
    clear
    echo -e "${BOLD}${CYAN}═══════════════════════════════════════${RESET}"
    echo -e "${BOLD}${CYAN}     CREATE NEW NOTE${RESET}"
    echo -e "${BOLD}${CYAN}═══════════════════════════════════════${RESET}\n"
    echo -e "${YELLOW}Enter note heading:${RESET}"
    read -r heading
    if [ -z "$heading" ]; then
        send_notification "Notes App" "Note creation cancelled"
        sleep 1
        return
    fi
    filename=$(echo "$heading" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9]/-/g' | sed 's/--*/-/g' | sed 's/^-//' | sed 's/-$//')
    filepath="$NOTES_DIR/${filename}.md"
    if [ -f "$filepath" ]; then
        send_notification "Notes App" "A note with this heading already exists"
        sleep 1
        return
    fi
    echo "# $heading" > "$TEMP_FILE"
    echo "" >> "$TEMP_FILE"
    echo "Write your note here..." >> "$TEMP_FILE"
    echo "" >> "$TEMP_FILE"
    echo "Use @tags to organize your notes (e.g., @urgent @work @personal)" >> "$TEMP_FILE"
    ${EDITOR:-nano} "$TEMP_FILE"
    if [ -f "$TEMP_FILE" ]; then
        cp "$TEMP_FILE" "$filepath"
        rm "$TEMP_FILE"
        save_note_history "$filepath"
        send_notification "Notes App" "Note created: $heading"
        CURRENT_NOTE="$filepath"
        preview_note "$filepath"
    fi
}
