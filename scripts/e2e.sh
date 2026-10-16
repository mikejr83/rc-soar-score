#!/usr/bin/env bash
# scripts/e2e.sh
# Runs the contest app's end-to-end tests (Flutter integration_test) against
# the real app on the demo data, which is recreated for every run.
# Not part of CI (Actions has no credits); run it locally or from an agent.
#
#   ./scripts/e2e.sh                 # Windows desktop (default on Windows)
#   ./scripts/e2e.sh -d web          # headless Chrome against the E2E server
#   ./scripts/e2e.sh -d <device>     # any other `flutter test -d` device
#   ./scripts/e2e.sh -- --name journey   # extra args go to flutter test/drive
#
# The web mode needs Chrome and a matching chromedriver (`chromedriver` on
# PATH, or CHROMEDRIVER=<path>). It builds the app with SOAR_SCORE_E2E=true
# (an always-signed-in session) and points it at
# apps/soar_score_server/tool/e2e_server.dart, a token-free API server on
# demo data. Each test file gets a fresh server, hence fresh demo data.
set -eu
device=windows
extra=()
while [ $# -gt 0 ]; do
  case "$1" in
    -d | --device) device="$2"; shift 2 ;;
    --) shift; extra=("$@"); break ;;
    *) echo "usage: $(basename "$0") [-d <device>] [-- <flutter args>]" >&2; exit 1 ;;
  esac
done
root="$(cd "$(dirname "$0")/.." && pwd)"
cd "$root/apps/soar_score_contest"

if [ "$device" = web ] || [ "$device" = chrome ]; then
  port="${E2E_SERVER_PORT:-18080}"
  driver_port=4444
  chromedriver="${CHROMEDRIVER:-chromedriver}"
  server_pid=""
  driver_pid=""
  stop_server() {
    if [ -n "$server_pid" ]; then kill "$server_pid" 2>/dev/null || true; wait "$server_pid" 2>/dev/null || true; fi
    server_pid=""
  }
  cleanup() {
    stop_server
    if [ -n "$driver_pid" ]; then kill "$driver_pid" 2>/dev/null || true; fi
  }
  trap cleanup EXIT
  start_server() {
    log="$(mktemp)"
    (cd "$root/apps/soar_score_server" && exec dart run tool/e2e_server.dart --port "$port") >"$log" 2>&1 &
    server_pid=$!
    for _ in $(seq 1 120); do
      grep -q E2E_SERVER_READY "$log" && return 0
      kill -0 "$server_pid" 2>/dev/null || break
      sleep 1
    done
    cat "$log" >&2
    echo "E2E server did not start" >&2
    exit 1
  }
  "$chromedriver" --port=$driver_port >/dev/null 2>&1 &
  driver_pid=$!
  status=0
  for file in integration_test/*_test.dart; do
    start_server
    flutter drive --driver=test_driver/integration_test.dart --target="$file" \
      -d web-server --browser-name=chrome \
      --dart-define=SOAR_SCORE_E2E=true \
      --dart-define=SOAR_SCORE_API_BASE_URL="http://localhost:$port" \
      ${extra[@]+"${extra[@]}"} || status=1
    stop_server
  done
  exit $status
fi

# One flutter test run per file: the Windows app allows a single instance, and
# a second file's launch fails while the previous run's app is still alive.
status=0
for file in integration_test/*_test.dart; do
  flutter test "$file" -d "$device"     --dart-define=SOAR_SCORE_DEMO=true     --dart-define=SOAR_SCORE_DEMO_RESET=true     ${extra[@]+"${extra[@]}"} || status=1
done
exit $status
