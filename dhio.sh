#!/bin/bash
# Terminal Notes App with Markdown Preview

# Source all modules
source "$(dirname "$0")/config.sh"
source "$(dirname "$0")/lib/utils.sh"
source "$(dirname "$0")/lib/ui.sh"
source "$(dirname "$0")/lib/markdown.sh"
source "$(dirname "$0")/lib/notebin.sh"
source "$(dirname "$0")/lib/archive.sh"

# Source note modules
source "$(dirname "$0")/lib/notes/create.sh"
source "$(dirname "$0")/lib/notes/list.sh"
source "$(dirname "$0")/lib/notes/edit.sh"
source "$(dirname "$0")/lib/notes/delete.sh"
source "$(dirname "$0")/lib/notes/preview.sh"
source "$(dirname "$0")/lib/notes/tags.sh"
source "$(dirname "$0")/lib/notes/search.sh"
source "$(dirname "$0")/lib/notes/main.sh"

# Initialize and start
init_notes_dir
main_menu
