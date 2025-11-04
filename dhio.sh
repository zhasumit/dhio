#!/bin/bash
# Main entry point

source "$(dirname "$0")/config.sh"
source "$(dirname "$0")/lib/colors.sh"
source "$(dirname "$0")/lib/utils.sh"
source "$(dirname "$0")/lib/ui.sh"
source "$(dirname "$0")/lib/notes.sh"
source "$(dirname "$0")/lib/notebin.sh"
source "$(dirname "$0")/lib/search.sh"
source "$(dirname "$0")/lib/markdown.sh"

# Initialize and start
init_notes_dir
main_menu
