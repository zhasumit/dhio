#!/bin/bash
# Markdown rendering

# Process inline markdown formatting with tag support
process_inline() {
    local line="$1"
    local result=""
    local i=0
    line="${line//<br>/$'\n'}"
    line="${line//<br\/>/$'\n'}"
    line="${line//<BR>/$'\n'}"
    line="${line//<BR\/>/$'\n'}"
    local len=${#line}
    while [ $i -lt $len ]; do
        local char="${line:$i:1}"
        local next="${line:$i+1:1}"
        local next2="${line:$i+2:1}"
        if [ "$char" = "@" ]; then
            local end_pos=$((i+1))
            local found_end=false
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
        if [[ "$line" =~ ^\[([[:space:]xX]?)\][[:space:]](.+)$ ]]; then
            local checkbox="${BASH_REMATCH[1]}"
            local todo_text="${BASH_REMATCH[2]}"
            local formatted_todo=$(process_inline "$todo_text")
            if [[ "$checkbox" =~ [xX] ]]; then
                echo -e "  ${GREEN}✓✓${RESET} ${STRIKETHROUGH}${DIM}$formatted_todo${RESET}"
            else
                echo -e "  ${GRAY}☐${RESET}  $formatted_todo"
            fi
            continue
        fi
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
        elif [[ "$line" =~ ^(---|\*\*\*|___)$ ]]; then
            echo -e "${DIM}────────────────────────────────────────────────────${RESET}"
        elif [[ "$line" =~ ^[[:space:]]*[-*+][[:space:]](.+)$ ]]; then
            local content="${BASH_REMATCH[1]}"
            local formatted=$(process_inline "$content")
            echo -e "  ${YELLOW}•${RESET} $formatted"
        elif [[ "$line" =~ ^[[:space:]]*[0-9]+\.[[:space:]](.+)$ ]]; then
            local content="${BASH_REMATCH[1]}"
            local formatted=$(process_inline "$content")
            echo -e "  ${YELLOW}▸${RESET} $formatted"
        elif [[ "$line" =~ ^\>[[:space:]](.+)$ ]]; then
            local content="${BASH_REMATCH[1]}"
            local formatted=$(process_inline "$content")
            echo -e "${DIM}┃${RESET} $formatted"
        else
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
