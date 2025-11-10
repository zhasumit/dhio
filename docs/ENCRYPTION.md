% Encryption — Dhio

This document explains the encryption models implemented in Dhio, how keys are stored, and recommended secure usage for production.

Summary
-------
- Recommended flow: RSA-wrapped symmetric encryption.
- Legacy flow: symmetric AES-256 passphrase-based encryption (kept for compatibility).
- Private RSA keys are stored encrypted on disk under `$NOTES_DIR/.keys/` and protected by a passphrase.
- All passphrases and symmetric keys are handled using stdin or temporary files (0600) to avoid exposure in process command lines.

Files and layout
----------------
- `$NOTES_DIR/your-note.md.enc` — encrypted file (AES-256-CBC) produced by the symmetric encryption step.
- `$NOTES_DIR/your-note.md.key` — RSA-encrypted symmetric key (binary). This companion file means the file is RSA-wrapped.
- `$NOTES_DIR/.keys/<username>.pem` — encrypted RSA private key (AES-encrypted using the user's passphrase).
- `$NOTES_DIR/.keys/<username>.pub.pem` — public key (PEM) for encrypting symmetric keys.

RSA-wrapped workflow (recommended)
----------------------------------
1. Keypair management
   - Create or ensure a keypair exists:

     ```bash
     # interactive (prompts)
     ensure_keypair myuser

     # non-interactive (scripted) — available for CI/scripts
     create_keypair_noninteractive myuser 'S3cureP@ss'
     ```

   - Keys are created with OpenSSL RSA (2048 bits) and the private key is encrypted with AES-256 using your passphrase.

2. Encrypting a note

   ```bash
   encrypt_note_rsa /path/to/note.md myuser
   # produces: note.md.enc and note.md.key (and removes the plaintext note)
   ```

   Implementation notes:
   - A random symmetric key is generated with `openssl rand -hex 32`.
   - The note is encrypted with `openssl enc -aes-256-cbc -pbkdf2` using the symmetric key provided via stdin (avoids argv exposure).
   - The symmetric key is encrypted with the recipient's RSA public key using `openssl rsautl -encrypt` and written to the `.key` companion file.

3. Decrypting a note

   ```bash
   # interactive (will prompt for passphrase if you don't pass it)
   decrypt_note_rsa /path/to/note.md.enc myuser

   # non-interactive (passphrase as third arg — still handled securely internally)
   decrypt_note_rsa /path/to/note.md.enc myuser 'S3cureP@ss'
   ```

   Implementation notes:
   - The private key is unlocked using a passphrase that is written to a secure temporary file (mode 600) and passed to OpenSSL with `-passin file:...`.
   - The RSA unwrap returns the symmetric key, which is then passed to `openssl enc -d` via stdin or a temporary passfile.

Legacy symmetric AES-256 flow
----------------------------
- Functions `encrypt_note` and `decrypt_note` exist for symmetric passphrase-based encryption. They are maintained for backward compatibility.
- For new deployments prefer RSA-wrapped flow for per-user keys and easier key distribution.

Security notes and hardening
---------------------------
- Passphrases are never passed directly on command-lines by Dhio; we use temporary files (0600) or stdin to avoid leaking secrets via process listings.
- The private key files under `$NOTES_DIR/.keys/` are sensitive — set directory mode 700 and private keys 600.
- Back up private keys securely. Losing the private key (or its passphrase) makes data unrecoverable.
- Consider using OS secret stores or hardware tokens (YubiKey/PKCS#11) for stronger protection; Dhio's shell-based implementation is intentionally simple.

Audit and testing
-----------------
- Tests under `tests/` include a smoke test for RSA-wrapped encrypt/decrypt. Run `./tests/run_all.sh` locally and in CI.
- On any change to the encryption code, add a new test covering the edge case (wrong passphrase, corrupted keyfile, truncated `.enc` file).

Appendix: troubleshooting
------------------------
- If decryption fails with "Failed to decrypt symmetric key", ensure:
  - You're using the correct username and passphrase.
  - The private key file exists and has correct permissions (600).
  - The companion `.key` file matches the `.enc` file (look for timestamps/ownership mismatch).
