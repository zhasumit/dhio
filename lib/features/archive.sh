#!/bin/bash
# Archive feature for Dhio Notes App

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
    echo -e "${YELLOW}${BOLD}$(printf '%*s' 40 '' | tr ' ' '-')${RESET}"
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
        echo -e "${BOLD}${CYAN}$(printf '%*s' 40 '' | tr ' ' '-')${RESET}"
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
                        local match_result=$(grep -m 1 -n -i -- "$search_term" "$note" 2>/dev/null || echo "")
                        if [ -n "$match_result" ]; then
                            local line_num=$(echo "$match_result" | cut -d: -f1)
                            local match_line=$(echo "$match_result" | cut -d: -f2-)
                            match_line=$(echo "$match_line" | awk -v term="$search_term" -v red="$RED" -v reset="$RESET" 'BEGIN{IGNORECASE=1}{gsub(term, red term reset); print}')
                            match_lines+=("${DIM}[$line_num]${RESET}  $match_line")
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
                    heading=$(echo "$heading" | awk -v term="$search_term" -v red="$RED" -v reset="$RESET" 'BEGIN{IGNORECASE=1}{gsub(term, red term reset); print}')
                fi

                local term_width=$(tput cols)
                local left_part=""
                if [ $i -eq $selected_index ]; then
                    left_part="${BLUE}→${RESET}    ${YELLOW}$((i+1))${RESET} ${BOLD}${heading}${RESET}"
                else
                    left_part="     ${YELLOW}$((i+1))${RESET} ${BOLD}${heading}${RESET}"
                fi
                
                local left_plain=$(echo -e "$left_part" | sed 's/\x1b\[[0-9;]*m//g')
                local left_len=${#left_plain}
                local date_len=${#date}
                local padding=$((term_width - left_len - date_len))
                
                if [ $padding -gt 0 ]; then
                    echo -e "$left_part$(printf '%*s' $padding '')${DIM}${date}${RESET}"
                else
                    echo -e "$left_part ${DIM}${date}${RESET}"
                fi
                
                if [ -n "$tags" ]; then
                    echo -e "      ${TAG_COLOR}• ${tags}${RESET}"
                fi

                if [ -n "${match_lines[$i]}" ]; then
                    echo -e "      ${match_lines[$i]}\n"
                else
                    echo ""
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
            local select_indicator=""
            if [ "$is_selected" = "true" ]; then
                select_indicator="${GREEN}✓${RESET} "
            else
                select_indicator="${GRAY}○${RESET} "
            fi
            local term_width=$(tput cols)
            local left_part=""
            if [ $i -eq $current_index ]; then
                left_part="${BLUE}→${RESET} ${select_indicator}${YELLOW}$((i+1))${RESET} ${BOLD}${heading}${RESET}"
            else
                left_part="  ${select_indicator}${YELLOW}$((i+1))${RESET} ${BOLD}${heading}${RESET}"
            fi
            
            local left_plain=$(echo -e "$left_part" | sed 's/\x1b\[[0-9;]*m//g')
            local left_len=${#left_plain}
            local date_len=${#date}
            local padding=$((term_width - left_len - date_len))
            
            if [ $padding -gt 0 ]; then
                echo -e "$left_part$(printf '%*s' $padding '')${DIM}${date}${RESET}"
            else
                echo -e "$left_part ${DIM}${date}${RESET}"
            fi
            
            if [ -n "$tags" ]; then
                echo -e "      ${TAG_COLOR}🏷️ ${tags}${RESET}"
            fi
            echo ""
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
            "")
                if [ ${#note_array[@]} -gt 0 ]; then
                    preview_note "${note_array[$current_index]}"
                    return
                fi
                ;;
            r|R)
                local restore_count=0
                local restored_names=()
                for note in "${!selected_notes[@]}"; do
                    if [ "${selected_notes[$note]}" = "true" ] && [ -f "$note" ]; then
                        local basename=$(basename "$note")
                        local heading=$(head -n 1 "$note" | sed 's/^#* *//')
                        if mv "$note" "$NOTES_DIR/$basename" 2>/dev/null; then
                            ((restore_count++))
                            restored_names+=("$heading")
                            unset selected_notes[$note]
                        fi
                    fi
                done
                if ((restore_count > 0)); then
                    send_notification "Notes App" "$restore_count note(s) restored"
                    # Refresh list
                    note_array=()
                    for note in "$ARCHIVE_DIR"/*.md; do
                        [ -f "$note" ] && note_array+=("$note")
                    done
                    ((current_index>=${#note_array[@]})) && current_index=$(( ${#note_array[@]} - 1 ))
                    if [ $current_index -lt 0 ]; then
                        current_index=0
                    fi
                else
                    send_notification "Notes App" "No notes selected to restore"
                fi
                ;;
            d|D|x|X)
                # Combined delete/purge
                local delete_count=0
                local notes_to_delete=()
                for note in "${!selected_notes[@]}"; do
                    if [ "${selected_notes[$note]}" = "true" ] && [ -f "$note" ]; then
                        ((delete_count++))
                        notes_to_delete+=("$note")
                    fi
                done
                if ((delete_count == 0)); then
                    send_notification "Notes App" "No notes selected to delete"
                    continue
                fi
                clear
                echo -e "${RED}${BOLD}$(printf '%*s' 40 '' | tr ' ' '-')${RESET}"
                echo -e "${RED}${BOLD}     PERMANENT DELETION${RESET}"
                echo -e "${RED}${BOLD}═══════════════════════════════════════${RESET}\n"
                echo -e "${RED}${BOLD}This will permanently delete ${delete_count} note(s)!${RESET}"
                echo -e "${YELLOW}[Y]${RESET} Confirm    ${YELLOW}[N]${RESET} Cancel\n"
                read -rsn1 confirm
                if [[ "$confirm" =~ [yY] ]]; then
                    local deleted=0
                    local deleted_names=()
                    for note in "${notes_to_delete[@]}"; do
                        if [ -f "$note" ]; then
                            local heading=$(head -n 1 "$note" | sed 's/^#* *//')
                            if rm -f "$note" 2>/dev/null; then
                                ((deleted++))
                                deleted_names+=("$heading")
                                unset selected_notes[$note]
                            fi
                        fi
                    done
                    if ((deleted > 0)); then
                        for name in "${deleted_names[@]}"; do
                            send_notification "Notes App" "Cannot recover permanently deleted: $name"
                        done
                    fi
                    # Refresh list
                    note_array=()
                    for note in "$ARCHIVE_DIR"/*.md; do
                        [ -f "$note" ] && note_array+=("$note")
                    done
                    ((current_index>=${#note_array[@]})) && current_index=$(( ${#note_array[@]} - 1 ))
                    if [ $current_index -lt 0 ]; then
                        current_index=0
                    fi
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
