#!/usr/bin/env bash
set -euo pipefail

TARGET="${1:-web}"

cd apps/score-soar-api

flutter pub get
flutter build "$TARGET"

cd ../score-soar-contest

flutter pub get
flutter build "$TARGET"

cd ../score-soar-public

flutter pub get
flutter build "$TARGET"

echo "=== All projects built successfully ==="