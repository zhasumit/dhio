# Project tree for Dhio

This file documents the on-disk layout of the Dhio project (current state).

Root

- config.sh                 # default configuration and paths
- dhio.sh                   # main entrypoint (sources modules)
- install.sh                # simple installer that adds an alias/wrapper
- README.md                 # user-facing README (installation & usage)
- docs/                     # documentation (this folder)
- lib/                      # code modules
    - core/                 # core back-end utilities and features
        - cli.sh
        - encryption.sh
        - export_import.sh
        - history.sh
        - operations.sh
        - sorting.sh
        - statistics.sh
        - templates.sh
        - themes.sh
    - features/             # optional features and higher-level operations
        - archive.sh
        - notebin.sh
    - notes/                # note-specific commands and UI glue
        - create.sh
        - delete.sh
        - edit.sh
        - list.sh
        - main.sh
        - preview.sh
        - search.sh
        - tags.sh
    - ui/                   # UI and rendering
        - markdown.sh
        - ui.sh
    - utils/                # small utilities used across the app
        - common.sh
- docs/                     # generated docs, developer guide, and tree


Notes
- The app is intentionally small and shell-native for portability.
- Each `lib/*` file typically defines several related functions and is sourced by `dhio.sh`.
