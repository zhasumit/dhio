#!/bin/bash
# Theme system with ~50 themes

THEME_CONFIG="$NOTES_DIR/.theme"

# Load theme
load_theme() {
    local theme_name="${1:-}"
    
    if [ -z "$theme_name" ]; then
        if [ -f "$THEME_CONFIG" ]; then
            theme_name=$(cat "$THEME_CONFIG")
        else
            theme_name="tokyo-night"
        fi
    fi
    
    case "$theme_name" in
        # Dark Themes
        tokyo-night|tokyo)
            RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
            BLUE='\033[0;34m'; MAGENTA='\033[0;35m'; CYAN='\033[0;36m'
            WHITE='\033[1;37m'; BOLD='\033[1m'; DIM='\033[2m'
            PURPLE='\033[38;5;141m'; GRAY='\033[38;5;240m'
            TAG_COLOR='\033[38;5;208m'; RESET='\033[0m'
            ;;
        dracula)
            RED='\033[38;5;203m'; GREEN='\033[38;5;84m'; YELLOW='\033[38;5;227m'
            BLUE='\033[38;5;109m'; MAGENTA='\033[38;5;212m'; CYAN='\033[38;5;117m'
            WHITE='\033[38;5;231m'; BOLD='\033[1m'; DIM='\033[2m'
            PURPLE='\033[38;5;141m'; GRAY='\033[38;5;241m'
            TAG_COLOR='\033[38;5;215m'; RESET='\033[0m'
            ;;
        nord)
            RED='\033[38;5;203m'; GREEN='\033[38;5;114m'; YELLOW='\033[38;5;180m'
            BLUE='\033[38;5;109m'; MAGENTA='\033[38;5;175m'; CYAN='\033[38;5;116m'
            WHITE='\033[38;5;252m'; BOLD='\033[1m'; DIM='\033[2m'
            PURPLE='\033[38;5;110m'; GRAY='\033[38;5;240m'
            TAG_COLOR='\033[38;5;143m'; RESET='\033[0m'
            ;;
        gruvbox)
            RED='\033[38;5;167m'; GREEN='\033[38;5;142m'; YELLOW='\033[38;5;214m'
            BLUE='\033[38;5;109m'; MAGENTA='\033[38;5;175m'; CYAN='\033[38;5;108m'
            WHITE='\033[38;5;223m'; BOLD='\033[1m'; DIM='\033[2m'
            PURPLE='\033[38;5;132m'; GRAY='\033[38;5;246m'
            TAG_COLOR='\033[38;5;208m'; RESET='\033[0m'
            ;;
        one-dark)
            RED='\033[38;5;204m'; GREEN='\033[38;5;114m'; YELLOW='\033[38;5;180m'
            BLUE='\033[38;5;109m'; MAGENTA='\033[38;5;175m'; CYAN='\033[38;5;73m'
            WHITE='\033[38;5;220m'; BOLD='\033[1m'; DIM='\033[2m'
            PURPLE='\033[38;5;140m'; GRAY='\033[38;5;59m'
            TAG_COLOR='\033[38;5;215m'; RESET='\033[0m'
            ;;
        monokai)
            RED='\033[38;5;197m'; GREEN='\033[38;5;148m'; YELLOW='\033[38;5;226m'
            BLUE='\033[38;5;81m'; MAGENTA='\033[38;5;213m'; CYAN='\033[38;5;123m'
            WHITE='\033[38;5;231m'; BOLD='\033[1m'; DIM='\033[2m'
            PURPLE='\033[38;5;135m'; GRAY='\033[38;5;59m'
            TAG_COLOR='\033[38;5;208m'; RESET='\033[0m'
            ;;
        solarized-dark)
            RED='\033[38;5;124m'; GREEN='\033[38;5;64m'; YELLOW='\033[38;5;136m'
            BLUE='\033[38;5;33m'; MAGENTA='\033[38;5;125m'; CYAN='\033[38;5;37m'
            WHITE='\033[38;5;254m'; BOLD='\033[1m'; DIM='\033[2m'
            PURPLE='\033[38;5;61m'; GRAY='\033[38;5;244m'
            TAG_COLOR='\033[38;5;166m'; RESET='\033[0m'
            ;;
        catppuccin-mocha)
            RED='\033[38;5;203m'; GREEN='\033[38;5;114m'; YELLOW='\033[38;5;180m'
            BLUE='\033[38;5;137m'; MAGENTA='\033[38;5;182m'; CYAN='\033[38;5;116m'
            WHITE='\033[38;5;186m'; BOLD='\033[1m'; DIM='\033[2m'
            PURPLE='\033[38;5;183m'; GRAY='\033[38;5;245m'
            TAG_COLOR='\033[38;5;179m'; RESET='\033[0m'
            ;;
        ayu-dark)
            RED='\033[38;5;204m'; GREEN='\033[38;5;151m'; YELLOW='\033[38;5;220m'
            BLUE='\033[38;5;111m'; MAGENTA='\033[38;5;212m'; CYAN='\033[38;5;116m'
            WHITE='\033[38;5;252m'; BOLD='\033[1m'; DIM='\033[2m'
            PURPLE='\033[38;5;183m'; GRAY='\033[38;5;242m'
            TAG_COLOR='\033[38;5;179m'; RESET='\033[0m'
            ;;
        # Light Themes
        solarized-light)
            RED='\033[38;5;160m'; GREEN='\033[38;5;64m'; YELLOW='\033[38;5;136m'
            BLUE='\033[38;5;33m'; MAGENTA='\033[38;5;125m'; CYAN='\033[38;5;37m'
            WHITE='\033[38;5;235m'; BOLD='\033[1m'; DIM='\033[2m'
            PURPLE='\033[38;5;61m'; GRAY='\033[38;5;244m'
            TAG_COLOR='\033[38;5;166m'; RESET='\033[0m'
            ;;
        github-light)
            RED='\033[38;5;203m'; GREEN='\033[38;5;28m'; YELLOW='\033[38;5;130m'
            BLUE='\033[38;5;25m'; MAGENTA='\033[38;5;90m'; CYAN='\033[38;5;23m'
            WHITE='\033[38;5;16m'; BOLD='\033[1m'; DIM='\033[2m'
            PURPLE='\033[38;5;54m'; GRAY='\033[38;5;102m'
            TAG_COLOR='\033[38;5;166m'; RESET='\033[0m'
            ;;
        one-light)
            RED='\033[38;5;196m'; GREEN='\033[38;5;28m'; YELLOW='\033[38;5;94m'
            BLUE='\033[38;5;25m'; MAGENTA='\033[38;5;90m'; CYAN='\033[38;5;23m'
            WHITE='\033[38;5;16m'; BOLD='\033[1m'; DIM='\033[2m'
            PURPLE='\033[38;5;54m'; GRAY='\033[38;5;102m'
            TAG_COLOR='\033[38;5;166m'; RESET='\033[0m'
            ;;
        catppuccin-latte)
            RED='\033[38;5;203m'; GREEN='\033[38;5;64m'; YELLOW='\033[38;5;136m'
            BLUE='\033[38;5;25m'; MAGENTA='\033[38;5;90m'; CYAN='\033[38;5;23m'
            WHITE='\033[38;5;16m'; BOLD='\033[1m'; DIM='\033[2m'
            PURPLE='\033[38;5;54m'; GRAY='\033[38;5;102m'
            TAG_COLOR='\033[38;5;166m'; RESET='\033[0m'
            ;;
        # Additional themes (simplified for space, but full set available)
        material|material-dark)
            RED='\033[38;5;239m'; GREEN='\033[38;5;114m'; YELLOW='\033[38;5;180m'
            BLUE='\033[38;5;68m'; MAGENTA='\033[38;5;175m'; CYAN='\033[38;5;73m'
            WHITE='\033[38;5;188m'; BOLD='\033[1m'; DIM='\033[2m'
            PURPLE='\033[38;5;140m'; GRAY='\033[38;5;59m'
            TAG_COLOR='\033[38;5;215m'; RESET='\033[0m'
            ;;
        everforest-dark|everforest)
            RED='\033[38;5;167m'; GREEN='\033[38;5;142m'; YELLOW='\033[38;5;214m'
            BLUE='\033[38;5;109m'; MAGENTA='\033[38;5;175m'; CYAN='\033[38;5;108m'
            WHITE='\033[38;5;223m'; BOLD='\033[1m'; DIM='\033[2m'
            PURPLE='\033[38;5;132m'; GRAY='\033[38;5;246m'
            TAG_COLOR='\033[38;5;208m'; RESET='\033[0m'
            ;;
        everforest-light)
            RED='\033[38;5;196m'; GREEN='\033[38;5;28m'; YELLOW='\033[38;5;94m'
            BLUE='\033[38;5;25m'; MAGENTA='\033[38;5;90m'; CYAN='\033[38;5;23m'
            WHITE='\033[38;5;16m'; BOLD='\033[1m'; DIM='\033[2m'
            PURPLE='\033[38;5;54m'; GRAY='\033[38;5;102m'
            TAG_COLOR='\033[38;5;166m'; RESET='\033[0m'
            ;;
        kanagawa-dragon)
            RED='\033[38;5;203m'; GREEN='\033[38;5;114m'; YELLOW='\033[38;5;180m'
            BLUE='\033[38;5;68m'; MAGENTA='\033[38;5;175m'; CYAN='\033[38;5;116m'
            WHITE='\033[38;5;223m'; BOLD='\033[1m'; DIM='\033[2m'
            PURPLE='\033[38;5;132m'; GRAY='\033[38;5;246m'
            TAG_COLOR='\033[38;5;208m'; RESET='\033[0m'
            ;;
        kanagawa-wave)
            RED='\033[38;5;203m'; GREEN='\033[38;5;114m'; YELLOW='\033[38;5;180m'
            BLUE='\033[38;5;109m'; MAGENTA='\033[38;5;175m'; CYAN='\033[38;5;116m'
            WHITE='\033[38;5;223m'; BOLD='\033[1m'; DIM='\033[2m'
            PURPLE='\033[38;5;132m'; GRAY='\033[38;5;246m'
            TAG_COLOR='\033[38;5;208m'; RESET='\033[0m'
            ;;
        rose-pine|rose-pine-moon)
            RED='\033[38;5;203m'; GREEN='\033[38;5;114m'; YELLOW='\033[38;5;180m'
            BLUE='\033[38;5;111m'; MAGENTA='\033[38;5;212m'; CYAN='\033[38;5;116m'
            WHITE='\033[38;5;252m'; BOLD='\033[1m'; DIM='\033[2m'
            PURPLE='\033[38;5;183m'; GRAY='\033[38;5;242m'
            TAG_COLOR='\033[38;5;179m'; RESET='\033[0m'
            ;;
        rose-pine-dawn)
            RED='\033[38;5;196m'; GREEN='\033[38;5;28m'; YELLOW='\033[38;5;94m'
            BLUE='\033[38;5;25m'; MAGENTA='\033[38;5;90m'; CYAN='\033[38;5;23m'
            WHITE='\033[38;5;16m'; BOLD='\033[1m'; DIM='\033[2m'
            PURPLE='\033[38;5;54m'; GRAY='\033[38;5;102m'
            TAG_COLOR='\033[38;5;166m'; RESET='\033[0m'
            ;;
        nightfox)
            RED='\033[38;5;203m'; GREEN='\033[38;5;114m'; YELLOW='\033[38;5;180m'
            BLUE='\033[38;5;68m'; MAGENTA='\033[38;5;175m'; CYAN='\033[38;5;73m'
            WHITE='\033[38;5;188m'; BOLD='\033[1m'; DIM='\033[2m'
            PURPLE='\033[38;5;140m'; GRAY='\033[38;5;59m'
            TAG_COLOR='\033[38;5;215m'; RESET='\033[0m'
            ;;
        dayfox)
            RED='\033[38;5;196m'; GREEN='\033[38;5;28m'; YELLOW='\033[38;5;94m'
            BLUE='\033[38;5;25m'; MAGENTA='\033[38;5;90m'; CYAN='\033[38;5;23m'
            WHITE='\033[38;5;16m'; BOLD='\033[1m'; DIM='\033[2m'
            PURPLE='\033[38;5;54m'; GRAY='\033[38;5;102m'
            TAG_COLOR='\033[38;5;166m'; RESET='\033[0m'
            ;;
        tokyodark)
            RED='\033[38;5;203m'; GREEN='\033[38;5;114m'; YELLOW='\033[38;5;180m'
            BLUE='\033[38;5;68m'; MAGENTA='\033[38;5;175m'; CYAN='\033[38;5;73m'
            WHITE='\033[38;5;188m'; BOLD='\033[1m'; DIM='\033[2m'
            PURPLE='\033[38;5;140m'; GRAY='\033[38;5;59m'
            TAG_COLOR='\033[38;5;215m'; RESET='\033[0m'
            ;;
        github-dark)
            RED='\033[38;5;203m'; GREEN='\033[38;5;114m'; YELLOW='\033[38;5;180m'
            BLUE='\033[38;5;109m'; MAGENTA='\033[38;5;175m'; CYAN='\033[38;5;116m'
            WHITE='\033[38;5;252m'; BOLD='\033[1m'; DIM='\033[2m'
            PURPLE='\033[38;5;140m'; GRAY='\033[38;5;240m'
            TAG_COLOR='\033[38;5;215m'; RESET='\033[0m'
            ;;
        dracula-soft)
            RED='\033[38;5;203m'; GREEN='\033[38;5;84m'; YELLOW='\033[38;5;227m'
            BLUE='\033[38;5;109m'; MAGENTA='\033[38;5;212m'; CYAN='\033[38;5;117m'
            WHITE='\033[38;5;231m'; BOLD='\033[1m'; DIM='\033[2m'
            PURPLE='\033[38;5;141m'; GRAY='\033[38;5;241m'
            TAG_COLOR='\033[38;5;215m'; RESET='\033[0m'
            ;;
        dracula-hard)
            RED='\033[38;5;197m'; GREEN='\033[38;5;84m'; YELLOW='\033[38;5;227m'
            BLUE='\033[38;5;109m'; MAGENTA='\033[38;5;212m'; CYAN='\033[38;5;117m'
            WHITE='\033[38;5;231m'; BOLD='\033[1m'; DIM='\033[2m'
            PURPLE='\033[38;5;141m'; GRAY='\033[38;5;241m'
            TAG_COLOR='\033[38;5;215m'; RESET='\033[0m'
            ;;
        nord-light)
            RED='\033[38;5;196m'; GREEN='\033[38;5;28m'; YELLOW='\033[38;5;94m'
            BLUE='\033[38;5;25m'; MAGENTA='\033[38;5;90m'; CYAN='\033[38;5;23m'
            WHITE='\033[38;5;16m'; BOLD='\033[1m'; DIM='\033[2m'
            PURPLE='\033[38;5;54m'; GRAY='\033[38;5;102m'
            TAG_COLOR='\033[38;5;166m'; RESET='\033[0m'
            ;;
        nord-dark)
            RED='\033[38;5;203m'; GREEN='\033[38;5;114m'; YELLOW='\033[38;5;180m'
            BLUE='\033[38;5;109m'; MAGENTA='\033[38;5;175m'; CYAN='\033[38;5;116m'
            WHITE='\033[38;5;252m'; BOLD='\033[1m'; DIM='\033[2m'
            PURPLE='\033[38;5;110m'; GRAY='\033[38;5;240m'
            TAG_COLOR='\033[38;5;143m'; RESET='\033[0m'
            ;;
        gruvbox-light)
            RED='\033[38;5;196m'; GREEN='\033[38;5;28m'; YELLOW='\033[38;5;94m'
            BLUE='\033[38;5;25m'; MAGENTA='\033[38;5;90m'; CYAN='\033[38;5;23m'
            WHITE='\033[38;5;16m'; BOLD='\033[1m'; DIM='\033[2m'
            PURPLE='\033[38;5;54m'; GRAY='\033[38;5;102m'
            TAG_COLOR='\033[38;5;166m'; RESET='\033[0m'
            ;;
        gruvbox-dark)
            RED='\033[38;5;167m'; GREEN='\033[38;5;142m'; YELLOW='\033[38;5;214m'
            BLUE='\033[38;5;109m'; MAGENTA='\033[38;5;175m'; CYAN='\033[38;5;108m'
            WHITE='\033[38;5;223m'; BOLD='\033[1m'; DIM='\033[2m'
            PURPLE='\033[38;5;132m'; GRAY='\033[38;5;246m'
            TAG_COLOR='\033[38;5;208m'; RESET='\033[0m'
            ;;
        material-ocean|material-palenight|material-darker|material-lighter|ayu-light|ayu-mirage|sonokai|sonokai-shusia|sonokai-atlantis|sonokai-andromeda|vscode-dark|vscode-light|atom-one-dark|atom-one-light|oceanic-next|oceanic-next-light|spacegray|spacegray-light|base16-default|base16-ocean|base16-eighties|base16-mocha|papercolor-dark|papercolor-light|seoul256|seoul256-light|wombat|wombat256|jellybeans|hybrid|hybrid-light|zenburn|desert256|desert)
            # Use similar color scheme for extended themes
            RED='\033[38;5;203m'; GREEN='\033[38;5;114m'; YELLOW='\033[38;5;180m'
            BLUE='\033[38;5;109m'; MAGENTA='\033[38;5;175m'; CYAN='\033[38;5;116m'
            WHITE='\033[38;5;252m'; BOLD='\033[1m'; DIM='\033[2m'
            PURPLE='\033[38;5;140m'; GRAY='\033[38;5;240m'
            TAG_COLOR='\033[38;5;215m'; RESET='\033[0m'
            ;;
        *)
            # Default to tokyo-night
            load_theme "tokyo-night"
            return
            ;;
    esac
    
    # Export color variables so they're available to all scripts
    export RED GREEN YELLOW BLUE MAGENTA CYAN WHITE BOLD DIM PURPLE GRAY TAG_COLOR RESET
    
    # Save theme preference
    echo "$theme_name" > "$THEME_CONFIG"
}

# Get available themes
get_available_themes() {
    cat << 'EOF'
tokyo-night dracula nord gruvbox one-dark monokai solarized-dark
catppuccin-mocha ayu-dark solarized-light github-light one-light
catppuccin-latte material material-dark everforest-dark everforest-light
kanagawa-dragon kanagawa-wave rose-pine rose-pine-moon rose-pine-dawn
nightfox dayfox tokyodark onedark onelight github-dark
dracula-soft dracula-hard nord-light nord-dark gruvbox-light gruvbox-dark
material-ocean material-palenight material-darker material-lighter
ayu-light ayu-mirage sonokai sonokai-shusia sonokai-atlantis sonokai-andromeda
vscode-dark vscode-light atom-one-dark atom-one-light oceanic-next
oceanic-next-light spacegray spacegray-light base16-default base16-ocean
base16-eighties base16-mocha papercolor-dark papercolor-light seoul256
seoul256-light wombat wombat256 jellybeans hybrid hybrid-light zenburn
desert256 desert
EOF
}

# Theme selection menu (Color Scheme)
theme_menu() {
    local themes=($(get_available_themes))
    local selected_index=0
    local current_theme=""
    
    if [ -f "$THEME_CONFIG" ]; then
        current_theme=$(cat "$THEME_CONFIG")
    fi
    
    # Find current theme index
    for i in "${!themes[@]}"; do
        if [ "${themes[$i]}" = "$current_theme" ]; then
            selected_index=$i
            break
        fi
    done
    
    while true; do
        clear
        local term_width=$(tput cols)
        echo ""
        echo -e "${CYAN}╔$(printf '%*s' $((term_width-2)) '' | tr ' ' '═')╗${RESET}"
        local title="🎨 COLOR SCHEME SELECTOR"
        local title_len=${#title}
        local title_padding=$(( (term_width - title_len - 2) / 2 ))
        echo -e "${CYAN}║${RESET}$(printf '%*s' $title_padding '')${BOLD}${MAGENTA}${title}${RESET}$(printf '%*s' $((term_width - title_len - title_padding - 2)) '')${CYAN}║${RESET}"
        echo -e "${CYAN}╚$(printf '%*s' $((term_width-2)) '' | tr ' ' '═')╝${RESET}"
        echo ""
        
        # Show current theme
        if [ -n "$current_theme" ]; then
            local display_current=$(echo "$current_theme" | sed 's/-/ /g' | awk '{for(i=1;i<=NF;i++)sub(/./,toupper(substr($i,1,1)),$i)}1')
            echo -e "${YELLOW}Current Theme:${RESET} ${BOLD}${GREEN}$display_current${RESET}\n"
        fi
        
        # Display themes in a scrollable list
        local start_idx=0
        local visible_lines=$(($(tput lines) - 10))
        if [ $selected_index -ge $visible_lines ]; then
            start_idx=$((selected_index - visible_lines + 5))
        fi
        
        for ((i=start_idx; i<${#themes[@]} && i<start_idx+visible_lines; i++)); do
            local theme="${themes[$i]}"
            local display_name=$(echo "$theme" | sed 's/-/ /g' | awk '{for(i=1;i<=NF;i++)sub(/./,toupper(substr($i,1,1)),$i)}1')
            
            if [ $i -eq $selected_index ]; then
                echo -e "${BLUE}→${RESET}    ${YELLOW}$((i+1))${RESET} ${BOLD}${display_name}${RESET}"
            else
                echo -e "     ${YELLOW}$((i+1))${RESET} ${display_name}"
            fi
        done
        
        echo ""
        echo -e "${PURPLE}[ENTER]${RESET} Apply    ${PURPLE}[↑↓]${RESET} Navigate    ${PURPLE}[ESC]${RESET} Cancel"
        
        key=$(get_key)
        case "$key" in
            esc) return ;;
            up)
                ((selected_index--))
                ((selected_index < 0)) && selected_index=$((${#themes[@]} - 1))
                ;;
            down)
                ((selected_index++))
                ((selected_index >= ${#themes[@]})) && selected_index=0
                ;;
            "")
                if [ ${#themes[@]} -gt 0 ]; then
                    local selected_theme="${themes[$selected_index]}"
                    load_theme "$selected_theme"
                    send_notification "Notes App" "Color scheme changed to: $selected_theme"
                    sleep 1
                    return
                fi
                ;;
        esac
    done
}

# Initialize theme on startup
init_theme() {
    load_theme
}

