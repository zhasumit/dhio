#!/usr/bin/env bash
set -euo pipefail

echo "Running tests..."
DIR=$(cd "$(dirname "$0")" && pwd)
bash "$DIR/test_encryption.sh"

echo "All tests passed"
