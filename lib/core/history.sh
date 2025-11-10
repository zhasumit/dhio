#!/bin/bash
# Note history and undo/redo system

HISTORY_DIR="$NOTES_DIR/.history"

# Initialize history directory
init_history() {
    mkdir -p "$HISTORY_DIR"
}

# Save note version to history
# Usage: save_note_history filepath
save_note_history() {
    local filepath="$1"
    
    if [ ! -f "$filepath" ]; then
        return 1
    fi
    
    init_history
    
    local basename=$(basename "$filepath")
    local history_file="$HISTORY_DIR/${basename}.history"
    local timestamp=$(date +%s)
    local version_file="$HISTORY_DIR/${basename}.${timestamp}"
    
    # Save current version
    cp "$filepath" "$version_file"
    
    # Append to history log
    echo "$timestamp|$version_file" >> "$history_file"
    
    # Keep only last 50 versions
    tail -n 50 "$history_file" > "${history_file}.tmp"
    mv "${history_file}.tmp" "$history_file"
    
    # Clean up old versions
    local count=$(wc -l < "$history_file" 2>/dev/null || echo "0")
    if [ "$count" -gt 50 ]; then
        head -n -50 "$history_file" | cut -d'|' -f2 | xargs rm -f 2>/dev/null
        tail -n 50 "$history_file" > "${history_file}.tmp"
        mv "${history_file}.tmp" "$history_file"
    fi
}

# Get note history
# Usage: get_note_history filepath
get_note_history() {
    local filepath="$1"
    local basename=$(basename "$filepath")
    local history_file="$HISTORY_DIR/${basename}.history"
    
    if [ ! -f "$history_file" ]; then
        return 1
    fi
    
    cat "$history_file"
}

# Restore note from history
# Usage: restore_note_from_history filepath timestamp
restore_note_from_history() {
    local filepath="$1"
    local timestamp="$2"
    local basename=$(basename "$filepath")
    local version_file="$HISTORY_DIR/${basename}.${timestamp}"
    
    if [ ! -f "$version_file" ]; then
        send_notification "Notes App" "History version not found"
        return 1
    fi
    
    # Save current version before restoring
    save_note_history "$filepath"
    
    # Restore
    cp "$version_file" "$filepath"
    send_notification "Notes App" "Note restored from history"
    return 0
}

# Undo last change
# Usage: undo_note_change filepath
undo_note_change() {
    local filepath="$1"
    local basename=$(basename "$filepath")
    local history_file="$HISTORY_DIR/${basename}.history"
    
    if [ ! -f "$history_file" ]; then
        send_notification "Notes App" "No history available"
        return 1
    fi
    
    # Get second-to-last version (skip current)
    local prev_version=$(tail -n 2 "$history_file" | head -n 1 | cut -d'|' -f2)
    
    if [ -z "$prev_version" ] || [ ! -f "$prev_version" ]; then
        send_notification "Notes App" "No previous version available"
        return 1
    fi
    
    # Save current before undo
    save_note_history "$filepath"
    
    # Restore previous
    cp "$prev_version" "$filepath"
    send_notification "Notes App" "Undo successful"
    return 0
}

# Show history browser
# Usage: browse_note_history filepath
browse_note_history() {
    local filepath="$1"
    local basename=$(basename "$filepath")
    local history_file="$HISTORY_DIR/${basename}.history"
    
    if [ ! -f "$history_file" ]; then
        clear
        echo -e "${DIM}No history available for this note${RESET}\n"
        read -rsn1
        return
    fi
    
    local history_entries=()
    while IFS='|' read -r timestamp version_file; do
        [ -f "$version_file" ] && history_entries+=("$timestamp|$version_file")
    done < "$history_file"
    
    # Reverse to show newest first
    local reversed=()
    for ((i=${#history_entries[@]}-1; i>=0; i--)); do
        reversed+=("${history_entries[$i]}")
    done
    
    local selected_index=0
    
    while true; do
        clear
        echo -e "${BOLD}${CYAN}$(printf '%*s' 40 '' | tr ' ' '-')${RESET}"
        echo -e "${BOLD}${CYAN}     NOTE HISTORY${RESET}"
        echo -e "${BOLD}${CYAN}═══════════════════════════════════════${RESET}\n"
        
        if [ ${#reversed[@]} -eq 0 ]; then
            echo -e "${DIM}No history entries${RESET}\n"
        else
            (( selected_index >= ${#reversed[@]} )) && selected_index=0
            
            for i in "${!reversed[@]}"; do
                local entry="${reversed[$i]}"
                local timestamp=$(echo "$entry" | cut -d'|' -f1)
                local date_str=$(date -d "@$timestamp" "+%Y-%m-%d %H:%M:%S" 2>/dev/null || echo "$timestamp")
                
                if [ $i -eq $selected_index ]; then
                    echo -e "${BLUE}→${RESET}    ${YELLOW}[$((i+1))]${RESET} ${BOLD}${date_str}${RESET}"
                else
                    echo -e "     ${YELLOW}[$((i+1))]${RESET} ${date_str}"
                fi
            done
        fi
        
        echo ""
        echo -e "${PURPLE}[ENTER]${RESET} Restore    ${PURPLE}[U]${RESET} Undo    ${PURPLE}[ESC]${RESET} Back"
        
        key=$(get_key)
        case "$key" in
            esc) return ;;
            up)
                ((selected_index--))
                ((selected_index < 0)) && selected_index=$((${#reversed[@]} - 1))
                ;;
            down)
                ((selected_index++))
                ((selected_index >= ${#reversed[@]})) && selected_index=0
                ;;
            "")
                if [ ${#reversed[@]} -gt 0 ]; then
                    local entry="${reversed[$selected_index]}"
                    local timestamp=$(echo "$entry" | cut -d'|' -f1)
                    restore_note_from_history "$filepath" "$timestamp"
                    sleep 1
                    return
                fi
                ;;
            u|U)
                undo_note_change "$filepath"
                sleep 1
                return
                ;;
        esac
    done
}

