#!/bin/bash
# Generic operations module for common note operations
# This module provides reusable functions for delete, archive, restore, list rendering, and tag search

# Generic note list renderer
# Usage: render_note_list notes_array[@] current_index selected_notes_assoc [context]
render_note_list() {
    local notes_name="$1[@]"
    local notes_ref=("${!notes_name}")
    local current_idx="$2"
    local selected_name="$3"
    local context="${4:-main}"
    local search_term="${5:-}"
    
    local selected_count=0
    eval "for note in \"\${!${selected_name}[@]}\"; do
        eval \"[ \\\"\\\${${selected_name}[\$note]}\\\" = \\\"true\\\" ]\" && ((selected_count++))
    done"
    
    if [ $selected_count -gt 0 ]; then
        echo -e "\n${CYAN}Selected: ${selected_count} note(s)${RESET}\n"
    else
        echo ""
    fi
    
    for i in "${!notes_ref[@]}"; do
        local note="${notes_ref[$i]}"
        [ ! -f "$note" ] && continue
        
        local heading=$(head -n 1 "$note" 2>/dev/null | sed 's/^#* *//' || echo "Untitled")
        local date=$(date -r "$note" "+%Y-%m-%d %H:%M" 2>/dev/null || echo "")
        local tags=$(extract_tags "$note")
        eval "local is_selected=\"\${${selected_name}[\$note]:-false}\""
        
        # Highlight search term if provided
        if [ -n "$search_term" ]; then
            heading=$(echo "$heading" | awk -v term="$search_term" -v red="$RED" -v reset="$RESET" 'BEGIN{IGNORECASE=1}{gsub(term, red term reset); print}')
        fi
        
        # Selection indicator
        local select_indicator=""
        if [ "$is_selected" = "true" ]; then
            select_indicator="${GREEN}[✓]${RESET} "
        else
            select_indicator="${GRAY}[ ]${RESET} "
        fi
        
        # Current item indicator
        if [ $i -eq $current_idx ]; then
            echo -e "${BLUE}→${RESET}${select_indicator}${YELLOW}[$((i+1))]${RESET} ${BOLD}${heading}${RESET} ${DIM}${date}${RESET}"
        else
            echo -e " ${select_indicator}${YELLOW}[$((i+1))]${RESET} ${BOLD}${heading}${RESET} ${DIM}${date}${RESET}"
        fi
        
        if [ -n "$tags" ]; then
            echo -e "      ${TAG_COLOR}🏷️ ${tags}${RESET}"
        else
            echo ""
        fi
    done
}

# Generic delete operation
# Usage: generic_delete notes_array[@] target_dir [operation_name]
generic_delete() {
    local notes_name="$1[@]"
    local notes=("${!notes_name}")
    local target_dir="$2"
    local op_name="${3:-Delete}"
    
    if [ ${#notes[@]} -eq 0 ]; then
        send_notification "Notes App" "No notes to $op_name"
        return
    fi
    
    declare -A selected_notes
    local current_index=0
    
    while true; do
        clear
        echo -e "${BOLD}${RED}$(printf '%*s' 40 '' | tr ' ' '-')${RESET}"
        echo -e "${BOLD}${RED}     $op_name${RESET}"
        echo -e "${BOLD}${RED}═══════════════════════════════════════${RESET}\n"
        
        render_note_list notes current_index selected_notes "delete"
        
        draw_footer "delete"
        key=$(get_key)
        
        case "$key" in
            esc) return ;;
            up)
                ((current_index--))
                ((current_index < 0)) && current_index=$((${#notes[@]} - 1))
                ;;
            down)
                ((current_index++))
                ((current_index >= ${#notes[@]})) && current_index=0
                ;;
            " ")
                local current_note="${notes[$current_index]}"
                if [ "${selected_notes[$current_note]}" = "true" ]; then
                    selected_notes[$current_note]="false"
                else
                    selected_notes[$current_note]="true"
                fi
                ;;
            y|Y)
                local delete_count=0
                for note in "${!selected_notes[@]}"; do
                    [ "${selected_notes[$note]}" = "true" ] && ((delete_count++))
                done
                
                if [ $delete_count -eq 0 ]; then
                    # Delete current note if none selected
                    if [ ${#notes[@]} -gt 0 ] && [ -f "${notes[$current_index]}" ]; then
                        move_note_to_dir "${notes[$current_index]}" "$target_dir"
                        return
                    fi
                else
                    # Delete selected notes
                    for note in "${!selected_notes[@]}"; do
                        if [ "${selected_notes[$note]}" = "true" ] && [ -f "$note" ]; then
                            move_note_to_dir "$note" "$target_dir"
                        fi
                    done
                    send_notification "Notes App" "$delete_count note(s) moved"
                    return
                fi
                ;;
            [0-9])
                local num=$key
                local index=$((num - 1))
                if [ $index -ge 0 ] && [ $index -lt ${#notes[@]} ]; then
                    move_note_to_dir "${notes[$index]}" "$target_dir"
                    return
                fi
                ;;
        esac
    done
}

# Generic archive operation
generic_archive() {
    local notes_name="$1"
    generic_delete "$notes_name" "$ARCHIVE_DIR" "Archive"
}

# Generic restore operation
# Usage: generic_restore notes_array[@] target_dir
generic_restore() {
    local notes_name="$1[@]"
    local notes=("${!notes_name}")
    local target_dir="$2"
    
    if [ ${#notes[@]} -eq 0 ]; then
        send_notification "Notes App" "No notes to restore"
        return
    fi
    
    declare -A selected_notes
    local current_index=0
    
    while true; do
        clear
        echo -e "${BOLD}${GREEN}$(printf '%*s' 40 '' | tr ' ' '-')${RESET}"
        echo -e "${BOLD}${GREEN}     RESTORE NOTES${RESET}"
        echo -e "${BOLD}${GREEN}═══════════════════════════════════════${RESET}\n"
        
        render_note_list notes current_index selected_notes "restore"
        
        draw_footer "restore"
        key=$(get_key)
        
        case "$key" in
            esc) return ;;
            up)
                ((current_index--))
                ((current_index < 0)) && current_index=$((${#notes[@]} - 1))
                ;;
            down)
                ((current_index++))
                ((current_index >= ${#notes[@]})) && current_index=0
                ;;
            " ")
                local current_note="${notes[$current_index]}"
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
                        move_note_to_dir "$note" "$target_dir"
                        ((restore_count++))
                        unset selected_notes[$note]
                    fi
                done
                
                if [ $restore_count -gt 0 ]; then
                    send_notification "Notes App" "$restore_count note(s) restored"
                    sleep 1
                    # Refresh list
                    notes=()
                    for note in "$(dirname "$target_dir")"/*.md; do
                        [ -f "$note" ] && notes+=("$note")
                    done
                    ((current_index>=${#notes[@]})) && current_index=$((${#notes[@]} - 1))
                else
                    send_notification "Notes App" "No notes selected to restore"
                    sleep 1
                fi
                ;;
        esac
    done
}

# Move note to directory (used by delete/archive)
move_note_to_dir() {
    local filepath="$1"
    local target_dir="$2"
    
    if [ ! -f "$filepath" ]; then
        send_notification "Notes App" "Note not found"
        return 1
    fi
    
    local basename=$(basename "$filepath")
    local heading=$(head -n 1 "$filepath" 2>/dev/null | sed 's/^#* *//' || echo "Untitled")
    
    mkdir -p "$target_dir"
    mv "$filepath" "$target_dir/$basename" 2>/dev/null
    
    if [ $? -eq 0 ]; then
        send_notification "Notes App" "Note moved: $heading"
        return 0
    else
        send_notification "Notes App" "Failed to move note"
        return 1
    fi
}

# Generic tag search
# Usage: generic_tag_search notes_array[@] [search_context]
generic_tag_search() {
    local notes_name="$1[@]"
    local notes_ref=("${!notes_name}")
    local context="${2:-main}"
    local search_term=""
    local selected_index=0
    
    while true; do
        clear
        echo -e "${BOLD}${CYAN}$(printf '%*s' 40 '' | tr ' ' '-')${RESET}"
        echo -e "${BOLD}${CYAN}     FILTER BY TAG${RESET}"
        echo -e "${BOLD}${CYAN}═══════════════════════════════════════${RESET}\n"
        echo -e "${BOLD}${CYAN}Search:${RESET} ${YELLOW}${search_term}${RESET}\n"
        
        local filtered_notes=()
        for note in "${notes_ref[@]}"; do
            if [ -f "$note" ]; then
                local note_tags=$(extract_tags "$note")
                if [ -z "$search_term" ] || echo "$note_tags" | grep -qi "@$search_term"; then
                    filtered_notes+=("$note")
                fi
            fi
        done
        
        if [ ${#filtered_notes[@]} -eq 0 ]; then
            echo -e "${DIM}No matches${RESET}\n"
        else
            (( selected_index >= ${#filtered_notes[@]} )) && selected_index=0
            
            declare -A empty_selected
            render_note_list filtered_notes selected_index empty_selected "tagsearch" "$search_term"
        fi
        
        draw_footer "tagsearch"
        key=$(get_key)
        
        case "$key" in
            esc) return ;;
            up)
                ((selected_index--))
                ((selected_index < 0)) && selected_index=$((${#filtered_notes[@]} - 1))
                ;;
            down)
                ((selected_index++))
                ((selected_index >= ${#filtered_notes[@]})) && selected_index=0
                ;;
            $'\x7f')
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

# Generic search function
# Usage: generic_search notes_array[@] [search_context]
generic_search() {
    local notes_name="$1[@]"
    local notes_ref=("${!notes_name}")
    local context="${2:-main}"
    local search_term=""
    local selected_index=0
    
    while true; do
        clear
        echo -e "${BOLD}${CYAN}$(printf '%*s' 40 '' | tr ' ' '-')${RESET}"
        echo -e "${BOLD}${CYAN}     SEARCH NOTES${RESET}"
        echo -e "${BOLD}${CYAN}═══════════════════════════════════════${RESET}\n"
        echo -e "${BOLD}${CYAN}Search:${RESET} ${YELLOW}${search_term}${RESET}\n"
        
        local filtered_notes=()
        local match_lines=()
        
        for note in "${notes_ref[@]}"; do
            if [ -f "$note" ]; then
                local heading=$(head -n 1 "$note" 2>/dev/null | sed 's/^#* *//' || echo "")
                local content=$(cat "$note" 2>/dev/null || echo "")
                
                if [ -z "$search_term" ] ||
                   echo "$heading" | grep -qi -- "$search_term" 2>/dev/null ||
                   echo "$content" | grep -qi -- "$search_term" 2>/dev/null; then
                    filtered_notes+=("$note")
                    
                    if [ -n "$search_term" ]; then
                        local match_result=$(grep -m 1 -n -i -- "$search_term" "$note" 2>/dev/null || echo "")
                        if [ -n "$match_result" ]; then
                            local line_num=$(echo "$match_result" | cut -d: -f1)
                            local match_line=$(echo "$match_result" | cut -d: -f2- | head -c 80)
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
                local heading=$(head -n 1 "$note" 2>/dev/null | sed 's/^#* *//' || echo "Untitled")
                local date=$(date -r "$note" "+%Y-%m-%d %H:%M" 2>/dev/null || echo "")
                local tags=$(extract_tags "$note")
                
                if [ -n "$search_term" ]; then
                    heading=$(echo "$heading" | awk -v term="$search_term" -v red="$RED" -v reset="$RESET" 'BEGIN{IGNORECASE=1}{gsub(term, red term reset); print}')
                fi
                
                if [ $i -eq $selected_index ]; then
                    echo -e "${BLUE}→${RESET}    ${YELLOW}[$((i+1))]${RESET} ${BOLD}${heading}${RESET} ${DIM}${date}${RESET}"
                    echo -e "      ${TAG_COLOR}🏷️ ${tags}${RESET}"
                    if [ -n "${match_lines[$i]}" ]; then
                        echo -e "      ${match_lines[$i]}\n"
                    else
                        echo ""
                    fi
                else
                    echo -e "     ${YELLOW}[$((i+1))]${RESET} ${BOLD}${heading}${RESET} ${DIM}${date}${RESET}"
                    echo -e "      ${TAG_COLOR}🏷️ ${tags}${RESET}"
                    if [ -n "${match_lines[$i]}" ]; then
                        echo -e "      ${match_lines[$i]}\n"
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
                ((selected_index < 0)) && selected_index=$((${#filtered_notes[@]} - 1))
                ;;
            down)
                ((selected_index++))
                ((selected_index >= ${#filtered_notes[@]})) && selected_index=0
                ;;
            $'\x7f')
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

