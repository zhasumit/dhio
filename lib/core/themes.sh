#!/bin/bash
# Simple theme system with single color scheme

# Load theme - single color scheme
load_theme() {
    # Single unified color scheme
    RED='\033[0;31m'
    GREEN='\033[0;32m'
    YELLOW='\033[1;33m'
    BLUE='\033[0;34m'
    MAGENTA='\033[0;35m'
    CYAN='\033[0;36m'
    WHITE='\033[1;37m'
    BOLD='\033[1m'
    DIM='\033[2m'
    PURPLE='\033[38;5;141m'
    GRAY='\033[38;5;240m'
    TAG_COLOR='\033[38;5;208m'
    RESET='\033[0m'
    
    # Export color variables so they're available to all scripts
    export RED GREEN YELLOW BLUE MAGENTA CYAN WHITE BOLD DIM PURPLE GRAY TAG_COLOR RESET
}

# Initialize theme on startup
init_theme() {
    load_theme
}

