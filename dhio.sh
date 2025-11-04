#!/bin/bash
# Terminal Notes App with Markdown Preview

# Source all modules
source "$(dirname "$0")/config.sh"
source "$(dirname "$0")/lib/utils.sh"
source "$(dirname "$0")/lib/ui.sh"
source "$(dirname "$0")/lib/notes.sh"
source "$(dirname "$0")/lib/notebin.sh"
source "$(dirname "$0")/lib/archive.sh"
source "$(dirname "$0")/lib/markdown.sh"

# Initialize and start
init_notes_dir
main_menu
