#!/bin/bash
# Note editing functions

edit_note() {
    local filepath=$1
    if [ ! -f "$filepath" ]; then
        send_notification "Notes App" "Note not found"
        sleep 1
        return
    fi
    
    # Save history before editing
    save_note_history "$filepath"
    
    ${EDITOR:-nano} "$filepath"
    
    # Save history after editing
    save_note_history "$filepath"
    
    local heading
    heading=$(head -n 1 "$filepath" | sed 's/^#* *//')
    send_notification "Notes App" "Note updated: $heading"
    preview_note "$filepath"
}
