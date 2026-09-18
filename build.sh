#!/usr/bin/env bash
set -euo pipefail

TARGET="${1:-web}"

cd apps/soar-score-api

flutter pub get
flutter build "$TARGET"

cd ../soar-score-contest

flutter pub get
flutter build "$TARGET"

cd ../soar-score-public

flutter pub get
flutter build "$TARGET"

echo "=== All projects built successfully ==="