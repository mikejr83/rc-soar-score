#!/usr/bin/env bash
# scripts/e2e.sh
# Runs the contest app's end-to-end tests (Flutter integration_test) against
# the real app on the demo database, which is recreated for every run.
# Not part of CI (Actions has no credits); run it locally while testing.
#
#   ./scripts/e2e.sh                 # Windows desktop (default on Windows)
#   ./scripts/e2e.sh -d chrome       # any other `flutter test -d` device
#   ./scripts/e2e.sh -- --name journey   # extra args go to flutter test
set -eu
device=windows
extra=()
while [ $# -gt 0 ]; do
  case "$1" in
    -d | --device) device="$2"; shift 2 ;;
    --) shift; extra=("$@"); break ;;
    *) echo "usage: $(basename "$0") [-d <device>] [-- <flutter test args>]" >&2; exit 1 ;;
  esac
done
cd "$(dirname "$0")/../apps/soar_score_contest"
# One flutter test run per file: the Windows app allows a single instance, and
# a second file's launch fails while the previous run's app is still alive.
status=0
for file in integration_test/*_test.dart; do
  flutter test "$file" -d "$device"     --dart-define=SOAR_SCORE_DEMO=true     --dart-define=SOAR_SCORE_DEMO_RESET=true     ${extra[@]+"${extra[@]}"} || status=1
done
exit $status
