# Security notes — Dhio

This file documents security-relevant design decisions, current mitigations, and recommended next steps before a production release.

Design decisions and threat model
--------------------------------
- Dhio is a local, single-user terminal app. It does not transmit data externally by default.
- Threats addressed:
  - Accidental exposure of passphrases via process command-lines — mitigated by using stdin or secure temp files (mode 600).
  - Accidental keyring pollution — installer uses a temporary GNUPGHOME for signature verification.
  - File ownership and permissions — key directory created with 700 and private keys with 600.

Remaining risks and recommended mitigations
-------------------------------------------
1. Passphrase storage in scripts: while we avoid argv exposure, scripts still need to handle text passphrases. For high-security deployments:
   - Integrate with OS keyrings (libsecret, macOS Keychain) or hardware tokens (YubiKey with PIV/PKCS#11).
   - Minimize the time a plaintext passphrase exists on disk or in memory.

2. Key backup and recovery:
   - Losing a private key or passphrase will make encrypted notes irrecoverable. Provide users with explicit backup instructions.
   - Consider adding an export/import private key function (encrypted with a passphrase) and documenting secure offline storage.

3. Release key security:
   - Signing keys used to sign releases should be kept offline and rotated if compromised.
   - Publish public key fingerprints in `README.md` and in release notes to allow out-of-band verification.

4. Code execution surface in shell scripts:
   - Encourage code reviews and audits for contributors. Shell scripting is powerful but easy to misuse; prefer minimal trusted subsystems for sensitive operations.

Checklist before production launch
---------------------------------
- [ ] CI-driven release that builds tarball, runs all tests, and signs artifacts.
- [ ] Publish public signing key and fingerprint in `README.md` and `docs/KEYS_AND_GPG.md`.
- [ ] Add integration test for installer that runs in a disposable container and verifies signature+sha256 flows.
- [ ] Security review (preferably external) of `lib/core/encryption.sh` and `install.sh`.
