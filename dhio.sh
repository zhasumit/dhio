#!/bin/bash

# Terminal Notes App with Markdown Preview
# A bash-based note-taking application with live markdown rendering

NOTES_DIR="$HOME/Documents/.dhio"
NOTEBIN_DIR="$NOTES_DIR/notebin"
TEMP_FILE="$NOTES_DIR/.temp_note"
CODE_TEMP="$NOTES_DIR/.temp_code"

# Colors - Tokyo Night theme
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
BOLD='\033[1m'
DIM='\033[2m'
STRIKETHROUGH='\033[9m'
PURPLE='\033[38;5;141m'  # Tokyo Night purple
DARK_PURPLE='\033[38;5;98m'
GRAY='\033[38;5;240m'
RESET='\033[0m'

# Current state
CURRENT_VIEW="main"
CURRENT_NOTE=""

# Initialize notes directory
init_notes_dir() {
    mkdir -p "$NOTES_DIR"
    mkdir -p "$NOTEBIN_DIR"
}

# Send notification
send_notification() {
    local title="$1"
    local message="$2"

    if command -v notify-send &> /dev/null; then
        notify-send "$title" "$message"
    fi
}

# Draw footer menu
draw_footer() {
    local context="$1"
    local term_width=$(tput cols)

    printf "\n${PURPLE}%${term_width}s${RESET}\n" | tr ' ' '-'

    case "$context" in
        main)
            local items=("${PURPLE}[N]${RESET} New" "${PURPLE}[D]${RESET} Delete" "${PURPLE}[R]${RESET} Restore" "${PURPLE}[/]${RESET} Search" "${PURPLE}[ESC]${RESET} Exit")
            ;;
        preview)
            local items=("${PURPLE}[E]${RESET} Edit" "${PURPLE}[D]${RESET} Delete" "${PURPLE}[C1-9]${RESET} Copy code" "${PURPLE}[ESC]${RESET} Back")
            ;;
        search)
            local items=("${PURPLE}Type${RESET} to filter" "${PURPLE}[↑↓]${RESET} Navigate" "${PURPLE}[ENTER]${RESET} Open" "${PURPLE}[ESC]${RESET} Cancel")
            ;;
        delete)
            local items=("${PURPLE}[Y]${RESET} Yes" "${PURPLE}[N]${RESET} No" "${PURPLE}[ESC]${RESET} Cancel")
            ;;
        notebin)
            local items=("${PURPLE}[SPACE]${RESET} Select" "${PURPLE}[↑↓]${RESET} Navigate" "${PURPLE}[R]${RESET} Restore" "${PURPLE}[D]${RESET} Delete" "${PURPLE}[X]${RESET} Purge All" "${PURPLE}[ESC]${RESET} Back")
            ;;
    esac

    # Calculate spacing
    local num_items=${#items[@]}
    local item_lengths=0
    for item in "${items[@]}"; do
        # Strip ANSI codes for length calculation
        local plain=$(echo -e "$item" | sed 's/\x1b\[[0-9;]*m//g')
        item_lengths=$((item_lengths + ${#plain}))
    done

    local total_spacing=$((term_width - item_lengths))
    local spacing=$((total_spacing / (num_items + 1)))

    # Print items with equal spacing
    printf "%${spacing}s" ""
    for i in "${!items[@]}"; do
        printf "%b" "${items[$i]}"
        if [ $i -lt $((num_items - 1)) ]; then
            printf "%${spacing}s" ""
        fi
    done
    echo ""

    printf "${PURPLE}%${term_width}s${RESET}\n" | tr ' ' '-'
}

# Get single key press
get_key() {
    local key
    IFS= read -rsn1 key 2>/dev/null

    # Handle escape sequences
    if [[ $key == $'\x1b' ]]; then
        read -rsn2 -t 0.1 key2
        if [[ $key2 == "[A" ]]; then echo "up"
        elif [[ $key2 == "[B" ]]; then echo "down"
        elif [[ $key2 == "[C" ]]; then echo "right"
        elif [[ $key2 == "[D" ]]; then echo "left"
        else echo "esc"
        fi
    else
        echo "$key"
    fi
}

# Copy code block to clipboard
copy_code_block() {
    local code_content="$1"

    if command -v xclip &> /dev/null; then
        echo -n "$code_content" | xclip -selection clipboard
        return 0
    elif command -v xsel &> /dev/null; then
        echo -n "$code_content" | xsel --clipboard
        return 0
    elif command -v pbcopy &> /dev/null; then
        echo -n "$code_content" | pbcopy
        return 0
    elif command -v clip.exe &> /dev/null; then
        echo -n "$code_content" | clip.exe
        return 0
    else
        echo "$code_content" > "$CODE_TEMP"
        return 1
    fi
}

# Process inline markdown formatting with tag support
process_inline() {
    local line="$1"
    local result=""
    local i=0

    # Handle <br> tags first
    line="${line//<br>/$'\n'}"
    line="${line//<br\/>/$'\n'}"
    line="${line//<BR>/$'\n'}"
    line="${line//<BR\/>/$'\n'}"

    local len=${#line}

    while [ $i -lt $len ]; do
        local char="${line:$i:1}"
        local next="${line:$i+1:1}"
        local next2="${line:$i+2:1}"

        # Check for @tags (e.g., @tagname)
        if [ "$char" = "@" ]; then
            local end_pos=$((i+1))
            local found_end=false
            # Match alphanumeric, hyphens, and underscores
            while [ $end_pos -lt $len ]; do
                local test_char="${line:$end_pos:1}"
                if [[ "$test_char" =~ [a-zA-Z0-9_-] ]]; then
                    ((end_pos++))
                else
                    found_end=true
                    break
                fi
            done

            if [ $end_pos -gt $((i+1)) ]; then
                local tag_content="${line:$i:$((end_pos-i))}"
                result="${result}${YELLOW}${tag_content}${RESET}"
                i=$end_pos
                continue
            else
                result="${result}${char}"
                ((i++))
                continue
            fi
        fi

        # Check for ***text*** (bold italic)
        if [ "$char" = "*" ] && [ "$next" = "*" ] && [ "$next2" = "*" ]; then
            local end_pos=$((i+3))
            local found_end=false
            while [ $end_pos -lt $((len-2)) ]; do
                if [ "${line:$end_pos:3}" = "***" ]; then
                    local content="${line:$((i+3)):$((end_pos-i-3))}"
                    result="${result}${BOLD}${YELLOW}${content}${RESET}"
                    i=$((end_pos+3))
                    found_end=true
                    break
                fi
                ((end_pos++))
            done
            if [ "$found_end" = false ]; then
                result="${result}${char}"
                ((i++))
            fi
        # Check for **text** (bold)
        elif [ "$char" = "*" ] && [ "$next" = "*" ]; then
            local end_pos=$((i+2))
            local found_end=false
            while [ $end_pos -lt $((len-1)) ]; do
                if [ "${line:$end_pos:2}" = "**" ]; then
                    local content="${line:$((i+2)):$((end_pos-i-2))}"
                    result="${result}${BOLD}${content}${RESET}"
                    i=$((end_pos+2))
                    found_end=true
                    break
                fi
                ((end_pos++))
            done
            if [ "$found_end" = false ]; then
                result="${result}${char}"
                ((i++))
            fi
        # Check for *text* (italic)
        elif [ "$char" = "*" ]; then
            local end_pos=$((i+1))
            local found_end=false
            while [ $end_pos -lt $len ]; do
                if [ "${line:$end_pos:1}" = "*" ] && [ "${line:$((end_pos-1)):1}" != "\\" ]; then
                    local content="${line:$((i+1)):$((end_pos-i-1))}"
                    result="${result}${DIM}${content}${RESET}"
                    i=$((end_pos+1))
                    found_end=true
                    break
                fi
                ((end_pos++))
            done
            if [ "$found_end" = false ]; then
                result="${result}${char}"
                ((i++))
            fi
        # Check for `code` (inline code)
        elif [ "$char" = "\`" ]; then
            local end_pos=$((i+1))
            local found_end=false
            while [ $end_pos -lt $len ]; do
                if [ "${line:$end_pos:1}" = "\`" ]; then
                    local content="${line:$((i+1)):$((end_pos-i-1))}"
                    result="${result}${GREEN}${content}${RESET}"
                    i=$((end_pos+1))
                    found_end=true
                    break
                fi
                ((end_pos++))
            done
            if [ "$found_end" = false ]; then
                result="${result}${char}"
                ((i++))
            fi
        else
            result="${result}${char}"
            ((i++))
        fi
    done

    echo -e "$result"
}

# Render markdown to terminal
render_markdown() {
    local content="$1"
    local in_code_block=false
    local code_lang=""
    local code_content=""
    local code_block_num=0

    echo -e "\n${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}\n"

    while IFS= read -r line; do
        # Code blocks
        if [[ "$line" =~ ^\`\`\`(.*)$ ]]; then
            if [ "$in_code_block" = false ]; then
                in_code_block=true
                code_lang="${BASH_REMATCH[1]}"
                code_content=""
                ((code_block_num++))
                echo -e "${PURPLE}╭─────────────────────────────────────────────────────────╮${RESET}"
                echo -e "${PURPLE}│${RESET} ${BOLD}Code Block${code_lang:+ - $code_lang}${RESET} ${PURPLE}│${RESET}"
                echo -e "${PURPLE}╰─────────────────────────────────────────────────────────╯${RESET}"
            else
                in_code_block=false
                echo -e "${DARK_PURPLE}└─────────────────────────────────────────────────────────┘${RESET}"

                # Save code content for potential copying
                echo -n "$code_content" > "$NOTES_DIR/.code_block_${code_block_num}"
                echo ""
            fi
            continue
        fi

        if [ "$in_code_block" = true ]; then
            code_content="${code_content}${line}"$'\n'
            echo -e "${GREEN}│${RESET} $line"
            continue
        fi

        # Todo items - [] or [x] or [X]
        if [[ "$line" =~ ^\[([[:space:]xX]?)\][[:space:]](.+)$ ]]; then
            local checkbox="${BASH_REMATCH[1]}"
            local todo_text="${BASH_REMATCH[2]}"
            local formatted_todo=$(process_inline "$todo_text")

            if [[ "$checkbox" =~ [xX] ]]; then
                # Completed todo - double checkmark and strikethrough
                echo -e "  ${GREEN}✓✓${RESET} ${STRIKETHROUGH}${DIM}$formatted_todo${RESET}"
            else
                # Uncompleted todo - bigger box
                echo -e "  ${GRAY}☐${RESET}  $formatted_todo"
            fi
            continue
        fi

        # Headers - simple style
        if [[ "$line" =~ ^######[[:space:]](.+)$ ]]; then
            local content="${BASH_REMATCH[1]}"
            local formatted=$(process_inline "$content")
            echo -e "${MAGENTA}${formatted}${RESET}"
        elif [[ "$line" =~ ^#####[[:space:]](.+)$ ]]; then
            local content="${BASH_REMATCH[1]}"
            local formatted=$(process_inline "$content")
            echo -e "${MAGENTA}${BOLD}• ${formatted}${RESET}"
        elif [[ "$line" =~ ^####[[:space:]](.+)$ ]]; then
            local content="${BASH_REMATCH[1]}"
            local formatted=$(process_inline "$content")
            echo -e "${BLUE}▸ ${formatted}${RESET}"
        elif [[ "$line" =~ ^###[[:space:]](.+)$ ]]; then
            local content="${BASH_REMATCH[1]}"
            local formatted=$(process_inline "$content")
            echo -e "${BLUE}${BOLD}═══ ${formatted} ═══${RESET}"
        elif [[ "$line" =~ ^##[[:space:]](.+)$ ]]; then
            local content="${BASH_REMATCH[1]}"
            local formatted=$(process_inline "$content")
            echo -e "${CYAN}${BOLD}▋▋ ${formatted} ▋▋${RESET}"
        elif [[ "$line" =~ ^#[[:space:]](.+)$ ]]; then
            local content="${BASH_REMATCH[1]}"
            local formatted=$(process_inline "$content")
            echo -e "${WHITE}${BOLD}█ ${formatted} █${RESET}"
        # Horizontal rule
        elif [[ "$line" =~ ^(---|\*\*\*|___)$ ]]; then
            echo -e "${DIM}────────────────────────────────────────────────────${RESET}"
        # Lists
        elif [[ "$line" =~ ^[[:space:]]*[-*+][[:space:]](.+)$ ]]; then
            local content="${BASH_REMATCH[1]}"
            local formatted=$(process_inline "$content")
            echo -e "  ${YELLOW}•${RESET} $formatted"
        elif [[ "$line" =~ ^[[:space:]]*[0-9]+\.[[:space:]](.+)$ ]]; then
            local content="${BASH_REMATCH[1]}"
            local formatted=$(process_inline "$content")
            echo -e "  ${YELLOW}▸${RESET} $formatted"
        # Block quotes
        elif [[ "$line" =~ ^\>[[:space:]](.+)$ ]]; then
            local content="${BASH_REMATCH[1]}"
            local formatted=$(process_inline "$content")
            echo -e "${DIM}┃${RESET} $formatted"
        else
            # Regular text with inline formatting
            if [ -n "$line" ]; then
                local formatted=$(process_inline "$line")
                echo -e "$formatted"
            else
                echo ""
            fi
        fi
    done <<< "$content"

    echo -e "\n${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
}

# Create a new note
create_note() {
    clear
    echo -e "${BOLD}${CYAN}═══════════════════════════════════════${RESET}"
    echo -e "${BOLD}${CYAN}     CREATE NEW NOTE${RESET}"
    echo -e "${BOLD}${CYAN}═══════════════════════════════════════${RESET}\n"

    echo -e "${YELLOW}Enter note heading:${RESET}"
    read -r heading

    if [ -z "$heading" ]; then
        send_notification "Notes App" "Note creation cancelled"
        sleep 1
        return
    fi

    # Sanitize filename
    filename=$(echo "$heading" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9]/-/g' | sed 's/--*/-/g' | sed 's/^-//' | sed 's/-$//')
    filepath="$NOTES_DIR/${filename}.md"

    # Check if file exists
    if [ -f "$filepath" ]; then
        send_notification "Notes App" "A note with this heading already exists"
        sleep 1
        return
    fi

    # Create temp file with heading
    echo "# $heading" > "$TEMP_FILE"
    echo "" >> "$TEMP_FILE"
    echo "Write your note here..." >> "$TEMP_FILE"
    echo "" >> "$TEMP_FILE"
    echo "Use @tags to organize your notes (e.g., @urgent @work @personal)" >> "$TEMP_FILE"

    # Open in default editor
    ${EDITOR:-nano} "$TEMP_FILE"

    # Save the note
    if [ -f "$TEMP_FILE" ]; then
        cp "$TEMP_FILE" "$filepath"
        rm "$TEMP_FILE"
        send_notification "Notes App" "Note created: $heading"

        # Auto-preview the note
        CURRENT_NOTE="$filepath"
        preview_note "$filepath"
    fi
}

# Format note line with justified layout
format_note_line() {
    local num="$1"
    local heading="$2"
    local date="$3"
    local selected="$4"
    local term_width=$(tput cols)

    # Calculate available width for heading (leaving space for number, date, and padding)
    local num_part="${YELLOW}[$num]${RESET} ${BOLD}"
    local date_part="${RESET}${DIM}$date${RESET}"

    # Selection indicator
    local select_indicator=""
    if [ "$selected" = "true" ]; then
        select_indicator="${GREEN}[✓]${RESET} "
    else
        select_indicator="${GRAY}[ ]${RESET} "
    fi

    # Strip color codes for length calculation
    local num_len=$((${#num} + 3))  # [X]
    local date_len=${#date}
    local select_len=4  # [ ] or [✓]
    local available_width=$((term_width - num_len - date_len - select_len - 3))

    # Truncate heading if too long
    local display_heading="$heading"
    if [ ${#heading} -gt $available_width ]; then
        display_heading="${heading:0:$((available_width - 3))}..."
    fi

    # Calculate padding
    local padding_len=$((term_width - num_len - select_len - ${#display_heading} - date_len - 3))
    local padding=$(printf '%*s' "$padding_len" '')

    echo -e "${select_indicator}${YELLOW}[$num]${RESET} ${BOLD}${display_heading}${RESET}${padding}${DIM}$date${RESET}"
}

# Center text in terminal
center_text() {
    local text="$1"
    local term_width=$(tput cols)
    local text_length=${#text}
    local padding=$(( (term_width - text_length) / 2 ))
    printf "%${padding}s%s\n" "" "$text"
}

# List all notes
list_notes() {
    clear
    echo ""
    center_text "✎ᝰ Dhio notes appˎˊ˗"
    echo ""

    local notes=("$NOTES_DIR"/*.md)

    if [ ! -e "${notes[0]}" ]; then
        echo -e "${DIM}No notes found. Press 'n' to create your first note!${RESET}\n"
        draw_footer "main"

        while true; do
            key=$(get_key)
            case "$key" in
                n|N)
                    create_note
                    return
                    ;;
                r|R)
                    notebin_menu
                    return
                    ;;
                /)
                    search_notes_fuzzy
                    return
                    ;;
                esc)
                    exit 0
                    ;;
            esac
        done
        return
    fi

    local count=1
    declare -a note_array
    for note in "${notes[@]}"; do
        if [ -f "$note" ]; then
            note_array+=("$note")
            local heading=$(head -n 1 "$note" | sed 's/^#* *//')
            local date=$(date -r "$note" "+%Y-%m-%d %H:%M")

            format_note_line "$count" "$heading" "$date" "false"
            ((count++))
        fi
    done

    draw_footer "main"

    # Handle key input
    while true; do
        key=$(get_key)
        case "$key" in
            n|N)
                create_note
                return
                ;;
            d|D)
                delete_note_interactive "${note_array[@]}"
                return
                ;;
            r|R)
                notebin_menu
                return
                ;;
            /)
                search_notes_fuzzy "${note_array[@]}"
                return
                ;;
            esc)
                exit 0
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

# Notebin menu - show deleted notes with restore capability
notebin_menu() {
    local deleted_notes=("$NOTEBIN_DIR"/*.md)

    if [ ! -e "${deleted_notes[0]}" ]; then
        clear
        echo ""
        center_text "🗑️ Note Bin"
        echo ""
        echo -e "${DIM}No deleted notes found.${RESET}\n"
        echo -e "${GRAY}Press any key to go back...${RESET}"
        read -rsn1
        return
    fi

    declare -A selected_notes
    local current_index=0

    while true; do
        clear
        echo ""
        center_text "🗑️ Note Bin"
        echo ""

        # Rebuild note array on each iteration to handle deletions
        deleted_notes=("$NOTEBIN_DIR"/*.md)

        # Check if notebin is now empty
        if [ ! -e "${deleted_notes[0]}" ]; then
            echo -e "${DIM}No deleted notes found.${RESET}\n"
            echo -e "${GRAY}Press any key to go back...${RESET}"
            read -rsn1
            return
        fi

        local count=0
        declare -a note_array
        for note in "${deleted_notes[@]}"; do
            if [ -f "$note" ]; then
                note_array+=("$note")
                local heading=$(head -n 1 "$note" | sed 's/^#* *//')
                local date=$(date -r "$note" "+%Y-%m-%d %H:%M")

                local is_selected="false"
                [ "${selected_notes[$note]}" = "true" ] && is_selected="true"

                if [ $count -eq $current_index ]; then
                    echo -e "${BLUE}→${RESET} $(format_note_line $((count+1)) "$heading" "$date" "$is_selected")"
                else
                    echo -e "  $(format_note_line $((count+1)) "$heading" "$date" "$is_selected")"
                fi
                ((count++))
            fi
        done

        # Adjust current_index if it's out of bounds
        if [ $current_index -ge ${#note_array[@]} ] && [ ${#note_array[@]} -gt 0 ]; then
            current_index=$((${#note_array[@]} - 1))
        fi

        # Count selected notes
        local selected_count=0
        for note in "${!selected_notes[@]}"; do
            [ "${selected_notes[$note]}" = "true" ] && ((selected_count++))
        done

        if [ $selected_count -gt 0 ]; then
            echo -e "\n${CYAN}Selected: ${selected_count} note(s)${RESET}"
        fi

        draw_footer "notebin"

        key=$(get_key)
        case "$key" in
            up)
                ((current_index--))
                [ $current_index -lt 0 ] && current_index=$((${#note_array[@]} - 1))
                ;;
            down)
                ((current_index++))
                [ $current_index -ge ${#note_array[@]} ] && current_index=0
                ;;
            " ")
                # Toggle selection
                local current_note="${note_array[$current_index]}"
                if [ "${selected_notes[$current_note]}" = "true" ]; then
                    selected_notes[$current_note]="false"
                else
                    selected_notes[$current_note]="true"
                fi
                ;;
            r|R)
                # Restore selected notes
                local restore_count=0
                for note in "${!selected_notes[@]}"; do
                    if [ "${selected_notes[$note]}" = "true" ] && [ -f "$note" ]; then
                        local basename=$(basename "$note")
                        mv "$note" "$NOTES_DIR/$basename"
                        ((restore_count++))
                        unset selected_notes[$note]
                    fi
                done

                if [ $restore_count -gt 0 ]; then
                    send_notification "Notes App" "$restore_count note(s) restored"
                    sleep 1
                else
                    send_notification "Notes App" "No notes selected to restore"
                    sleep 1
                fi
                ;;
            d|D)
                # Permanently delete selected notes
                local delete_count=0
                for note in "${!selected_notes[@]}"; do
                    if [ "${selected_notes[$note]}" = "true" ]; then
                        ((delete_count++))
                    fi
                done

                if [ $delete_count -gt 0 ]; then
                    clear
                    echo -e "${RED}${BOLD}═══════════════════════════════════════${RESET}"
                    echo -e "${RED}${BOLD}     PERMANENT DELETION${RESET}"
                    echo -e "${RED}${BOLD}═══════════════════════════════════════${RESET}\n"
                    echo -e "${RED}${BOLD}WARNING: This will permanently delete $delete_count note(s)!${RESET}"
                    echo -e "${RED}This action CANNOT be undone!${RESET}\n"
                    echo -e "${YELLOW}[Y]${RESET} Yes, delete permanently"
                    echo -e "${YELLOW}[N]${RESET} No, cancel\n"

                    while true; do
                        del_key=$(get_key)
                        case "$del_key" in
                            y|Y)
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
                                break
                                ;;
                            n|N|esc)
                                break
                                ;;
                        esac
                    done
                else
                    send_notification "Notes App" "No notes selected to delete"
                    sleep 1
                fi
                ;;
            x|X)
                # Purge all notes in notebin
                clear
                echo -e "${RED}${BOLD}═══════════════════════════════════════${RESET}"
                echo -e "${RED}${BOLD}     PURGE ALL NOTES${RESET}"
                echo -e "${RED}${BOLD}═══════════════════════════════════════${RESET}\n"
                echo -e "${RED}${BOLD}WARNING: Permanently delete ALL notes in the bin?${RESET}"
                echo -e "${RED}This action CANNOT be undone!${RESET}\n"
                echo -e "${YELLOW}[Y]${RESET} Yes, purge all"
                echo -e "${YELLOW}[N]${RESET} No, cancel\n"

                while true; do
                    purge_key=$(get_key)
                    case "$purge_key" in
                        y|Y)
                            rm -f "$NOTEBIN_DIR"/*.md
                            send_notification "Notes App" "All notes permanently deleted from bin"
                            sleep 1
                            return
                            ;;
                        n|N|esc)
                            break
                            ;;
                    esac
                done
                ;;
            esc)
                return
                ;;
        esac
    done
}

# Fuzzy search notes
search_notes_fuzzy() {
    local notes=("$@")
    local search_term=""
    local selected_index=0

    while true; do
        clear
        # Header banner
        echo -e "${BOLD}${CYAN}═══════════════════════════════════════${RESET}"
        echo -e "${BOLD}${CYAN}     FUZZY SEARCH${RESET}"
        echo -e "${BOLD}${CYAN}═══════════════════════════════════════${RESET}\n"
        # Search input line
        echo -e "${BOLD}${CYAN}Search:${RESET} ${YELLOW}${search_term}${RESET}\n"

        # Build filtered list
        local filtered_notes=()
        for n in "${notes[@]}"; do
            if [ -f "$n" ]; then
                if [ -z "$search_term" ]; then
                    filtered_notes+=("$n")
	            else
                    if grep -iq -- "$search_term" "$n" 2>/dev/null; then
                        filtered_notes+=("$n")
                    fi
                fi
            fi
        done

        # Ensure selected_index is within bounds
        if [ ${#filtered_notes[@]} -eq 0 ]; then
            echo -e "${DIM}No matches${RESET}\n"
        else
            (( selected_index >= ${#filtered_notes[@]} )) && selected_index=0
            local idx=0
            for note in "${filtered_notes[@]}"; do
                local title
                title=$(head -n 1 "$note" | sed 's/^#* *//')
                # Selection indicator
                if [ $idx -eq $selected_index ]; then
                    echo -e "${BLUE}[x]${RESET} ${BOLD}$title${RESET}"
                else
                    echo -e "${BLUE}[ ]${RESET} ${BOLD}$title${RESET}"
                fi

                # Grab one matching line from file
                local match_line=""
                if [ -n "$search_term" ]; then
                    match_line=$(grep -i -m 1 -- "$search_term" "$note" 2>/dev/null || true)
                fi

                if [ -n "$match_line" ]; then
                    match_line="${match_line#"${match_line%%[![:space:]]*}"}"
                    local term_width
                    term_width=$(tput cols)
                    local preview="${match_line:0:$((term_width-6))}"

                    # Highlight search term using awk for clean color output
                    preview=$(echo "$preview" | awk -v term="$search_term" -v red="$RED" -v reset="$RESET" '
                        BEGIN { IGNORECASE=1 }
                        {
                            if (term == "") { print; next }
                            gsub(term, red "&" reset)
                            print
                        }' )
                    echo -e "   ${DIM}+${RESET} ${preview}\n"
                else
                    echo ""
                fi

                ((idx++))
            done
        fi

        draw_footer "search"

        # Key handling (using get_key)
        key=$(get_key)
        case "$key" in
            esc)
                return ;; # exit search
            up)
                ((selected_index--))
                ((selected_index < 0)) && selected_index=$((${#filtered_notes[@]} - 1))
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
            "")  # Enter
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

# Delete note interactive
delete_note_interactive() {
    local notes=("$@")
    clear
    echo -e "${BOLD}${RED}═══════════════════════════════════════${RESET}"
    echo -e "${BOLD}${RED}     Move to Bin${RESET}"
    echo -e "${BOLD}${RED}═══════════════════════════════════════${RESET}\n"

    echo -e "${YELLOW}Enter note number to delete:${RESET}\n"

    local count=1
    for note in "${notes[@]}"; do
        local heading=$(head -n 1 "$note" | sed 's/^#* *//')
        echo -e "${YELLOW}[$count]${RESET} ${BOLD}$heading${RESET}"
        ((count++))
    done

    draw_footer "delete"

    # Get input with ESC handling
    while true; do
        key=$(get_key)
        case "$key" in
            esc)
                send_notification "Notes App" "Action cancelled"
                return
                ;;
            [0-9])
                local num=$key
                local index=$((num - 1))
                if [ $index -ge 0 ] && [ $index -lt ${#notes[@]} ]; then
                    delete_note "${notes[$index]}"
                    return
                fi
                ;;
        esac
    done
}

# Preview note
preview_note() {
    local filepath=$1
    CURRENT_NOTE="$filepath"
    clear

    if [ ! -f "$filepath" ]; then
        send_notification "Notes App" "Note not found"
        sleep 1
        return
    fi

    local content=$(cat "$filepath")
    render_markdown "$content"

    draw_footer "preview"

    # Handle key input
    while true; do
        key=$(get_key)
        case "$key" in
            e|E)
                edit_note "$filepath"
                return
                ;;
            d|D)
                delete_note "$filepath"
                return
                ;;
            c|C)
                # Wait for number
                read -rsn1 num
                if [[ "$num" =~ ^[0-9]$ ]]; then
                    local code_file="$NOTES_DIR/.code_block_${num}"
                    if [ -f "$code_file" ]; then
                        local code_content=$(cat "$code_file")
                        if copy_code_block "$code_content"; then
                            send_notification "Notes App" "Code block $num copied to clipboard"
                        else
                            send_notification "Notes App" "Code saved to: $CODE_TEMP"
                        fi
                    else
                        send_notification "Notes App" "Code block $num not found"
                    fi
                fi
                ;;
            esc)
                return
                ;;
        esac
    done
}

# Edit note
edit_note() {
    local filepath=$1

    if [ ! -f "$filepath" ]; then
        send_notification "Notes App" "Note not found"
        sleep 1
        return
    fi

    ${EDITOR:-nano} "$filepath"

    local heading
    heading=$(head -n 1 "$filepath" | sed 's/^#* *//')
    send_notification "Notes App" "Note updated: $heading"

    # Auto-preview after edit
    preview_note "$filepath"
}

# Delete note (move to notebin)
delete_note() {
    local filepath=$1

    if [ ! -f "$filepath" ]; then
        send_notification "Notes App" "Note not found"
        sleep 1
        return
    fi

    local heading
    heading=$(head -n 1 "$filepath" | sed 's/^#* *//')

    clear
    echo -e "${YELLOW}${BOLD}═══════════════════════════════════════${RESET}"
    echo -e "${YELLOW}${BOLD}     MOVE TO BIN${RESET}"
    echo -e "${YELLOW}${BOLD}═══════════════════════════════════════${RESET}\n"
    echo -e "${CYAN}Move to bin: ${BOLD}$heading${RESET}"
    echo -e "\n${DIM}Note will be moved to notebin (can be restored later)${RESET}\n"

    draw_footer "delete"

    while true; do
        key=$(get_key)
        case "$key" in
            y|Y)
                local basename
                basename=$(basename "$filepath")
                mv "$filepath" "$NOTEBIN_DIR/$basename"
                send_notification "Notes App" "Note moved to bin: $heading"
                sleep 1
                return
                ;;
            n|N|esc)
                send_notification "Notes App" "Action cancelled"
                sleep 1
                return
                ;;
        esac
    done
}

# Main loop
main_menu() {
    while true; do
        list_notes
    done
}

# Initialize and start
init_notes_dir
main_menu
