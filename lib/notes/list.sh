#!/bin/bash
# Note listing and navigation functions

list_notes() {
    clear
    echo ""
    center_text "✎ᝰ Dhio notes appˎˊ˗"
    echo ""
    local notes=()
    for note in "$NOTES_DIR"/*.md; do
        [ -f "$note" ] && ! [[ "$note" =~ /archive/ ]] && ! [[ "$note" =~ /notebin/ ]] && notes+=("$note")
    done
    if [ ${#notes[@]} -eq 0 ]; then
        echo -e "${DIM}No notes found. Press 'n' to create your first note!${RESET}\n"
        draw_footer "main"
        while true; do
            key=$(get_key)
            case "$key" in
                n|N) create_note; return ;;
                a|A) archive_menu; return ;;
                t|T) tag_search; return ;;
                r|R) notebin_menu; return ;;
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
            if [ $i -eq $current_index ]; then
                echo -e "${BLUE}→${RESET}    ${YELLOW}[$((i+1))]${RESET} ${BOLD}${heading}${RESET} ${DIM}${date}${RESET}"
                echo -e "    ${TAG_COLOR}↳ ${tags}${RESET}\n"
            else
                echo -e "     ${YELLOW}[$((i+1))]${RESET} ${BOLD}${heading}${RESET} ${DIM}${date}${RESET}"
                echo -e "    ${TAG_COLOR}↳ ${tags}${RESET}\n"
            fi
        done
        draw_footer "main"
        key=$(get_key)
        case "$key" in
            n|N) create_note; return ;;
            a|A) archive_menu; return ;;
            t|T) tag_search; return ;;
            d|D) delete_note_interactive "${note_array[@]}"; return ;;
            r|R) notebin_menu; return ;;
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
