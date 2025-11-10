# Dhio — Terminal Notes App

Dhio is a lightweight, terminal-first notes application with Markdown preview, tagging, search, and optional encryption. It's designed to be fast, scriptable, and easy to install. This README explains installation, daily usage, encryption, customization, and development notes.

---

## Table of contents

- Overview
- Install
- Quick start
- Common commands & features
- Encryption (RSA / symmetric)
- Config and directories
- UI/Rendering notes
- Development & contributing
- Troubleshooting
- License

---

## Overview

Dhio provides a small, terminal-driven notes workflow with these goals:

- Markdown-first note editing and preview (with simple inline formatting, code blocks, and tables)
- Tags and fast search
- Lightweight encryption support (per-user RSA keypairs + symmetric fallback)
- Small, self-contained shell scripts (no heavy dependencies required)

The codebase is organized under `/lib` with core, ui, features, and notes modules.


## Install

From the project repo (recommended):

```bash
# run installer included in repository
./install.sh
```

Or by cloning the repository (recommended) and running the installer from the repo root:

```bash
git clone https://github.com/zhasumit/dhio.git
cd dhio
./install.sh
```

If you prefer the one-line `curl | bash` installer (less recommended), use the raw URL for `install.sh`:

```bash
curl -sSL https://raw.githubusercontent.com/zhasumit/dhio/main/install.sh | bash
```

What the installer does:

- Makes `dhio.sh` executable
- Appends a small block to `~/.bashrc` and `~/.zshrc` creating an alias `dhio` pointing to the installed location (using the current `pwd` at install time)
- Creates a small wrapper in `~/.local/bin/dhio` (so you can run `dhio` when `~/.local/bin` is in your PATH)

After install, reload your shell:

```bash
source ~/.bashrc  # or ~/.zshrc
# then run
dhio
```

Uninstall

If you installed from the repository (git clone), you can remove the alias and wrapper by running the uninstall helper from the project root:

```bash
# from the repo root
./uninstall.sh
# or via the installer helper
./install.sh uninstall
```

If you used the one-line installer (`curl | bash`) the default remote install directory is `~/.local/share/dhio` and you can run the bundled uninstall script there to remove shell rc entries, wrapper and optionally the install directory:

```bash
# remove alias and wrapper (prompts)
~/.local/share/dhio/uninstall.sh

# remove everything without prompts (wrapper + install dir)
~/.local/share/dhio/uninstall.sh --remove-dir --yes
```


## Quick start

- Run `dhio` to open the interactive UI (or `./dhio.sh` from the repo root).
- Use the main menu to create, list, view, and edit notes.
- Notes are stored as plain Markdown files in `$NOTES_DIR` (by default `$HOME/Documents/.dhio`). See `config.sh` to change this.

Basic keyboard/flow (interactive):

- `N` — new note
- `S` — sort
- `I` — statistics
- Arrow keys — navigate lists
- `Enter` — open/preview a note
- `ESC` — back/exit

Search & tags

- From the UI you can search (`/`) and filter by tags.
- Tags are simple tokens inside notes starting with `@` (e.g. `@work`, `@urgent`). Use `@tagname` anywhere in a note to mark it.


## Common commands & functions

You can source modules or call functions directly from a shell for scripting.

Examples (from the repo root):

```bash
# source helpers
. lib/core/themes.sh && init_theme
. lib/utils/common.sh
. lib/core/statistics.sh

# Print condensed stats (scripted)
show_statistics   # interactive menu

# Display a single line from a file (useful in scripts)
# Usage: show_line /path/to/note.md 42 2  # show line 42 with 2 lines of context
show_line /path/to/note.md 42 2
```

Encryption helpers (see next section for more details):

```bash
# Create/ensure a local keypair (prompts if necessary)
ensure_keypair myuser

# Encrypt note for a user (produces file.md.enc and file.md.key)
encrypt_note_rsa /path/to/file.md myuser

# Decrypt note (asks for passphrase to unlock private key)
decrypt_note_rsa /path/to/file.md.enc myuser
```


## Encryption (how it works)

Dhio supports encryption; for a complete guide and security notes see `docs/ENCRYPTION.md`.

Quick summary:

- Recommended: RSA-wrapped symmetric encryption (`encrypt_note_rsa` / `decrypt_note_rsa`). Keys are stored in `$NOTES_DIR/.keys/` and private keys are AES-encrypted with a passphrase.
- Legacy: symmetric AES-256 passphrase flow (`encrypt_note` / `decrypt_note`).
- Dhio avoids passing passphrases on the command line — it uses stdin or secure temporary files (mode 600) internally. See `docs/SECURITY.md` for the security checklist.

Examples:

```bash
# interactive
ensure_keypair myuser
encrypt_note_rsa /path/to/note.md myuser
decrypt_note_rsa /path/to/note.md.enc myuser

# non-interactive (scripted)
create_keypair_noninteractive myuser 'S3cureP@ss'
encrypt_note_rsa /path/to/note.md myuser
decrypt_note_rsa /path/to/note.md.enc myuser 'S3cureP@ss'
```

See `docs/ENCRYPTION.md` for full details, `docs/KEYS_AND_GPG.md` for signing/release guidance, and `docs/SECURITY.md` for hardening steps.


## Configuration & important files

- `dhio.sh` — main entrypoint; sources all modules and starts the interactive UI.
- `config.sh` — configuration and directory settings (default `NOTES_DIR`, `NOTEBIN_DIR`, etc.)
- `lib/core/themes.sh` — terminal color variables (initialized on startup)
- `lib/utils/common.sh` — helper utilities (show_line, highlight, strip_ansi, etc.)
- `lib/ui/markdown.sh` — markdown rendering to terminal (inline formatting, tables, code blocks)
- `lib/core/statistics.sh` — statistics view (condensed)
- `lib/core/encryption.sh` — encryption module (symmetric + RSA-wrapped symmetric)
- `lib/notes/*.sh` — create, edit, delete, list, preview, tags, search handlers
- `install.sh` — installer that sets up the `dhio` alias and wrapper

Customize

- To change where notes are stored, edit `NOTES_DIR` in `config.sh` before running the app.


## UI / Rendering notes

- Markdown rendering uses a custom shell parser. It supports headings, lists, code blocks, inline bold/italic/`code`, links, images (printed as placeholders), checkboxes, and simple tables.
- Color variables are defined in `lib/core/themes.sh` and exported; if your terminal doesn't support 256 colors, colors may appear different.
- If you encounter misaligned tables or strange characters, ensure your terminal reports the correct width (`tput cols`) and that `$TERM` is properly set. The renderer strips ANSI escapes when measuring column widths to avoid misalignment.


## Development & contributing

- The project is intentionally small and shell-only to keep dependencies minimal.
- To run and test changes locally:
  - Source the modules in a shell or run `./dhio.sh` from the project root.
  - Use a temporary `NOTES_DIR` for tests to avoid touching your real notes.

Suggested improvements (good first tasks)

- Add an interactive UI entry to encrypt/decrypt a note from the note list.
- Improve passphrase handling to avoid any exposure via process arguments.
- Add tests / scripts to exercise encryption flows automatically.

Pull requests

- Fork, implement changes, add tests, and open a PR with a short description. Keep changes focused and avoid large unrelated refactors.


## Troubleshooting

- If colors are not rendering correctly: check `lib/core/themes.sh` and ensure your terminal supports ANSI escapes. Try `init_theme` sourcing and `echo -e "${CYAN}test${RESET}"` to validate.
- If `dhio` alias/command doesn't work after install, ensure you have reloaded your shell or that `~/.local/bin` is in your PATH.
- If encryption fails, verify you have `openssl` installed and available in `$PATH`.


## License

This project is licensed under the MIT License — see the `LICENSE` file for details.


---

If you want, I can also:

- Add an explicit `CONTRIBUTING.md` and `CODE_OF_CONDUCT.md`,
- Create a `docs/` folder with screenshots or terminal recording samples,
- Add automated tests for encryption and statistics flows.

Tell me which of those you'd like next and I will implement them.