#!/bin/bash
# Note sorting functionality

SORT_CONFIG="$NOTES_DIR/.sort"

# Sort notes by name (ascending)
sort_by_name_asc() {
    local -n notes_ref="$1"
    local sorted=($(printf '%s\n' "${notes_ref[@]}" | sort))
    notes_ref=("${sorted[@]}")
}

# Sort notes by name (descending)
sort_by_name_desc() {
    local -n notes_ref="$1"
    local sorted=($(printf '%s\n' "${notes_ref[@]}" | sort -r))
    notes_ref=("${sorted[@]}")
}

# Sort notes by modification date (ascending - oldest first)
sort_by_date_modified_asc() {
    local -n notes_ref="$1"
    local sorted=()
    
    # Create array of timestamp|filepath
    local timestamps=()
    for note in "${notes_ref[@]}"; do
        local mtime=$(stat -f %m "$note" 2>/dev/null || stat -c %Y "$note" 2>/dev/null || echo "0")
        timestamps+=("${mtime}|${note}")
    done
    
    # Sort by timestamp
    IFS=$'\n' sorted_timestamps=($(printf '%s\n' "${timestamps[@]}" | sort -t'|' -k1 -n))
    
    # Extract filepaths
    for entry in "${sorted_timestamps[@]}"; do
        sorted+=("${entry#*|}")
    done
    
    notes_ref=("${sorted[@]}")
}

# Sort notes by modification date (descending - newest first)
sort_by_date_modified_desc() {
    local -n notes_ref="$1"
    local sorted=()
    
    local timestamps=()
    for note in "${notes_ref[@]}"; do
        local mtime=$(stat -f %m "$note" 2>/dev/null || stat -c %Y "$note" 2>/dev/null || echo "0")
        timestamps+=("${mtime}|${note}")
    done
    
    IFS=$'\n' sorted_timestamps=($(printf '%s\n' "${timestamps[@]}" | sort -t'|' -k1 -rn))
    
    for entry in "${sorted_timestamps[@]}"; do
        sorted+=("${entry#*|}")
    done
    
    notes_ref=("${sorted[@]}")
}

# Sort notes by creation date (ascending)
sort_by_date_created_asc() {
    local -n notes_ref="$1"
    # Use birthtime if available, otherwise fallback to mtime
    local sorted=()
    local timestamps=()
    
    for note in "${notes_ref[@]}"; do
        # Try to get birthtime (creation time)
        local btime=$(stat -f %B "$note" 2>/dev/null || stat -c %W "$note" 2>/dev/null || stat -c %Y "$note" 2>/dev/null || echo "0")
        timestamps+=("${btime}|${note}")
    done
    
    IFS=$'\n' sorted_timestamps=($(printf '%s\n' "${timestamps[@]}" | sort -t'|' -k1 -n))
    
    for entry in "${sorted_timestamps[@]}"; do
        sorted+=("${entry#*|}")
    done
    
    notes_ref=("${sorted[@]}")
}

# Sort notes by creation date (descending)
sort_by_date_created_desc() {
    local -n notes_ref="$1"
    local sorted=()
    local timestamps=()
    
    for note in "${notes_ref[@]}"; do
        local btime=$(stat -f %B "$note" 2>/dev/null || stat -c %W "$note" 2>/dev/null || stat -c %Y "$note" 2>/dev/null || echo "0")
        timestamps+=("${btime}|${note}")
    done
    
    IFS=$'\n' sorted_timestamps=($(printf '%s\n' "${timestamps[@]}" | sort -t'|' -k1 -rn))
    
    for entry in "${sorted_timestamps[@]}"; do
        sorted+=("${entry#*|}")
    done
    
    notes_ref=("${sorted[@]}")
}

# Sort notes by size (ascending)
sort_by_size_asc() {
    local -n notes_ref="$1"
    local sorted=()
    local sizes=()
    
    for note in "${notes_ref[@]}"; do
        local size=$(stat -f %z "$note" 2>/dev/null || stat -c %s "$note" 2>/dev/null || echo "0")
        sizes+=("${size}|${note}")
    done
    
    IFS=$'\n' sorted_sizes=($(printf '%s\n' "${sizes[@]}" | sort -t'|' -k1 -n))
    
    for entry in "${sorted_sizes[@]}"; do
        sorted+=("${entry#*|}")
    done
    
    notes_ref=("${sorted[@]}")
}

# Sort notes by size (descending)
sort_by_size_desc() {
    local -n notes_ref="$1"
    local sorted=()
    local sizes=()
    
    for note in "${notes_ref[@]}"; do
        local size=$(stat -f %z "$note" 2>/dev/null || stat -c %s "$note" 2>/dev/null || echo "0")
        sizes+=("${size}|${note}")
    done
    
    IFS=$'\n' sorted_sizes=($(printf '%s\n' "${sizes[@]}" | sort -t'|' -k1 -rn))
    
    for entry in "${sorted_sizes[@]}"; do
        sorted+=("${entry#*|}")
    done
    
    notes_ref=("${sorted[@]}")
}

# Apply sorting to notes array
# Usage: apply_sorting notes_array[@] sort_type sort_order
apply_sorting() {
    local notes_name="$1[@]"
    local notes_ref=("${!notes_name}")
    local sort_type="${2:-date_modified}"
    local sort_order="${3:-desc}"
    
    case "${sort_type}_${sort_order}" in
        name_asc) sort_by_name_asc notes_ref ;;
        name_desc) sort_by_name_desc notes_ref ;;
        date_modified_asc) sort_by_date_modified_asc notes_ref ;;
        date_modified_desc) sort_by_date_modified_desc notes_ref ;;
        date_created_asc) sort_by_date_created_asc notes_ref ;;
        date_created_desc) sort_by_date_created_desc notes_ref ;;
        size_asc) sort_by_size_asc notes_ref ;;
        size_desc) sort_by_size_desc notes_ref ;;
        *) sort_by_date_modified_desc notes_ref ;; # Default
    esac
    
    # Update the original array
    eval "$1=(\"\${notes_ref[@]}\")"
    
    # Save sort preference
    echo "${sort_type}|${sort_order}" > "$SORT_CONFIG"
}

# Get current sort preference
get_sort_preference() {
    if [ -f "$SORT_CONFIG" ]; then
        cat "$SORT_CONFIG"
    else
        echo "date_modified|desc"
    fi
}

# Sorting menu
sorting_menu() {
    local sort_options=(
        "name_asc:Name (A-Z)"
        "name_desc:Name (Z-A)"
        "date_modified_desc:Date Modified (Newest First)"
        "date_modified_asc:Date Modified (Oldest First)"
        "date_created_desc:Date Created (Newest First)"
        "date_created_asc:Date Created (Oldest First)"
        "size_desc:Size (Largest First)"
        "size_asc:Size (Smallest First)"
    )
    
    local selected_index=0
    local current_sort=$(get_sort_preference)
    local current_type=$(echo "$current_sort" | cut -d'|' -f1)
    local current_order=$(echo "$current_sort" | cut -d'|' -f2)
    local current_display="${current_type}_${current_order}"
    
    # Find current selection
    for i in "${!sort_options[@]}"; do
        if [[ "${sort_options[$i]}" == "$current_display:"* ]]; then
            selected_index=$i
            break
        fi
    done
    
    while true; do
        clear
        echo -e "${BOLD}${CYAN}═══════════════════════════════════════${RESET}"
        echo -e "${BOLD}${CYAN}     SORT NOTES${RESET}"
        echo -e "${BOLD}${CYAN}═══════════════════════════════════════${RESET}\n"
        
        for i in "${!sort_options[@]}"; do
            local option="${sort_options[$i]}"
            local label="${option#*:}"
            
            if [ $i -eq $selected_index ]; then
                echo -e "${BLUE}→${RESET}    ${YELLOW}[$((i+1))]${RESET} ${BOLD}${label}${RESET}"
            else
                echo -e "     ${YELLOW}[$((i+1))]${RESET} ${label}"
            fi
        done
        
        echo ""
        echo -e "${PURPLE}[ENTER]${RESET} Apply    ${PURPLE}[ESC]${RESET} Cancel"
        
        key=$(get_key)
        case "$key" in
            esc) return ;;
            up)
                ((selected_index--))
                ((selected_index < 0)) && selected_index=$((${#sort_options[@]} - 1))
                ;;
            down)
                ((selected_index++))
                ((selected_index >= ${#sort_options[@]})) && selected_index=0
                ;;
            "")
                if [ ${#sort_options[@]} -gt 0 ]; then
                    local selected="${sort_options[$selected_index]}"
                    local sort_key="${selected%%:*}"
                    local sort_type="${sort_key%_*}"
                    local sort_order="${sort_key#*_}"
                    
                    # This will be applied when list_notes is called
                    echo "${sort_type}|${sort_order}" > "$SORT_CONFIG"
                    send_notification "Notes App" "Sort order changed"
                    sleep 1
                    return
                fi
                ;;
            [1-8])
                local num=$key
                local index=$((num - 1))
                if [ $index -ge 0 ] && [ $index -lt ${#sort_options[@]} ]; then
                    local selected="${sort_options[$index]}"
                    local sort_key="${selected%%:*}"
                    local sort_type="${sort_key%_*}"
                    local sort_order="${sort_key#*_}"
                    echo "${sort_type}|${sort_order}" > "$SORT_CONFIG"
                    send_notification "Notes App" "Sort order changed"
                    sleep 1
                    return
                fi
                ;;
        esac
    done
}

