#!/bin/bash
# Note statistics module with improved display

# Get total note count
get_total_notes() {
    local count=0
    for note in "$NOTES_DIR"/*.md; do
        [ -f "$note" ] && ! [[ "$note" =~ /archive/ ]] && ! [[ "$note" =~ /notebin/ ]] && ((count++))
    done
    echo $count
}

# Get archived note count
get_archived_count() {
    local count=0
    for note in "$ARCHIVE_DIR"/*.md; do
        [ -f "$note" ] && ((count++))
    done
    echo $count
}

# Get deleted note count
get_deleted_count() {
    local count=0
    for note in "$NOTEBIN_DIR"/*.md; do
        [ -f "$note" ] && ((count++))
    done
    echo $count
}

# Get notes by tag
get_notes_by_tag() {
    local tag="$1"
    local count=0
    
    for note in "$NOTES_DIR"/*.md; do
        if [ -f "$note" ] && ! [[ "$note" =~ /archive/ ]] && ! [[ "$note" =~ /notebin/ ]]; then
            local tags=$(extract_tags "$note")
            if echo "$tags" | grep -qi "@$tag"; then
                ((count++))
            fi
        fi
    done
    
    echo $count
}

# Get all unique tags
get_all_tags() {
    declare -A tag_set
    
    for note in "$NOTES_DIR"/*.md; do
        if [ -f "$note" ] && ! [[ "$note" =~ /archive/ ]] && ! [[ "$note" =~ /notebin/ ]]; then
            local tags=$(extract_tags "$note")
            for tag in $tags; do
                tag_set["$tag"]=1
            done
        fi
    done
    
    printf '%s\n' "${!tag_set[@]}" | sort
}

# Get total word count
get_total_words() {
    local total=0
    
    for note in "$NOTES_DIR"/*.md; do
        if [ -f "$note" ] && ! [[ "$note" =~ /archive/ ]] && ! [[ "$note" =~ /notebin/ ]]; then
            local words=$(wc -w < "$note" 2>/dev/null || echo "0")
            total=$((total + words))
        fi
    done
    
    echo $total
}

# Get total character count
get_total_chars() {
    local total=0
    
    for note in "$NOTES_DIR"/*.md; do
        if [ -f "$note" ] && ! [[ "$note" =~ /archive/ ]] && ! [[ "$note" =~ /notebin/ ]]; then
            local chars=$(wc -c < "$note" 2>/dev/null || echo "0")
            total=$((total + chars))
        fi
    done
    
    echo $total
}

# Get oldest note date
get_oldest_note_date() {
    local oldest=""
    
    for note in "$NOTES_DIR"/*.md; do
        if [ -f "$note" ] && ! [[ "$note" =~ /archive/ ]] && ! [[ "$note" =~ /notebin/ ]]; then
            local mtime=$(stat -f %m "$note" 2>/dev/null || stat -c %Y "$note" 2>/dev/null || echo "0")
            if [ -z "$oldest" ] || [ "$mtime" -lt "$oldest" ]; then
                oldest="$mtime"
            fi
        fi
    done
    
    if [ -n "$oldest" ] && [ "$oldest" != "0" ]; then
        date -d "@$oldest" "+%Y-%m-%d" 2>/dev/null || date -r "$oldest" "+%Y-%m-%d" 2>/dev/null || echo "Unknown"
    else
        echo "No notes"
    fi
}

# Get newest note date
get_newest_note_date() {
    local newest=""
    
    for note in "$NOTES_DIR"/*.md; do
        if [ -f "$note" ] && ! [[ "$note" =~ /archive/ ]] && ! [[ "$note" =~ /notebin/ ]]; then
            local mtime=$(stat -f %m "$note" 2>/dev/null || stat -c %Y "$note" 2>/dev/null || echo "0")
            if [ -z "$newest" ] || [ "$mtime" -gt "$newest" ]; then
                newest="$mtime"
            fi
        fi
    done
    
    if [ -n "$newest" ] && [ "$newest" != "0" ]; then
        date -d "@$newest" "+%Y-%m-%d" 2>/dev/null || date -r "$newest" "+%Y-%m-%d" 2>/dev/null || echo "Unknown"
    else
        echo "No notes"
    fi
}

# Format number with commas
format_number() {
    local num="$1"
    echo "$num" | awk '{printf "%'"'"'d\n", $0}'
}

# Show statistics menu with clean, minimal display
show_statistics() {
    while true; do
        clear
        local term_width=$(tput cols)
        local box_width=$((term_width - 4))
        
        echo ""
        echo -e "${CYAN}┌$(printf '%*s' $box_width '' | tr ' ' '─')┐${RESET}"
        local title="📊 NOTE STATISTICS"
        local title_len=${#title}
        local title_padding=$(( (box_width - title_len) / 2 ))
        echo -e "${CYAN}│${RESET}$(printf '%*s' $title_padding '')${BOLD}${YELLOW}${title}${RESET}$(printf '%*s' $((box_width - title_len - title_padding)) '')${CYAN}│${RESET}"
        echo -e "${CYAN}├$(printf '%*s' $box_width '' | tr ' ' '─')┤${RESET}"
        
        local total=$(get_total_notes)
        local archived=$(get_archived_count)
        local deleted=$(get_deleted_count)
        local words=$(get_total_words)
        local chars=$(get_total_chars)
        local oldest=$(get_oldest_note_date)
        local newest=$(get_newest_note_date)
        
        # Overview - clean and minimal
        echo -e "${CYAN}│${RESET} ${BOLD}Overview:${RESET}"
        echo -e "${CYAN}│${RESET}   ${CYAN}Total Notes:${RESET}   ${BOLD}${GREEN}$(format_number $total)${RESET}"
        echo -e "${CYAN}│${RESET}   ${CYAN}Archived:${RESET}      ${BOLD}${MAGENTA}$(format_number $archived)${RESET}"
        echo -e "${CYAN}│${RESET}   ${CYAN}Deleted:${RESET}       ${BOLD}${RED}$(format_number $deleted)${RESET}"
        echo -e "${CYAN}│${RESET}"
        echo -e "${CYAN}├$(printf '%*s' $box_width '' | tr ' ' '─')┤${RESET}"
        
        # Content stats
        echo -e "${CYAN}│${RESET} ${BOLD}Content:${RESET}"
        echo -e "${CYAN}│${RESET}   ${CYAN}Total Words:${RESET}   ${BOLD}${GREEN}$(format_number $words)${RESET}"
        echo -e "${CYAN}│${RESET}   ${CYAN}Total Chars:${RESET}   ${BOLD}${GREEN}$(format_number $chars)${RESET}"
        if [ $total -gt 0 ]; then
            local avg_words=$((words / total))
            echo -e "${CYAN}│${RESET}   ${CYAN}Avg/Note:${RESET}     ${BOLD}${GREEN}$(format_number $avg_words)${RESET} words"
        fi
        echo -e "${CYAN}│${RESET}"
        echo -e "${CYAN}├$(printf '%*s' $box_width '' | tr ' ' '─')┤${RESET}"
        
        # Date range
        echo -e "${CYAN}│${RESET} ${BOLD}Date Range:${RESET}"
        echo -e "${CYAN}│${RESET}   ${CYAN}Oldest:${RESET}        ${BOLD}${BLUE}$oldest${RESET}"
        echo -e "${CYAN}│${RESET}   ${CYAN}Newest:${RESET}        ${BOLD}${BLUE}$newest${RESET}"
        echo -e "${CYAN}│${RESET}"
        echo -e "${CYAN}├$(printf '%*s' $box_width '' | tr ' ' '─')┤${RESET}"
        
        # Tags - minimal preview
        echo -e "${CYAN}│${RESET} ${BOLD}Tags:${RESET}"
        local tags=$(get_all_tags)
        if [ -n "$tags" ]; then
            local tag_count=0
            local preview_count=0
            while IFS= read -r tag && [ $preview_count -lt 5 ]; do
                local count=$(get_notes_by_tag "${tag#@}")
                echo -e "${CYAN}│${RESET}   ${TAG_COLOR}$tag${RESET} ${BOLD}${GREEN}$(format_number $count)${RESET}"
                ((tag_count++))
                ((preview_count++))
            done <<< "$tags"
            if [ $tag_count -gt 5 ]; then
                local remaining=$((tag_count - 5))
                echo -e "${CYAN}│${RESET}   ${DIM}... and $remaining more${RESET}"
            fi
            echo -e "${CYAN}│${RESET}   ${CYAN}Total:${RESET} ${BOLD}${GREEN}$(format_number $tag_count)${RESET} unique tags"
        else
            echo -e "${CYAN}│${RESET}   ${DIM}No tags found${RESET}"
        fi
        
        echo -e "${CYAN}└$(printf '%*s' $box_width '' | tr ' ' '─')┘${RESET}"
        echo ""
        echo -e "${PURPLE}[ESC]${RESET} Back"
        
        key=$(get_key)
        case "$key" in
            esc) return ;;
        esac
    done
}
