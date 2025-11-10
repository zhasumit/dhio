# Developer Guide — Dhio

This guide explains the main design, developer tasks, and where key functionality lives. It is intended for contributors or maintainers who want to understand and modify the code.

## Purpose and goals

Dhio is a terminal-first notes app implemented in portable Bash. Design goals:
- Minimal dependencies (OpenSSL optional for encryption; bat/pygmentize optional for highlighting)
- Clear module boundaries: `core`, `ui`, `notes`, `features`, `utils`
- Easy to script and extend by sourcing helper functions

## Key directories and files

- `dhio.sh` — main entrypoint. Sources `config.sh`, initializes theme and notes directories, then sources modules and starts the interactive UI. Changes here affect startup order.
- `config.sh` — central configuration. Contains default `NOTES_DIR`, `NOTEBIN_DIR`, `ARCHIVE_DIR`, and temp file paths. Contributors can make configuration options configurable via CLI or env.

- `lib/utils/common.sh` — general-purpose utilities used across the app:
  - `init_notes_dir` — ensures the directory layout exists
  - `get_key` — small single-key reader for interactive menus
  - `copy_code_block` — copies extracted code to clipboard if available
  - `show_line` — handy helper to print a specific line from a file (used by the user for ‘ln N’ flows)
  - `highlight_search_term`, `strip_ansi`, etc.

- `lib/core/themes.sh` — defines ANSI color variables and exports them for all modules. Keep color names stable; UI code expects variables like `${TAG_COLOR}`, `${RESET}`, `${GREEN}`, etc.

- `lib/ui/markdown.sh` — Markdown rendering to the terminal. Responsibilities:
  - Inline formatting (`process_inline`) — bold, italic, code spans, tags, links
  - `render_table` — render pipe-delimited tables with measured column widths (strips ANSI for measurements)
  - `render_markdown` — line-by-line rendering: headings, lists, code blocks, images, checkboxes, blockquotes

- `lib/core/statistics.sh` — statistics view. Computes total notes, archived/deleted counts, words, date range, and a top-tags summary. Uses `get_all_tags` and `get_notes_by_tag` helpers.

- `lib/core/encryption.sh` — encryption module. Supports:
  - Symmetric AES encryption (legacy functions `encrypt_note` / `decrypt_note`)
  - RSA-wrapped symmetric encryption (new): per-local-user RSA keypair in `$NOTES_DIR/.keys` and functions `encrypt_note_rsa` / `decrypt_note_rsa`
  - `ensure_default_user_key` prompts (interactive) to create a simple username/passphrase on first run
  - `ensure_default_user_key` prompts (interactive) to create a simple username/passphrase on first run

For full documentation on encryption, testing, keys, and release verification see the `docs/` directory:

- `docs/ENCRYPTION.md` — detailed description of RSA-wrapped and symmetric flows, usage examples, and hardening notes.
- `docs/KEYS_AND_GPG.md` — guidance on GPG signing, publishing public keys, and installer verification.
- `docs/TESTING.md` — how tests are organized and how to add tests and run them locally/CI.
- `docs/SECURITY.md` — security model, remaining risks, and pre-launch checklist.

- `lib/notes/*.sh` — note operations (create, edit, delete, preview, search, tags). These files glue user actions in the UI to on-disk note files.

- `lib/features/*.sh` — higher-level features like `notebin` (trash) and `archive`.

- `install.sh` — simple installer that appends an alias and creates a `~/.local/bin/dhio` wrapper using the install `pwd`.

## Code style and conventions

- Shell: Bash idioms are used. Avoid bash-isms that break on older Bash versions if you intend to support them.
- Functions: keep behavior idempotent where possible and return non-zero on failure.
- Color variables: always use `${RESET}` after colorized output to avoid leaking colors.
- When formatting output for width-sensitive UI, strip ANSI sequences to measure visible length.

## Adding features

1. Add new functionality as a new function in the appropriate module under `lib/`.
2. Keep interactive UI wiring to `lib/ui/ui.sh` and `lib/notes/main.sh`.
3. If the feature needs state, add small config options to `config.sh`.
4. Add unit-like smoke tests as small scripts or a `tests/` directory that sources modules and checks outputs.

## Encryption notes for developers

- RSA keypairs are created with `openssl genpkey -algorithm RSA -pkeyopt rsa_keygen_bits:2048` and private keys are encrypted with AES-256 and a passphrase.
- The RSA flow stores two files per encrypted note: `note.md.enc` (encrypted content) and `note.md.enc.key` (RSA-encrypted symmetric key). The `decrypt_note_rsa` function expects the private key under `$NOTES_DIR/.keys/<username>.pem`.
- Consider using OpenSSL's more modern envelope APIs or using `gpg` if you prefer OpenPGP compatibility.

## Testing locally

- Use a temporary `NOTES_DIR` to avoid touching your real notes during development. Example:

```bash
export NOTES_DIR="/tmp/dhio_test_notes"
mkdir -p "$NOTES_DIR"
# source modules and run functions interactively
. lib/core/themes.sh && init_theme
. lib/utils/common.sh
. lib/core/statistics.sh
show_statistics
```

## Where to add documentation/comments

- Prefer adding precise function-level comments explaining inputs, outputs and side effects directly above the function (readers will see these when opening files).
- For larger explanations (design decisions, security tradeoffs), add files under `docs/` and link from `README.md`.


## Checklist for new contributors

- [ ] Run existing scripts locally and confirm no syntax errors
- [ ] Keep changes small and testable
- [ ] Add or update docs for any new feature
- [ ] Consider adding a small smoke test to `tests/` when possible


## Contact

If you'd like, I can split this guide into smaller markdown files (encryption, UI, development, API reference). Tell me which sections you want split out first.
