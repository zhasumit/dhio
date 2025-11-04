#!/bin/bash
# Archive logic (mirrors notebin.sh)

# Ensure archive directory exists
mkdir -p "$ARCHIVE_DIR"

archive_menu() {
    local archived_notes=("$ARCHIVE_DIR"/*.md)
    if [ ! -e "${archived_notes[0]}" ]; then
        clear
        echo ""
        center_text "🗄️ Archive"
        echo ""
        echo -e "${DIM}No archived notes found.${RESET}\n"
        echo -e "${GRAY}Press any key to go back...${RESET}"
        read -rsn1
        return
    fi
    declare -A selected_notes
    local current_index=0
    local note_array=()
    for note in "$ARCHIVE_DIR"/*.md; do
        [ -f "$note" ] && note_array+=("$note")
    done
    while true; do
        # --- Handle empty archive ---
        if [ ${#note_array[@]} -eq 0 ]; then
            clear
            echo ""
            center_text "🗄️ Archive"
            echo ""
            echo -e "${DIM}No archived notes found.${RESET}\n"
            echo -e "${GRAY}Press any key to go back...${RESET}"
            read -rsn1
            return
        fi
        # Clamp index
        (( current_index < 0 )) && current_index=0
        (( current_index >= ${#note_array[@]} )) && current_index=$(( ${#note_array[@]} - 1 ))
        # --- Render UI ---
        clear
        echo ""
        center_text "🗄️ Archive"
        echo ""
        local selected_count=0
        for note in "${!selected_notes[@]}"; do
            [ "${selected_notes[$note]}" = "true" ] && ((selected_count++))
        done
        ((selected_count > 0)) && echo -e "\n${CYAN}Selected: ${selected_count} note(s)${RESET}\n" || echo ""
        for i in "${!note_array[@]}"; do
            local note="${note_array[$i]}"
            local heading=$(head -n 1 "$note" | sed 's/^#* *//')
            local date=$(date -r "$note" "+%Y-%m-%d %H:%M")
            local is_selected="${selected_notes[$note]:-false}"
            if [ $i -eq $current_index ]; then
                echo -e "${BLUE}→${RESET} $(format_note_line $((i+1)) "$heading" "$date" "$is_selected")"
            else
                echo -e "  $(format_note_line $((i+1)) "$heading" "$date" "$is_selected")"
            fi
        done
        draw_footer "archive"
        key=$(get_key)
        case "$key" in
            up)
                ((current_index--))
                ((current_index < 0)) && current_index=$(( ${#note_array[@]} - 1 ))
                ;;
            down)
                ((current_index++))
                ((current_index >= ${#note_array[@]} )) && current_index=0
                ;;
            " ")
                local current_note="${note_array[$current_index]}"
                if [ "${selected_notes[$current_note]}" = "true" ]; then
                    selected_notes[$current_note]="false"
                else
                    selected_notes[$current_note]="true"
                fi
                ;;
            r|R)
                local restore_count=0
                for note in "${!selected_notes[@]}"; do
                    if [ "${selected_notes[$note]}" = "true" ] && [ -f "$note" ]; then
                        mv "$note" "$NOTES_DIR/"
                        ((restore_count++))
                        unset selected_notes[$note]
                    fi
                done
                if ((restore_count > 0)); then
                    send_notification "Notes App" "$restore_count note(s) restored"
                    sleep 1
                    # Refresh list
                    note_array=()
                    for note in "$ARCHIVE_DIR"/*.md; do
                        [ -f "$note" ] && note_array+=("$note")
                    done
                    ((current_index>=${#note_array[@]})) && current_index=$(( ${#note_array[@]} - 1 ))
                else
                    send_notification "Notes App" "No notes selected to restore"
                    sleep 1
                fi
                ;;
            d|D|x|X)
                local delete_count=0
                for note in "${!selected_notes[@]}"; do
                    [ "${selected_notes[$note]}" = "true" ] && ((delete_count++))
                done
                if ((delete_count == 0)); then
                    send_notification "Notes App" "No notes selected to delete"
                    sleep 1
                    continue
                fi
                clear
                echo -e "${RED}${BOLD}═══════════════════════════════════════${RESET}"
                echo -e "${RED}${BOLD}     PERMANENT DELETION${RESET}"
                echo -e "${RED}${BOLD}═══════════════════════════════════════${RESET}\n"
                echo -e "${RED}${BOLD}This will permanently delete ${delete_count} note(s)!${RESET}"
                echo -e "${YELLOW}[Y]${RESET} Confirm    ${YELLOW}[N]${RESET} Cancel\n"
                read -rsn1 confirm
                if [[ "$confirm" =~ [yY] ]]; then
                    local deleted=0
                    for note in "${!selected_notes[@]}"; do
                        if [ "${selected_notes[$note]}" = "true" ] && [ -f "$note" ]; then
                            rm -f "$note"
                            ((deleted++))
                            unset selected_notes[$note]
                        fi
                    done
                    send_notification "Notes App" "$deleted note(s) permanently deleted"
                    sleep 1
                    # Refresh list
                    note_array=()
                    for note in "$ARCHIVE_DIR"/*.md; do
                        [ -f "$note" ] && note_array+=("$note")
                    done
                    ((current_index>=${#note_array[@]})) && current_index=$(( ${#note_array[@]} - 1 ))
                fi
                ;;
            esc)
                return
                ;;
        esac
    done
}
