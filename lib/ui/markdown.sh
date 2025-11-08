#!/bin/bash
# Enhanced Markdown rendering for Dhio Notes App

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
                result="${result}${TAG_COLOR}${tag_content}${RESET}"
                i=$end_pos
                continue
            else
                result="${result}${char}"
                ((i++))
                continue
            fi
        fi
        # Links [text](url)
        if [ "$char" = "[" ]; then
            local link_end=$((i+1))
            local link_text=""
            while [ $link_end -lt $len ]; do
                if [ "${line:$link_end:1}" = "]" ] && [ "${line:$link_end+1:1}" = "(" ]; then
                    link_text="${line:$i+1:$((link_end-i-1))}"
                    local url_start=$((link_end+2))
                    local url_end=$url_start
                    while [ $url_end -lt $len ]; do
                        if [ "${line:$url_end:1}" = ")" ]; then
                            local url="${line:$url_start:$((url_end-url_start))}"
                            result="${result}${CYAN}${link_text}${RESET} ${DIM}(${url})${RESET}"
                            i=$((url_end+1))
                            continue 2
                        fi
                        ((url_end++))
                    done
                fi
                ((link_end++))
            done
        fi
        # Bold and italic
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

# Render table
render_table() {
    local lines=("$@")
    if [ ${#lines[@]} -lt 2 ]; then
        return
    fi
    
    # Parse header
    local header="${lines[0]}"
    local separator="${lines[1]}"
    local data_lines=("${lines[@]:2}")
    
    # Extract columns from header
    IFS='|' read -ra header_cols <<< "$header"
    local num_cols=${#header_cols[@]}
    
    # Calculate column widths
    local col_widths=()
    for ((i=0; i<num_cols; i++)); do
        local max_len=0
        for line in "${lines[@]}"; do
            IFS='|' read -ra cols <<< "$line"
            local clean_col=$(echo "${cols[$i]}" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//' | sed 's/\x1b\[[0-9;]*m//g')
            local len=${#clean_col}
            [ $len -gt $max_len ] && max_len=$len
        done
        col_widths+=($max_len)
    done
    
    # Print table with better formatting
    echo -e "${CYAN}┌"
    for ((i=0; i<num_cols; i++)); do
        printf "%*s" ${col_widths[$i]} "" | tr ' ' '─'
        [ $i -lt $((num_cols-1)) ] && echo -n "┬"
    done
    echo -e "┐${RESET}"
    
    # Header
    echo -e "${CYAN}│${RESET}"
    for ((i=0; i<num_cols; i++)); do
        local col=$(echo "${header_cols[$i]}" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
        printf "${BOLD}%-*s${RESET}" ${col_widths[$i]} "$col"
        [ $i -lt $((num_cols-1)) ] && echo -n "${CYAN}│${RESET}"
    done
    echo -e "${CYAN}│${RESET}"
    
    # Separator
    echo -e "${CYAN}├"
    for ((i=0; i<num_cols; i++)); do
        printf "%*s" ${col_widths[$i]} "" | tr ' ' '─'
        [ $i -lt $((num_cols-1)) ] && echo -n "┼"
    done
    echo -e "┤${RESET}"
    
    # Data rows
    for line in "${data_lines[@]}"; do
        IFS='|' read -ra cols <<< "$line"
        echo -e "${CYAN}│${RESET}"
        for ((i=0; i<num_cols; i++)); do
            local col=$(echo "${cols[$i]}" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
            local formatted=$(process_inline "$col")
            printf "%-*s" ${col_widths[$i]} "$formatted"
            [ $i -lt $((num_cols-1)) ] && echo -n "${CYAN}│${RESET}"
        done
        echo -e "${CYAN}│${RESET}"
    done
    
    # Footer
    echo -e "${CYAN}└"
    for ((i=0; i<num_cols; i++)); do
        printf "%*s" ${col_widths[$i]} "" | tr ' ' '─'
        [ $i -lt $((num_cols-1)) ] && echo -n "┴"
    done
    echo -e "┘${RESET}"
}

# Render markdown to terminal with cleaner formatting
render_markdown() {
    local content="$1"
    local in_code_block=false
    local code_lang=""
    local code_content=""
    local code_block_num=0
    local in_table=false
    local table_lines=()
    
    local term_width=$(tput cols)
    local border_width=$((term_width - 4))
    
    echo ""
    echo -e "${CYAN}┌$(printf '%*s' $border_width '' | tr ' ' '─')┐${RESET}"
    
    while IFS= read -r line; do
        # Code blocks
        if [[ "$line" =~ ^\`\`\`(.*)$ ]]; then
            if [ "$in_code_block" = false ]; then
                in_code_block=true
                code_lang="${BASH_REMATCH[1]}"
                code_content=""
                ((code_block_num++))
                echo -e "${CYAN}│${RESET} ${PURPLE}┌─ Code${code_lang:+ ($code_lang)} ─$(printf '%*s' $((border_width-15-${#code_lang})) '' | tr ' ' '─')┐${RESET} ${CYAN}│${RESET}"
            else
                in_code_block=false
                echo -e "${CYAN}│${RESET} ${PURPLE}└$(printf '%*s' $((border_width-2)) '' | tr ' ' '─')┘${RESET} ${CYAN}│${RESET}"
                echo -n "$code_content" > "$NOTES_DIR/.code_block_${code_block_num}"
            fi
            continue
        fi
        
        if [ "$in_code_block" = true ]; then
            code_content="${code_content}${line}"$'\n'
            if command -v bat &> /dev/null && [ -n "$code_lang" ]; then
                local highlighted=$(echo "$line" | bat --language="$code_lang" --style=plain --color=always --wrap=never 2>/dev/null || echo "$line")
                echo -e "${CYAN}│${RESET} ${PURPLE}│${RESET} ${GREEN}${highlighted}${RESET} ${PURPLE}│${RESET} ${CYAN}│${RESET}"
            elif command -v pygmentize &> /dev/null && [ -n "$code_lang" ]; then
                local highlighted=$(echo "$line" | pygmentize -l "$code_lang" -f terminal 2>/dev/null || echo "$line")
                echo -e "${CYAN}│${RESET} ${PURPLE}│${RESET} ${GREEN}${highlighted}${RESET} ${PURPLE}│${RESET} ${CYAN}│${RESET}"
            else
                echo -e "${CYAN}│${RESET} ${PURPLE}│${RESET} ${GREEN}${line}${RESET} ${PURPLE}│${RESET} ${CYAN}│${RESET}"
            fi
            continue
        fi
        
        # Tables
        if [[ "$line" =~ ^[[:space:]]*\|.*\| ]]; then
            if [ "$in_table" = false ]; then
                in_table=true
                table_lines=()
            fi
            table_lines+=("$line")
            continue
        else
            if [ "$in_table" = true ] && [ ${#table_lines[@]} -gt 0 ]; then
                render_table "${table_lines[@]}"
                table_lines=()
                in_table=false
            fi
        fi
        
        # Checkboxes
        if [[ "$line" =~ ^\[([[:space:]xX]?)\][[:space:]](.+)$ ]]; then
            local checkbox="${BASH_REMATCH[1]}"
            local todo_text="${BASH_REMATCH[2]}"
            local formatted_todo=$(process_inline "$todo_text")
            if [[ "$checkbox" =~ [xX] ]]; then
                echo -e "${CYAN}│${RESET}   ${GREEN}✓${RESET} ${STRIKETHROUGH}${DIM}$formatted_todo${RESET} ${CYAN}│${RESET}"
            else
                echo -e "${CYAN}│${RESET}   ${GRAY}☐${RESET}  $formatted_todo ${CYAN}│${RESET}"
            fi
            continue
        fi
        
        # Headings
        if [[ "$line" =~ ^######[[:space:]](.+)$ ]]; then
            local content="${BASH_REMATCH[1]}"
            local formatted=$(process_inline "$content")
            echo -e "${CYAN}│${RESET}   ${MAGENTA}${formatted}${RESET} ${CYAN}│${RESET}"
        elif [[ "$line" =~ ^#####[[:space:]](.+)$ ]]; then
            local content="${BASH_REMATCH[1]}"
            local formatted=$(process_inline "$content")
            echo -e "${CYAN}│${RESET}   ${MAGENTA}${BOLD}• ${formatted}${RESET} ${CYAN}│${RESET}"
        elif [[ "$line" =~ ^####[[:space:]](.+)$ ]]; then
            local content="${BASH_REMATCH[1]}"
            local formatted=$(process_inline "$content")
            echo -e "${CYAN}│${RESET}   ${BLUE}▸ ${formatted}${RESET} ${CYAN}│${RESET}"
        elif [[ "$line" =~ ^###[[:space:]](.+)$ ]]; then
            local content="${BASH_REMATCH[1]}"
            local formatted=$(process_inline "$content")
            echo -e "${CYAN}│${RESET}   ${BLUE}${BOLD}═══ ${formatted} ═══${RESET} ${CYAN}│${RESET}"
        elif [[ "$line" =~ ^##[[:space:]](.+)$ ]]; then
            local content="${BASH_REMATCH[1]}"
            local formatted=$(process_inline "$content")
            echo -e "${CYAN}│${RESET}   ${CYAN}${BOLD}▋▋ ${formatted} ▋▋${RESET} ${CYAN}│${RESET}"
        elif [[ "$line" =~ ^#[[:space:]](.+)$ ]]; then
            local content="${BASH_REMATCH[1]}"
            local formatted=$(process_inline "$content")
            echo -e "${CYAN}│${RESET}   ${WHITE}${BOLD}█ ${formatted} █${RESET} ${CYAN}│${RESET}"
        # Horizontal rules
        elif [[ "$line" =~ ^(---|\*\*\*|___)$ ]]; then
            echo -e "${CYAN}│${RESET}   ${DIM}$(printf '%*s' $((border_width-6)) '' | tr ' ' '─')${RESET} ${CYAN}│${RESET}"
        # Lists
        elif [[ "$line" =~ ^[[:space:]]*[-*+][[:space:]](.+)$ ]]; then
            local content="${BASH_REMATCH[1]}"
            local formatted=$(process_inline "$content")
            echo -e "${CYAN}│${RESET}   ${YELLOW}•${RESET} $formatted ${CYAN}│${RESET}"
        elif [[ "$line" =~ ^[[:space:]]*[0-9]+\.[[:space:]](.+)$ ]]; then
            local content="${BASH_REMATCH[1]}"
            local formatted=$(process_inline "$content")
            echo -e "${CYAN}│${RESET}   ${YELLOW}▸${RESET} $formatted ${CYAN}│${RESET}"
        # Blockquotes
        elif [[ "$line" =~ ^\>[[:space:]](.+)$ ]]; then
            local content="${BASH_REMATCH[1]}"
            local formatted=$(process_inline "$content")
            echo -e "${CYAN}│${RESET}   ${DIM}┃${RESET} ${formatted} ${CYAN}│${RESET}"
        # Images
        elif [[ "$line" =~ ^\!\[.*\]\(.*\) ]]; then
            local alt=$(echo "$line" | sed -n 's/^!\[\([^\]]*\)\].*/\1/p')
            local url=$(echo "$line" | sed -n 's/^!\[[^\]]*\](\([^)]*\))/\1/p')
            echo -e "${CYAN}│${RESET}   ${CYAN}[Image: ${alt}]${RESET} ${DIM}(${url})${RESET} ${CYAN}│${RESET}"
        # Regular text
        else
            if [ -n "$line" ]; then
                local formatted=$(process_inline "$line")
                echo -e "${CYAN}│${RESET}   $formatted ${CYAN}│${RESET}"
            else
                echo -e "${CYAN}│${RESET} ${CYAN}│${RESET}"
            fi
        fi
    done <<< "$content"
    
    echo -e "${CYAN}└$(printf '%*s' $border_width '' | tr ' ' '─')┘${RESET}"
    echo ""
}
