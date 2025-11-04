#!/bin/bash
# Archive logic for Dhio Notes App

# Archive a note (move to archive directory)
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

# Search archived notes
search_archived_notes() {
    local archived_notes=("$ARCHIVE_DIR"/*.md)
    local search_term=""
    local selected_index=0

    while true; do
        clear
        echo -e "${BOLD}${CYAN}═══════════════════════════════════════${RESET}"
        echo -e "${BOLD}${CYAN}     SEARCH ARCHIVE${RESET}"
        echo -e "${BOLD}${CYAN}═══════════════════════════════════════${RESET}\n"
        echo -e "${BOLD}${CYAN}Search:${RESET} ${YELLOW}${search_term}${RESET}\n"

        local filtered_notes=()
        local match_lines=()

        for note in "$ARCHIVE_DIR"/*.md; do
            if [ -f "$note" ]; then
                local heading=$(head -n 1 "$note" | sed 's/^#* *//')
                local content=$(cat "$note")

                if [ -z "$search_term" ] ||
                   [[ "$heading" =~ $search_term ]] ||
                   [[ "$content" =~ $search_term ]]; then
                    filtered_notes+=("$note")

                    if [ -n "$search_term" ]; then
                        local match_line=$(grep -m 1 -i -- "$search_term" "$note" 2>/dev/null || echo "")
                        if [ -n "$match_line" ]; then
                            match_line=$(echo "$match_line" | sed "s/$search_term/${RED}&${RESET}/gi")
                            match_lines+=("$match_line")
                        else
                            match_lines+=("")
                        fi
                    else
                        match_lines+=("")
                    fi
                fi
            fi
        done

        if [ ${#filtered_notes[@]} -eq 0 ]; then
            echo -e "${DIM}No matches found${RESET}\n"
        else
            (( selected_index >= ${#filtered_notes[@]} )) && selected_index=0

            for i in "${!filtered_notes[@]}"; do
                local note="${filtered_notes[$i]}"
                local heading=$(head -n 1 "$note" | sed 's/^#* *//')
                local date=$(date -r "$note" "+%Y-%m-%d %H:%M")
                local tags=$(extract_tags "$note")

                if [ -n "$search_term" ]; then
                    heading=$(echo "$heading" | sed "s/$search_term/${RED}&${RESET}/gi")
                fi

                if [ $i -eq $selected_index ]; then
                    echo -e "${BLUE}→${RESET}    ${YELLOW}[$((i+1))]${RESET} ${BOLD}${heading}${RESET} ${DIM}${date}${RESET}"
                    echo -e "    ${TAG_COLOR}↳ ${tags}${RESET}"

                    if [ -n "${match_lines[$i]}" ]; then
                        echo -e "    ${DIM}┃${RESET} ${match_lines[$i]}\n"
                    else
                        echo ""
                    fi
                else
                    echo -e "     ${YELLOW}[$((i+1))]${RESET} ${BOLD}${heading}${RESET} ${DIM}${date}${RESET}"
                    echo -e "    ${TAG_COLOR}↳ ${tags}${RESET}"

                    if [ -n "${match_lines[$i]}" ]; then
                        echo -e "    ${DIM}┃${RESET} ${match_lines[$i]}\n"
                    else
                        echo ""
                    fi
                fi
            done
        fi

        draw_footer "search"
        key=$(get_key)

        case "$key" in
            esc) return ;;
            up)
                ((selected_index--))
                ((selected_index < 0)) && selected_index=$(( ${#filtered_notes[@]} - 1 ))
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

# Archive menu (mirrors notebin menu)
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
        # --- Clamp index ---
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
            local tags=$(extract_tags "$note")
            local is_selected="${selected_notes[$note]:-false}"
            if [ $i -eq $current_index ]; then
                echo -e "${BLUE}→${RESET}    ${YELLOW}[$((i+1))]${RESET} ${BOLD}${heading}${RESET} ${DIM}${date}${RESET}"
                echo -e "    ${TAG_COLOR}↳ ${tags}${RESET}\n"
            else
                echo -e "     ${YELLOW}[$((i+1))]${RESET} ${BOLD}${heading}${RESET} ${DIM}${date}${RESET}"
                echo -e "    ${TAG_COLOR}↳ ${tags}${RESET}\n"
            fi
        done
        # --- Footer and Input ---
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
            /)
                search_archived_notes
                return
                ;;
            esc)
                return
                ;;
        esac
    done
}
