# Dhio Notes App - Directory Structure

## Overview
This document describes the organized structure of the Dhio notes application.

## Directory Structure

```
dhio/
├── dhio.sh                 # Main entry point
├── config.sh               # Configuration and paths
├── lib/
│   ├── core/               # Core functionality modules
│   │   ├── cli.sh          # CLI interface
│   │   ├── encryption.sh   # AES-256 encryption
│   │   ├── export_import.sh # Export/import functionality
│   │   ├── history.sh      # Note history & undo/redo
│   │   ├── operations.sh   # Generic operations (delete, archive, restore)
│   │   ├── sorting.sh      # Note sorting functionality
│   │   ├── statistics.sh   # Note statistics
│   │   ├── templates.sh    # Note templates system
│   │   └── themes.sh       # Theme system (~50 themes)
│   │
│   ├── ui/                 # User interface modules
│   │   ├── ui.sh           # UI functions (footer, formatting)
│   │   └── markdown.sh     # Markdown rendering
│   │
│   ├── features/           # Feature modules
│   │   ├── archive.sh      # Archive menu and operations
│   │   └── notebin.sh      # Notebin (trash) menu and operations
│   │
│   ├── notes/              # Note-specific operations
│   │   ├── create.sh       # Note creation
│   │   ├── delete.sh       # Note deletion
│   │   ├── edit.sh          # Note editing
│   │   ├── list.sh          # Note listing
│   │   ├── main.sh          # Main menu loop
│   │   ├── preview.sh       # Note preview
│   │   ├── search.sh        # Note search
│   │   └── tags.sh          # Tag extraction and search
│   │
│   └── utils/               # Utility functions
│       └── common.sh        # Common utilities (init, notifications, etc.)
│
├── readme.md
└── thingstoadd.txt
```

## Module Organization

### Core Modules (`lib/core/`)
Advanced features and core functionality:
- **cli.sh**: Production-grade CLI interface
- **encryption.sh**: AES-256 encryption for sensitive notes
- **export_import.sh**: Export to Markdown/HTML/PDF, import notes
- **history.sh**: Version history, undo/redo functionality
- **operations.sh**: Generic reusable operations (delete, archive, restore, list rendering)
- **sorting.sh**: Sort notes by name, date, size (ascending/descending)
- **statistics.sh**: Note statistics and analytics
- **templates.sh**: Note templates (meeting, todo, code, daily, journal)
- **themes.sh**: Theme system with ~50 themes

### UI Modules (`lib/ui/`)
User interface and rendering:
- **ui.sh**: Footer menus, text formatting, centering
- **markdown.sh**: Markdown to terminal rendering with syntax highlighting

### Feature Modules (`lib/features/`)
Feature-specific menus and operations:
- **archive.sh**: Archive menu, search archived notes, restore from archive
- **notebin.sh**: Notebin (trash) menu, restore deleted notes, permanent deletion

### Note Modules (`lib/notes/`)
Core note operations:
- **create.sh**: Create new notes
- **delete.sh**: Delete notes (move to notebin)
- **edit.sh**: Edit existing notes
- **list.sh**: List and navigate notes
- **main.sh**: Main menu loop
- **preview.sh**: Preview note content
- **search.sh**: Search notes by content/title
- **tags.sh**: Extract tags, tag-based filtering

### Utils (`lib/utils/`)
Common utility functions:
- **common.sh**: Directory initialization, notifications, key input, clipboard operations, text highlighting

## Key Design Principles

1. **Separation of Concerns**: Each module has a single, clear responsibility
2. **No Duplication**: Removed duplicate files and consolidated functionality
3. **Modularity**: Easy to extend and maintain
4. **Clear Organization**: Related functionality grouped together
5. **Reusability**: Generic operations in `core/operations.sh` for common tasks

## File Loading Order

The main script (`dhio.sh`) loads modules in this order:
1. Configuration
2. Utilities
3. Themes (must load before UI)
4. UI modules
5. Core functionality
6. Feature modules
7. Note operations

This ensures dependencies are available when needed.

