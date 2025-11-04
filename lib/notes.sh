#!/bin/bash
# Note CRUD operations

# Create a new note
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
        send_notification "Notes App" "Note created: $heading"
        CURRENT_NOTE="$filepath"
        preview_note "$filepath"
    fi
}

# List all notes
list_notes() {
    clear
    echo ""
    center_text "✎ᝰ Dhio notes appˎˊ˗"
    echo ""
    local notes=()
    for note in "$NOTES_DIR"/*.md; do
        # Skip archived and deleted notes
        [ -f "$note" ] && ! [[ "$note" =~ /archive/ ]] && ! [[ "$note" =~ /notebin/ ]] && notes+=("$note")
    done
    if [ ${#notes[@]} -eq 0 ]; then
        echo -e "${DIM}No notes found. Press 'n' to create your first note!${RESET}\n"
        draw_footer "main"
        while true; do
            key=$(get_key)
            case "$key" in
                n|N) create_note; return ;;
                a|A) archive_menu; return ;;  # <-- Add this line
                r|R) notebin_menu; return ;;
                /) search_notes_fuzzy "${notes[@]}"; return ;;
                esc) exit 0 ;;
                [0-9])
                    local num=$key
                    local index=$((num - 1))
                    if [ $index -ge 0 ] && [ $index -lt ${#notes[@]} ]; then
                        preview_note "${notes[$index]}"
                        return
                    fi
                    ;;
                up|down) ;;  # (if you have arrow nav)
            esac
        done
        return
    fi
    local count=1
    declare -a note_array
    for note in "${notes[@]}"; do
        if [ -f "$note" ]; then
            note_array+=("$note")
            ((count++))
        fi
    done
    local current_index=0
    while true; do
        clear
        echo ""
        center_text "✎ᝰ Dhio notes appˎˊ˗"
        echo ""
        count=1
        for i in "${!note_array[@]}"; do
            local note="${note_array[$i]}"
            local heading=$(head -n 1 "$note" | sed 's/^#* *//')
            local date=$(date -r "$note" "+%Y-%m-%d %H:%M")
            if [ $i -eq $current_index ]; then
                echo -e "${BLUE}→${RESET} $(format_note_line $count "$heading" "$date" "false")"
            else
                echo -e "  $(format_note_line $count "$heading" "$date" "false")"
            fi
            ((count++))
        done
        draw_footer "main"
        key=$(get_key)
        case "$key" in
            n|N) create_note; return ;;
            d|D) delete_note_interactive "${note_array[@]}"; return ;;
            r|R) notebin_menu; return ;;
            a|A) archive_menu; return ;;
            /) search_notes_fuzzy "${note_array[@]}"; return ;;
            esc) exit 0 ;;
            up)
                ((current_index--))
                [ $current_index -lt 0 ] && current_index=$((${#note_array[@]} - 1))
                ;;
            down)
                ((current_index++))
                [ $current_index -ge ${#note_array[@]} ] && current_index=0
                ;;
            "")
                # Enter key: open selected note
                preview_note "${note_array[$current_index]}"
                return
                ;;
        esac
    done
}

# archive the notes
archive_note() {
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

# Edit note
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

# Delete note interactive
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
        echo -e "${YELLOW}[$count]${RESET} ${BOLD}$heading${RESET}"
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

# Delete note (move to notebin)
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
                local basename
                basename=$(basename "$filepath")
                mv "$filepath" "$NOTEBIN_DIR/$basename"
                send_notification "Notes App" "Note moved to bin: $heading"
                sleep 1
                return
                ;;
            n|N|esc) send_notification "Notes App" "Action cancelled"; sleep 1; return ;;
        esac
    done
}
# Preview note
preview_note() {
    local filepath=$1
    CURRENT_NOTE="$filepath"
    clear
    if [ ! -f "$filepath" ]; then
        send_notification "Notes App" "Note not found"
        sleep 1
        return
    fi
    local content
    content=$(cat "$filepath")
    render_markdown "$content"
    draw_footer "preview"

    while true; do
        key=$(get_key)
        case "$key" in
	       	a|A)
	            archive_note "$filepath"
	            return
	            ;;
            e|E)
                edit_note "$filepath"
                return
                ;;
            d|D)
                delete_note "$filepath"
                return
                ;;
            c|C)
                read -rsn1 num
                if [[ "$num" =~ ^[0-9]$ ]]; then
                    local code_file="$NOTES_DIR/.code_block_${num}"
                    if [ -f "$code_file" ]; then
                        local code_content
                        code_content=$(cat "$code_file")
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
            esc)
                return
                ;;
        esac
    done
}

# Main loop
main_menu() {
    while true; do
        list_notes
    done
}
