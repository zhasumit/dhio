#!/bin/bash
# Terminal Notes App with Markdown Preview

# Source configuration
source "$(dirname "$0")/config.sh"

# Initialize directories
init_notes_dir

# Source core modules
source "$(dirname "$0")/lib/utils/common.sh"
source "$(dirname "$0")/lib/core/themes.sh"
init_theme  # Load theme before UI

# Source UI and rendering
source "$(dirname "$0")/lib/ui/ui.sh"
source "$(dirname "$0")/lib/ui/markdown.sh"

# Source core functionality
source "$(dirname "$0")/lib/core/operations.sh"
source "$(dirname "$0")/lib/core/encryption.sh"
source "$(dirname "$0")/lib/core/history.sh"
source "$(dirname "$0")/lib/core/export_import.sh"
source "$(dirname "$0")/lib/core/templates.sh"
source "$(dirname "$0")/lib/core/statistics.sh"
source "$(dirname "$0")/lib/core/sorting.sh"
source "$(dirname "$0")/lib/core/cli.sh"

# Source feature modules
source "$(dirname "$0")/lib/features/notebin.sh"
source "$(dirname "$0")/lib/features/archive.sh"

# Source note modules
source "$(dirname "$0")/lib/notes/create.sh"
source "$(dirname "$0")/lib/notes/list.sh"
source "$(dirname "$0")/lib/notes/edit.sh"
source "$(dirname "$0")/lib/notes/delete.sh"
source "$(dirname "$0")/lib/notes/preview.sh"
source "$(dirname "$0")/lib/notes/tags.sh"
source "$(dirname "$0")/lib/notes/search.sh"
source "$(dirname "$0")/lib/notes/main.sh"

# Initialize history
init_history

# Check if CLI mode
if [ $# -gt 0 ]; then
    handle_cli "$@"
    exit $?
fi

# Interactive mode
main_menu
