#!/bin/bash
# Note statistics module
#
# Purpose:
# - Compute and display a concise summary of the notes collection (total, archived, deleted,
#   average words per note, and date range).
# - Provide a compact tags summary showing the top tags and counts.
#
# Public functions:
# - show_statistics: interactive menu entry that prints the summary and tags
# - get_total_notes, get_archived_count, get_deleted_count: small helpers used elsewhere


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

# Show statistics menu with tables for tags
show_statistics() {
    while true; do
        clear
        local term_width=$(tput cols)
        local box_width=$((term_width - 4))
        
        echo ""
        echo -e "${CYAN}$(printf '%*s' $box_width '' | tr ' ' '-')${RESET}"
        local title="📊 NOTE STATISTICS"
        local title_len=${#title}
        local title_padding=$(( (box_width - title_len) / 2 ))
        echo -e "$(printf '%*s' $title_padding '')${BOLD}${YELLOW}${title}${RESET}"
        echo -e "${CYAN}$(printf '%*s' $box_width '' | tr ' ' '-')${RESET}"
        
        local total=$(get_total_notes)
        local archived=$(get_archived_count)
        local deleted=$(get_deleted_count)
    local words=$(get_total_words)
        local chars=$(get_total_chars)
        local oldest=$(get_oldest_note_date)
        local newest=$(get_newest_note_date)
        
        # Summary
        # Minimal summary (only the essential info)
        echo ""
        echo -e "  ${BOLD}Total Notes:${RESET}   ${GREEN}$(format_number $total)${RESET}"
        echo -e "  ${BOLD}Archived:${RESET}      ${MAGENTA}$(format_number $archived)${RESET}"
        echo -e "  ${BOLD}Deleted:${RESET}       ${RED}$(format_number $deleted)${RESET}"
        if [ $total -gt 0 ]; then
            local avg_words=$((words / total))
            echo -e "  ${BOLD}Avg Words/Note:${RESET} ${GREEN}$(format_number $avg_words)${RESET}"
        fi
        echo -e "  ${BOLD}Date Range:${RESET}   ${BLUE}$oldest${RESET} to ${BLUE}$newest${RESET}"
        echo ""

        # Tags: print count on the LEFT, tag on the right; only show top 5, then total unique tags
        local tags=$(get_all_tags)
        if [ -n "$tags" ]; then
            # Build a list of "count<TAB>tag"
            local tmp_list
            tmp_list=$(mktemp)
            while IFS= read -r tag; do
                local count=$(get_notes_by_tag "${tag#@}")
                printf "%d\t%s\n" "$count" "$tag" >> "$tmp_list"
            done <<< "$tags"

            # Header: Count left, Tag right
            echo -e "  ${BOLD}Tags:${RESET}"
            printf "  %5s  %s\n" "Count" "Tag"
            echo -e "  ${CYAN}$(printf '%*s' 40 '' | tr ' ' '-')${RESET}"

            # Print top 5 with count on left
            sort -nr "$tmp_list" | head -n 5 | while IFS=$'\t' read -r cnt tg; do
                printf "  ${GREEN}%5s${RESET}  %s\n" "$(format_number $cnt)" "${TAG_COLOR}$tg${RESET}"
            done

            local total_tags=$(wc -l < "$tmp_list" | tr -d ' ')
            echo ""
            echo -e "  ${BOLD}Total Tags Found:${RESET} ${GREEN}$(format_number $total_tags)${RESET}"
            rm -f "$tmp_list"
        else
            echo -e "  ${DIM}No tags found${RESET}"
        fi
        
        echo ""
        echo -e "${CYAN}$(printf '%*s' $box_width '' | tr ' ' '-')${RESET}"
        echo ""
        echo -e "${PURPLE}[ESC]${RESET} Back"
        
        key=$(get_key)
        case "$key" in
            esc) return ;;
        esac
    done
}
