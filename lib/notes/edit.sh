#!/bin/bash
# Note editing functions

edit_note() {
    local filepath=$1
    if [ ! -f "$filepath" ]; then
        send_notification "Notes App" "Note not found"
        sleep 1
        return
    fi
    ${EDITOR:-nano} "$filepath"
    local heading
    heading=$(head -n 1 "$filepath" | sed 's/^#* *//')
    send_notification "Notes App" "Note updated: $heading"
    preview_note "$filepath"
}
