RELEASE PROCESS
===============

This document describes a minimal, reproducible process to create a release tarball and a signed artifact that the installer can verify.

1) Build a source tarball

   From the repository root (clean working tree):

     git checkout -b release-v1
     git tag -a v1.0.0 -m "Release v1.0.0"
     git archive --format=tar.gz -o dhio-v1.0.0.tar.gz v1.0.0

   This produces `dhio-v1.0.0.tar.gz` which is what the installer can download.

2) Create a SHA256 checksum

     sha256sum dhio-v1.0.0.tar.gz > dhio-v1.0.0.tar.gz.sha256

3) Sign the tarball (optional but recommended)

   Use GPG to create a detached signature:

     gpg --armor --detach-sign dhio-v1.0.0.tar.gz

   This produces `dhio-v1.0.0.tar.gz.asc`.

4) Publish

   Upload `dhio-v1.0.0.tar.gz`, `dhio-v1.0.0.tar.gz.sha256` and optionally `dhio-v1.0.0.tar.gz.asc` alongside your GitHub release assets.

5) Installer verification

   The installer supports an optional `--sha256` argument. Users can run:

     curl -sSL <URL_TO_INSTALLER> | bash -s -- --tarball-url <URL_TO_TARBALL> --sha256 <HEX>

   For stronger guarantees, verify the GPG signature locally using the project's public key.

Installer GPG verification
-------------------------

The installer supports verifying a detached GPG signature and the project's public key during remote install. Pass the public key URL and signature URL when invoking the installer:

   curl -sSL <URL_TO_INSTALLER> | bash -s -- --tarball-url <URL_TO_TARBALL> --gpg-pubkey-url <URL_TO_PUBKEY_ASC> --sig-url <URL_TO_TARBALL_ASC>

This will import the provided ASCII-armored public key into a temporary GNUPGHOME and verify the detached signature against the downloaded tarball. The installer will abort if verification fails.

Notes
- Keep your signing key in a secure environment and rotate if compromised.
- Consider reproducing builds in a CI environment to ensure deterministic tarballs.
