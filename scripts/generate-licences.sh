#!/usr/bin/env bash
# Regenerates apps/soar_score_web/src/content/licences.json, the data behind
# the /open-source page (#687), from pubspec.lock and package-lock.json.
#
# Prerequisites: `dart pub get` (or `melos bootstrap`) and `npm ci` in
# apps/soar_score_web, so the pub cache and node_modules hold the licence texts.
#
#   scripts/generate-licences.sh                    write the JSON
#   scripts/generate-licences.sh --check            fail if it is stale
#   scripts/generate-licences.sh --product contest-app --notices FILE
#                                                   plain-text notices for one product
set -euo pipefail
cd "$(dirname "$0")/.."
exec dart scripts/generate_licences.dart "$@"
