# Testing — Dhio

This document explains the automated tests included with Dhio, how CI runs them, and how to add more tests.

Included tests
--------------
- `tests/test_encryption.sh` — non-interactive smoke test for RSA-wrapped encrypt/decrypt.
- `tests/run_all.sh` — test runner that executes all tests in `tests/`.

Running tests locally
---------------------
From the repo root:

```bash
bash tests/run_all.sh
```

The tests are intentionally small and fast. They run in a temporary `NOTES_DIR` and do not touch your real notes. If a test needs network or external resources, mock them or provide fixtures under `tests/fixtures/`.

CI integration
--------------
- GitHub Actions workflow `.github/workflows/ci.yml` includes a `lint-and-test` job that installs `shellcheck` and `openssl`, runs a lightweight `shellcheck` pass, and executes `./tests/run_all.sh`.
- There's also a manual `verify-release` job that can be run with `workflow_dispatch` inputs to verify tarballs and signatures.

Adding tests
------------
1. Create a new executable script under `tests/`, name it `test_<feature>.sh`.
2. Keep tests self-contained: create temporary directories, set `NOTES_DIR` to the temp dir, and clean up at the end.
3. Exit with non-zero on failure and print concise debug info to stderr.

Example test skeleton

```bash
#!/usr/bin/env bash
set -euo pipefail
TMPDIR=$(mktemp -d)
export NOTES_DIR="$TMPDIR/notes"
mkdir -p "$NOTES_DIR"
. ./lib/core/encryption.sh
# ... test actions ...
rm -rf "$TMPDIR"
```

Best practices
--------------
- Keep small, focused tests — one feature per test script.
- Stub or provide lightweight wrappers for interactive or external dependencies (e.g., `send_notification`) in the test itself.
- For integration tests involving installer flows, consider running them inside a disposable container or VM.
