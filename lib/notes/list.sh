#!/bin/bash
# Note listing and navigation functions

list_notes() {
    clear
    draw_header "DHIO NOTES" "📝"
    local notes=()
    for note in "$NOTES_DIR"/*.md; do
        [ -f "$note" ] && ! [[ "$note" =~ /archive/ ]] && ! [[ "$note" =~ /notebin/ ]] && notes+=("$note")
    done
    
    # Apply sorting
    if [ ${#notes[@]} -gt 0 ]; then
        local sort_pref=$(get_sort_preference)
        local sort_type=$(echo "$sort_pref" | cut -d'|' -f1)
        local sort_order=$(echo "$sort_pref" | cut -d'|' -f2)
        apply_sorting notes "$sort_type" "$sort_order"
    fi
    
    if [ ${#notes[@]} -eq 0 ]; then
        echo -e "${DIM}No notes found. Press 'n' to create your first note!${RESET}\n"
        draw_footer "main"
        while true; do
            key=$(get_key)
            case "$key" in
                n|N) create_note; return ;;
                m|M) template_menu; return ;;
                a|A) archive_menu; return ;;
                t|T) tag_search; return ;;
                r|R) notebin_menu; return ;;
                i|I) show_statistics; return ;;
                /) search_notes_fuzzy "${notes[@]}"; return ;;
                esc) exit 0 ;;
            esac
        done
        return
    fi
    local count=1
    declare -a note_array=("${notes[@]}")
    local current_index=0
    while true; do
        clear
        echo ""
        center_text "✎ᝰ Dhio notes appˎˊ˗"
        echo ""
        # Clamp index
        (( current_index < 0 )) && current_index=0
        (( current_index >= ${#note_array[@]} )) && current_index=$(( ${#note_array[@]} - 1 ))

        for i in "${!note_array[@]}"; do
            local note="${note_array[$i]}"
            local heading=$(head -n 1 "$note" | sed 's/^#* *//')
            local date=$(date -r "$note" "+%Y-%m-%d %H:%M")
            local tags=$(extract_tags "$note")
            local term_width=$(tput cols)
            
            # Format left part
            local left_part=""
            if [ $i -eq $current_index ]; then
                left_part="${BLUE}→${RESET}    ${YELLOW}$((i+1))${RESET} ${BOLD}${heading}${RESET}"
            else
                left_part="     ${YELLOW}$((i+1))${RESET} ${BOLD}${heading}${RESET}"
            fi
            
            # Calculate padding for right-aligned date
            local left_plain=$(echo -e "$left_part" | sed 's/\x1b\[[0-9;]*m//g')
            local left_len=${#left_plain}
            local date_len=${#date}
            local padding=$((term_width - left_len - date_len))
            
            if [ $padding -gt 0 ]; then
                echo -e "$left_part$(printf '%*s' $padding '')${DIM}${date}${RESET}"
            else
                echo -e "$left_part ${DIM}${date}${RESET}"
            fi
            
            # Tags with better spacing
            if [ -n "$tags" ]; then
                echo -e "      ${TAG_COLOR}🏷️ ${tags}${RESET}"
            fi
            echo ""
        done
        draw_footer "main"
        key=$(get_key)
        case "$key" in
            n|N) create_note; return ;;
            a|A) archive_menu; return ;;
            t|T) tag_search; return ;;
            d|D) 
                # Enable selection mode for deletion
                declare -A selected_notes
                local selection_mode=true
                while [ "$selection_mode" = "true" ]; do
                    clear
                    draw_header "DHIO NOTES" "📝"
                    for i in "${!note_array[@]}"; do
                        local note="${note_array[$i]}"
                        local heading=$(head -n 1 "$note" | sed 's/^#* *//')
                        local date=$(date -r "$note" "+%Y-%m-%d %H:%M")
                        local tags=$(extract_tags "$note")
                        local term_width=$(tput cols)
                        local is_selected="${selected_notes[$note]:-false}"
                        local select_indicator=""
                        if [ "$is_selected" = "true" ]; then
                            select_indicator="${GREEN}✓${RESET} "
                        else
                            select_indicator="${GRAY}○${RESET} "
                        fi
                        
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
                    echo -e "${PURPLE}[SPACE]${RESET} Select  ${PURPLE}[D]${RESET} Delete Selected  ${PURPLE}[ESC]${RESET} Cancel"
                    key=$(get_key)
                    case "$key" in
                        esc) selection_mode=false; return ;;
                        " ")
                            local current_note="${note_array[$current_index]}"
                            if [ "${selected_notes[$current_note]}" = "true" ]; then
                                selected_notes[$current_note]="false"
                            else
                                selected_notes[$current_note]="true"
                            fi
                            ;;
                        d|D)
                            local delete_count=0
                            for note in "${!selected_notes[@]}"; do
                                if [ "${selected_notes[$note]}" = "true" ]; then
                                    delete_note "$note"
                                    ((delete_count++))
                                fi
                            done
                            if [ $delete_count -gt 0 ]; then
                                send_notification "Notes App" "$delete_count note(s) deleted"
                                selection_mode=false
                                return
                            else
                                send_notification "Notes App" "No notes selected"
                            fi
                            ;;
                        up)
                            ((current_index--))
                            ((current_index < 0)) && current_index=$(( ${#note_array[@]} - 1 ))
                            ;;
                        down)
                            ((current_index++))
                            ((current_index >= ${#note_array[@]} )) && current_index=0
                            ;;
                    esac
                done
                ;;
            r|R) notebin_menu; return ;;
            s|S) sorting_menu; return ;;
            m|M) template_menu; return ;;
            i|I) show_statistics; return ;;
            /) search_notes_fuzzy "${note_array[@]}"; return ;;
            esc) exit 0 ;;
            up)
                ((current_index--))
                ((current_index < 0)) && current_index=$(( ${#note_array[@]} - 1 ))
                ;;
            down)
                ((current_index++))
                ((current_index >= ${#note_array[@]} )) && current_index=0
                ;;
            "")
                if [ ${#note_array[@]} -gt 0 ]; then
                    preview_note "${note_array[$current_index]}"
                    return
                fi
                ;;
            [0-9])
                local num=$key
                local index=$((num - 1))
                if [ $index -ge 0 ] && [ $index -lt ${#note_array[@]} ]; then
                    preview_note "${note_array[$index]}"
                    return
                fi
                ;;
        esac
    done
}
