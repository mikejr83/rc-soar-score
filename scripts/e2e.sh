#!/usr/bin/env bash
# scripts/e2e.sh
# Runs the contest app's end-to-end tests (Flutter integration_test) against
# the real app on the demo database, which is recreated for every run.
# Not part of CI (Actions has no credits); run it locally while testing.
#
#   ./scripts/e2e.sh                 # Windows desktop (default on Windows)
#   ./scripts/e2e.sh -d chrome       # any other `flutter test -d` device
#   ./scripts/e2e.sh -f score_entry_test.dart -- --name 'official score entry'
#   ./scripts/e2e.sh -- --name journey   # extra args go to flutter test
set -eu
device=windows
test_file=
extra=()
while [ $# -gt 0 ]; do
  case "$1" in
    -d | --device) device="$2"; shift 2 ;;
    -f | --file) test_file="$2"; shift 2 ;;
    --) shift; extra=("$@"); break ;;
    *) echo "usage: $(basename "$0") [-d <device>] [-f <test-file>] [-- <flutter test args>]" >&2; exit 1 ;;
  esac
done
cd "$(dirname "$0")/../apps/soar_score_contest"
if [ -n "$test_file" ]; then
  case "$test_file" in
    */* | *\\*) echo "-f expects a test filename, not a path: $test_file" >&2; exit 1 ;;
  esac
  case "$test_file" in
    *_test.dart) ;;
    *) echo "-f expects an *_test.dart filename: $test_file" >&2; exit 1 ;;
  esac
  if [ ! -f "integration_test/$test_file" ]; then
    echo "No E2E test file named '$test_file' found in integration_test." >&2
    exit 1
  fi
  files=("integration_test/$test_file")
else
  files=(integration_test/*_test.dart)
fi
# One flutter test run per file: the Windows app allows a single instance, and
# a second file's launch fails while the previous run's app is still alive.
status=0
for file in "${files[@]}"; do
  flutter test "$file" -d "$device"     --dart-define=SOAR_SCORE_DEMO=true     --dart-define=SOAR_SCORE_DEMO_RESET=true     ${extra[@]+"${extra[@]}"} || status=1
done
exit $status
