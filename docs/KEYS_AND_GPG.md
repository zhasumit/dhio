# Keys, releases, and GPG verification

This document covers how Dhio stores keys, recommended release signing practices, and how the installer verifies releases.

Key storage
-----------
- RSA keypairs created by Dhio are stored in `$NOTES_DIR/.keys/`.
  - Private key files: `$NOTES_DIR/.keys/<username>.pem` (permissions 600)
  - Public key files: `$NOTES_DIR/.keys/<username>.pub.pem` (permissions 644)
- Ensure `$NOTES_DIR/.keys/` is mode 700 and accessible only to the owner.

Creating and using GPG for release signing
------------------------------------------
The project supports signing release tarballs with GPG for users to verify authenticity.

1. Create a signing key (recommended on a secure machine):

   ```bash
   gpg --full-generate-key
   # choose RSA (3072 or 4096), set expiry/uid appropriately
   ```

2. Export your public key for publishing:

   ```bash
   gpg --armor --export your@email
   # publish the resulting ASCII-armored file in release assets or a stable URL
   ```

3. Sign your tarball (detached, ASCII-armored):

   ```bash
   gpg --armor --detach-sign dhio-v1.0.0.tar.gz
   # produces dhio-v1.0.0.tar.gz.asc
   ```

Publishing releases
-------------------
- Upload the tarball (`.tar.gz`), its SHA256 (`.tar.gz.sha256`), and the detached signature (`.tar.gz.asc`) as assets on GitHub Releases.
- Publish the project's public key as a stable URL (e.g., release asset or hosted on your website) and include the fingerprint in README for out-of-band verification.

Installer verification (what Dhio does)
-------------------------------------
- The installer supports `--gpg-pubkey-url` and `--sig-url` options: it downloads the tarball, the public key, and the detached signature, verifies the signature using a temporary `GNUPGHOME`, and aborts on mismatch.
- Example:

   ```bash
   # Recommended: publish release assets on GitHub and reference them by tag.
   # Replace <TAG> with the release tag, e.g. v1.0.0
   curl -sSL https://raw.githubusercontent.com/zhasumit/dhio/main/install.sh | \
      bash -s -- --tarball-url https://github.com/zhasumit/dhio/releases/download/<TAG>/dhio-<TAG>.tar.gz \
                --sha256 <HEX> \
                --gpg-pubkey-url https://github.com/zhasumit/dhio/releases/download/<TAG>/pubkey.asc \
                --sig-url https://github.com/zhasumit/dhio/releases/download/<TAG>/dhio-<TAG>.tar.gz.asc
   ```

How to verify locally
---------------------
If you downloaded the tarball and the signature manually, verify locally with:

```bash
gpg --import pubkey.asc
gpg --verify dhio-v1.0.0.tar.gz.asc dhio-v1.0.0.tar.gz
sha256sum -c dhio-v1.0.0.tar.gz.sha256
```

Recommendations
---------------
- Use a dedicated signing key and keep it offline when not signing.
- Publish the public key fingerprint in the repository README and website for users to verify the public key.
- Consider reproducible build practices (stripping timestamps, deterministic file order) to improve trust in tarball contents.
