#!/bin/bash
# Export and import functionality for notes

EXPORT_DIR="$NOTES_DIR/exports"

# Initialize export directory
init_export_dir() {
    mkdir -p "$EXPORT_DIR"
}

# Export note to Markdown
# Usage: export_note_markdown filepath [output_path]
export_note_markdown() {
    local filepath="$1"
    local output_path="${2:-}"
    
    if [ ! -f "$filepath" ]; then
        send_notification "Notes App" "Note not found"
        return 1
    fi
    
    init_export_dir
    
    if [ -z "$output_path" ]; then
        local basename=$(basename "$filepath" .md)
        output_path="$EXPORT_DIR/${basename}.md"
    fi
    
    cp "$filepath" "$output_path"
    send_notification "Notes App" "Note exported to: $output_path"
    return 0
}

# Export note to HTML
# Usage: export_note_html filepath [output_path]
export_note_html() {
    local filepath="$1"
    local output_path="${2:-}"
    
    if [ ! -f "$filepath" ]; then
        send_notification "Notes App" "Note not found"
        return 1
    fi
    
    init_export_dir
    
    if [ -z "$output_path" ]; then
        local basename=$(basename "$filepath" .md)
        output_path="$EXPORT_DIR/${basename}.html"
    fi
    
    # Check for pandoc
    if command -v pandoc &> /dev/null; then
        pandoc -f markdown -t html -o "$output_path" "$filepath" 2>/dev/null
        if [ $? -eq 0 ]; then
            send_notification "Notes App" "Note exported to HTML: $output_path"
            return 0
        fi
    fi
    
    # Fallback: simple HTML conversion
    {
        echo "<!DOCTYPE html>"
        echo "<html><head><meta charset='utf-8'><title>$(head -n 1 "$filepath" | sed 's/^#* *//')</title></head><body>"
        echo "<pre>"
        cat "$filepath"
        echo "</pre>"
        echo "</body></html>"
    } > "$output_path"
    
    send_notification "Notes App" "Note exported to HTML: $output_path"
    return 0
}

# Export note to PDF
# Usage: export_note_pdf filepath [output_path]
export_note_pdf() {
    local filepath="$1"
    local output_path="${2:-}"
    
    if [ ! -f "$filepath" ]; then
        send_notification "Notes App" "Note not found"
        return 1
    fi
    
    if ! command -v pandoc &> /dev/null; then
        send_notification "Notes App" "Pandoc not found. Install pandoc for PDF export."
        return 1
    fi
    
    init_export_dir
    
    if [ -z "$output_path" ]; then
        local basename=$(basename "$filepath" .md)
        output_path="$EXPORT_DIR/${basename}.pdf"
    fi
    
    pandoc -f markdown -t pdf -o "$output_path" "$filepath" 2>/dev/null
    
    if [ $? -eq 0 ]; then
        send_notification "Notes App" "Note exported to PDF: $output_path"
        return 0
    else
        send_notification "Notes App" "PDF export failed"
        return 1
    fi
}

# Export all notes
# Usage: export_all_notes format [output_dir]
export_all_notes() {
    local format="${1:-markdown}"
    local output_dir="${2:-$EXPORT_DIR/all_notes}"
    
    mkdir -p "$output_dir"
    local count=0
    
    for note in "$NOTES_DIR"/*.md; do
        if [ -f "$note" ] && ! [[ "$note" =~ /archive/ ]] && ! [[ "$note" =~ /notebin/ ]]; then
            case "$format" in
                markdown|md)
                    export_note_markdown "$note" "$output_dir/$(basename "$note")" >/dev/null 2>&1
                    ;;
                html)
                    export_note_html "$note" "$output_dir/$(basename "$note" .md).html" >/dev/null 2>&1
                    ;;
                pdf)
                    export_note_pdf "$note" "$output_dir/$(basename "$note" .md).pdf" >/dev/null 2>&1
                    ;;
            esac
            ((count++))
        fi
    done
    
    send_notification "Notes App" "Exported $count notes to $output_dir"
}

# Import note from file
# Usage: import_note source_file [target_name]
import_note() {
    local source_file="$1"
    local target_name="${2:-}"
    
    if [ ! -f "$source_file" ]; then
        send_notification "Notes App" "Source file not found"
        return 1
    fi
    
    if [ -z "$target_name" ]; then
        target_name=$(basename "$source_file")
    fi
    
    # Ensure .md extension
    [[ "$target_name" != *.md ]] && target_name="${target_name}.md"
    
    local target_path="$NOTES_DIR/$target_name"
    
    # Check if exists
    if [ -f "$target_path" ]; then
        local timestamp=$(date +%s)
        target_name="${target_name%.md}_imported_${timestamp}.md"
        target_path="$NOTES_DIR/$target_name"
    fi
    
    cp "$source_file" "$target_path"
    send_notification "Notes App" "Note imported: $target_name"
    return 0
}

# Export menu
export_menu() {
    local filepath="$1"
    
    if [ ! -f "$filepath" ]; then
        send_notification "Notes App" "Note not found"
        return
    fi
    
    while true; do
        clear
        echo -e "${BOLD}${CYAN}═══════════════════════════════════════${RESET}"
        echo -e "${BOLD}${CYAN}     EXPORT NOTE${RESET}"
        echo -e "${BOLD}${CYAN}═══════════════════════════════════════${RESET}\n"
        
        local heading=$(head -n 1 "$filepath" | sed 's/^#* *//')
        echo -e "${YELLOW}Note:${RESET} ${BOLD}$heading${RESET}\n"
        echo -e "${YELLOW}[1]${RESET} Export as Markdown"
        echo -e "${YELLOW}[2]${RESET} Export as HTML"
        echo -e "${YELLOW}[3]${RESET} Export as PDF"
        echo -e "${YELLOW}[ESC]${RESET} Cancel\n"
        
        key=$(get_key)
        case "$key" in
            1) export_note_markdown "$filepath"; sleep 1; return ;;
            2) export_note_html "$filepath"; sleep 1; return ;;
            3) export_note_pdf "$filepath"; sleep 1; return ;;
            esc) return ;;
        esac
    done
}

