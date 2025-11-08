#!/bin/bash
# Note preview functions

preview_note() {
    local filepath=$1
    CURRENT_NOTE="$filepath"
    clear
    if [ ! -f "$filepath" ]; then
        send_notification "Notes App" "Note not found"
        sleep 1
        return
    fi
    local content=$(cat "$filepath")
    render_markdown "$content"
    draw_footer "preview"
    while true; do
        key=$(get_key)
        case "$key" in
            e|E) edit_note "$filepath"; return ;;
            a|A) archive_note "$filepath"; return ;;
            d|D) 
                delete_note "$filepath"
                # Return to list after deletion
                return
                ;;
            x|X) export_menu "$filepath"; return ;;
            h|H) browse_note_history "$filepath"; return ;;
            u|U) undo_note_change "$filepath"; sleep 1; preview_note "$filepath"; return ;;
            c|C)
                read -rsn1 num
                if [[ "$num" =~ ^[0-9]$ ]]; then
                    local code_file="$NOTES_DIR/.code_block_${num}"
                    if [ -f "$code_file" ]; then
                        local code_content=$(cat "$code_file")
                        if copy_code_block "$code_content"; then
                            send_notification "Notes App" "Code block $num copied to clipboard"
                        else
                            send_notification "Notes App" "Code saved to: $CODE_TEMP"
                        fi
                    else
                        send_notification "Notes App" "Code block $num not found"
                    fi
                fi
                ;;
            esc) return ;;
        esac
    done
}
