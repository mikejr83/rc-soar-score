#!/usr/bin/env bash
set -euo pipefail

PROJECTS="score_soar_api score_soar_contest score_soar_public"
TARGET="${1:-web}"

if [ "$TARGET" != "web" ]; then
  echo "Usage: ./build.sh [web]"
  exit 1
fi

for project in $PROJECTS; do
  echo "=== Building $project ($TARGET) ==="
  cd "$project"
  flutter pub get
  flutter build "$TARGET" --release
  cd ..
done

echo "=== All projects built successfully ==="