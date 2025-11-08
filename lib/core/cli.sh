#!/bin/bash
# CLI interface for production-grade usage

# CLI help
show_cli_help() {
    cat << EOF
${BOLD}Dhio - Terminal Notes App${RESET}

${CYAN}Usage:${RESET}
    dhio [command] [options]

${CYAN}Commands:${RESET}
    ${YELLOW}add${RESET} <title> [content]    Create a new note
    ${YELLOW}edit${RESET} <title>             Edit a note
    ${YELLOW}delete${RESET} <title>           Delete a note (move to bin)
    ${YELLOW}archive${RESET} <title>          Archive a note
    ${YELLOW}restore${RESET} <title>          Restore from archive/bin
    ${YELLOW}list${RESET}                     List all notes
    ${YELLOW}search${RESET} <query>           Search notes
    ${YELLOW}tag${RESET} <tag>                Filter by tag
    ${YELLOW}preview${RESET} <title>          Preview a note
    ${YELLOW}export${RESET} <title> [format]  Export note (md/html/pdf)
    ${YELLOW}import${RESET} <file>            Import a note
    ${YELLOW}template${RESET} <name>          Create from template
    ${YELLOW}daily${RESET}                    Create/open daily note
    ${YELLOW}stats${RESET}                    Show statistics
    ${YELLOW}theme${RESET} [name]             Change theme
    ${YELLOW}encrypt${RESET} <title>          Encrypt a note
    ${YELLOW}decrypt${RESET} <title>          Decrypt a note
    ${YELLOW}history${RESET} <title>           View note history
    ${YELLOW}undo${RESET} <title>             Undo last change
    ${YELLOW}sort${RESET} [type] [order]      Sort notes
    ${YELLOW}help${RESET}                     Show this help

${CYAN}Examples:${RESET}
    dhio add "Meeting Notes" "Content here"
    dhio search "project"
    dhio tag work
    dhio export "My Note" pdf
    dhio template meeting
    dhio daily
    dhio stats

EOF
}

# Find note by title (fuzzy)
find_note_by_title() {
    local search_title="$1"
    local best_match=""
    local best_score=0
    
    for note in "$NOTES_DIR"/*.md; do
        if [ -f "$note" ] && ! [[ "$note" =~ /archive/ ]] && ! [[ "$note" =~ /notebin/ ]]; then
            local heading=$(head -n 1 "$note" 2>/dev/null | sed 's/^#* *//' || echo "")
            local filename=$(basename "$note" .md)
            
            # Simple fuzzy matching
            if echo "$heading" | grep -qi "$search_title" || echo "$filename" | grep -qi "$search_title"; then
                local score=$(echo "$heading" | grep -io "$search_title" | wc -l)
                if [ "$score" -gt "$best_score" ]; then
                    best_score=$score
                    best_match="$note"
                fi
            fi
        fi
    done
    
    echo "$best_match"
}

# CLI: Add note
cli_add() {
    local title="$1"
    local content="${2:-}"
    
    if [ -z "$title" ]; then
        echo "Error: Title required" >&2
        return 1
    fi
    
    local filename=$(echo "$title" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9]/-/g' | sed 's/--*/-/g' | sed 's/^-//' | sed 's/-$//')
    local filepath="$NOTES_DIR/${filename}.md"
    
    if [ -f "$filepath" ]; then
        echo "Error: Note already exists" >&2
        return 1
    fi
    
    {
        echo "# $title"
        echo ""
        if [ -n "$content" ]; then
            echo "$content"
        else
            echo "Write your note here..."
        fi
    } > "$filepath"
    
    echo "Note created: $title"
    return 0
}

# CLI: Edit note
cli_edit() {
    local title="$1"
    local filepath=$(find_note_by_title "$title")
    
    if [ -z "$filepath" ] || [ ! -f "$filepath" ]; then
        echo "Error: Note not found: $title" >&2
        return 1
    fi
    
    ${EDITOR:-nano} "$filepath"
    echo "Note updated: $title"
}

# CLI: Delete note
cli_delete() {
    local title="$1"
    local filepath=$(find_note_by_title "$title")
    
    if [ -z "$filepath" ] || [ ! -f "$filepath" ]; then
        echo "Error: Note not found: $title" >&2
        return 1
    fi
    
    move_note_to_dir "$filepath" "$NOTEBIN_DIR"
    echo "Note deleted: $title"
}

# CLI: Archive note
cli_archive() {
    local title="$1"
    local filepath=$(find_note_by_title "$title")
    
    if [ -z "$filepath" ] || [ ! -f "$filepath" ]; then
        echo "Error: Note not found: $title" >&2
        return 1
    fi
    
    move_note_to_dir "$filepath" "$ARCHIVE_DIR"
    echo "Note archived: $title"
}

# CLI: List notes
cli_list() {
    local notes=()
    for note in "$NOTES_DIR"/*.md; do
        [ -f "$note" ] && ! [[ "$note" =~ /archive/ ]] && ! [[ "$note" =~ /notebin/ ]] && notes+=("$note")
    done
    
    if [ ${#notes[@]} -eq 0 ]; then
        echo "No notes found"
        return
    fi
    
    # Apply sorting
    local sort_pref=$(get_sort_preference)
    local sort_type=$(echo "$sort_pref" | cut -d'|' -f1)
    local sort_order=$(echo "$sort_pref" | cut -d'|' -f2)
    apply_sorting notes "$sort_type" "$sort_order"
    
    for i in "${!notes[@]}"; do
        local note="${notes[$i]}"
        local heading=$(head -n 1 "$note" 2>/dev/null | sed 's/^#* *//' || echo "Untitled")
        local date=$(date -r "$note" "+%Y-%m-%d %H:%M" 2>/dev/null || echo "")
        echo "[$((i+1))] $heading ($date)"
    done
}

# CLI: Search
cli_search() {
    local query="$1"
    
    if [ -z "$query" ]; then
        echo "Error: Search query required" >&2
        return 1
    fi
    
    local matches=()
    for note in "$NOTES_DIR"/*.md; do
        if [ -f "$note" ] && ! [[ "$note" =~ /archive/ ]] && ! [[ "$note" =~ /notebin/ ]]; then
            if grep -qi -- "$query" "$note" 2>/dev/null; then
                matches+=("$note")
            fi
        fi
    done
    
    if [ ${#matches[@]} -eq 0 ]; then
        echo "No matches found"
        return
    fi
    
    for note in "${matches[@]}"; do
        local heading=$(head -n 1 "$note" 2>/dev/null | sed 's/^#* *//' || echo "Untitled")
        echo "- $heading"
    done
}

# CLI: Preview
cli_preview() {
    local title="$1"
    local filepath=$(find_note_by_title "$title")
    
    if [ -z "$filepath" ] || [ ! -f "$filepath" ]; then
        echo "Error: Note not found: $title" >&2
        return 1
    fi
    
    if is_encrypted "$filepath"; then
        preview_encrypted_note "$filepath"
    else
        cat "$filepath"
    fi
}

# CLI: Export
cli_export() {
    local title="$1"
    local format="${2:-markdown}"
    local filepath=$(find_note_by_title "$title")
    
    if [ -z "$filepath" ] || [ ! -f "$filepath" ]; then
        echo "Error: Note not found: $title" >&2
        return 1
    fi
    
    case "$format" in
        md|markdown) export_note_markdown "$filepath" ;;
        html) export_note_html "$filepath" ;;
        pdf) export_note_pdf "$filepath" ;;
        *) echo "Error: Invalid format. Use: md, html, or pdf" >&2; return 1 ;;
    esac
}

# CLI: Template
cli_template() {
    local template_name="$1"
    
    if [ -z "$template_name" ]; then
        echo "Error: Template name required" >&2
        return 1
    fi
    
    create_from_template "$template_name"
}

# CLI: Daily note
cli_daily() {
    create_daily_note
}

# CLI: Stats
cli_stats() {
    local total=$(get_total_notes)
    local archived=$(get_archived_count)
    local deleted=$(get_deleted_count)
    local words=$(get_total_words)
    
    echo "Total Notes: $total"
    echo "Archived: $archived"
    echo "Deleted: $deleted"
    echo "Total Words: $words"
}

# CLI: Theme
cli_theme() {
    local theme_name="$1"
    
    if [ -z "$theme_name" ]; then
        echo "Current theme: $(cat "$THEME_CONFIG" 2>/dev/null || echo 'tokyo-night')"
        echo "Available themes: $(get_available_themes | head -n 5 | tr '\n' ' ')"
        return
    fi
    
    load_theme "$theme_name"
    echo "Theme changed to: $theme_name"
}

# CLI: Encrypt
cli_encrypt() {
    local title="$1"
    local filepath=$(find_note_by_title "$title")
    
    if [ -z "$filepath" ] || [ ! -f "$filepath" ]; then
        echo "Error: Note not found: $title" >&2
        return 1
    fi
    
    encrypt_note "$filepath"
}

# CLI: Decrypt
cli_decrypt() {
    local title="$1"
    local filepath=$(find_note_by_title "$title")
    
    if [ -z "$filepath" ] || [ ! -f "$filepath" ]; then
        echo "Error: Note not found: $title" >&2
        return 1
    fi
    
    decrypt_note "$filepath"
}

# CLI: History
cli_history() {
    local title="$1"
    local filepath=$(find_note_by_title "$title")
    
    if [ -z "$filepath" ] || [ ! -f "$filepath" ]; then
        echo "Error: Note not found: $title" >&2
        return 1
    fi
    
    browse_note_history "$filepath"
}

# CLI: Undo
cli_undo() {
    local title="$1"
    local filepath=$(find_note_by_title "$title")
    
    if [ -z "$filepath" ] || [ ! -f "$filepath" ]; then
        echo "Error: Note not found: $title" >&2
        return 1
    fi
    
    undo_note_change "$filepath"
    echo "Undo successful"
}

# Main CLI handler
handle_cli() {
    local command="${1:-}"
    
    case "$command" in
        add) shift; cli_add "$@" ;;
        edit) shift; cli_edit "$@" ;;
        delete) shift; cli_delete "$@" ;;
        archive) shift; cli_archive "$@" ;;
        restore) shift; echo "Use interactive mode for restore" ;;
        list) cli_list ;;
        search) shift; cli_search "$@" ;;
        tag) shift; echo "Use interactive mode for tag filtering" ;;
        preview) shift; cli_preview "$@" ;;
        export) shift; cli_export "$@" ;;
        import) shift; import_note "$@" ;;
        template) shift; cli_template "$@" ;;
        daily) cli_daily ;;
        stats) cli_stats ;;
        theme) shift; cli_theme "$@" ;;
        encrypt) shift; cli_encrypt "$@" ;;
        decrypt) shift; cli_decrypt "$@" ;;
        history) shift; cli_history "$@" ;;
        undo) shift; cli_undo "$@" ;;
        sort) shift; echo "Use interactive mode for sorting" ;;
        help|--help|-h) show_cli_help ;;
        "") ;; # No command, run interactive mode
        *) echo "Unknown command: $command. Use 'dhio help' for help." >&2; return 1 ;;
    esac
}

