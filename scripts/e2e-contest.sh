#!/usr/bin/env bash
# scripts/e2e-contest.sh
# Runs the contest app's end-to-end tests (Flutter integration_test) against
# the real app on the demo data, which is recreated for every run.
# Not part of CI (Actions has no credits); run it locally or from an agent.
#
#   ./scripts/e2e-contest.sh                 # Windows desktop (default on Windows)
#   ./scripts/e2e-contest.sh -d web          # headless Chrome against the E2E server
#   ./scripts/e2e-contest.sh -d <device>     # any other `flutter test -d` device
#   ./scripts/e2e-contest.sh -f save_failure_retry_test.dart -- --name 'Retry saves'
#   ./scripts/e2e-contest.sh -- --name journey   # extra args go to flutter test/drive
#
# The web mode needs Chrome and a matching chromedriver. Run
# ./scripts/e2e-setup.sh once to install both into .e2e-tools/ (git-ignored),
# where this script finds them; or put `chromedriver` on PATH, or set
# CHROMEDRIVER=<path> (and CHROME_EXECUTABLE=<path>). It builds the app with SOAR_SCORE_E2E=true
# (an always-signed-in session) and points it at
# apps/soar_score_server/tool/e2e_server.dart, a token-free API server on
# demo data. Each test file gets a fresh server, hence fresh demo data.
# The renderer (CanvasKit) is bundled with the app (--no-web-resources-cdn), so
# a run needs no access to gstatic.com, which sandboxed networks block (the
# page would stay blank until the test timed out).
# A test file that runs longer than E2E_TEST_TIMEOUT seconds (default 300) is
# stopped and counted as failed, so a hung browser cannot stall a run. The
# long contest_lifecycle_journey_test.dart gets 1800 seconds by default;
# setting E2E_TEST_TIMEOUT overrides the limit for every file. These limits
# apply to web runs only; a Windows (native) run has no timeout.
set -eu
# E2E_STOP_AFTER=<n> ends the lifecycle journey after phase n.
stop_after=()
[ -z "${E2E_STOP_AFTER:-}" ] || stop_after=(--dart-define=E2E_STOP_AFTER="$E2E_STOP_AFTER")
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
root="$(cd "$(dirname "$0")/.." && pwd)"
cd "$root/apps/soar_score_contest"
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

if [ "$device" = web ] || [ "$device" = chrome ]; then
  port="${E2E_SERVER_PORT:-18080}"
  driver_port=4444
  # Chrome and chromedriver from scripts/e2e-setup.sh, unless the environment
  # already names them.
  tools="$root/.e2e-tools"
  if [ -f "$tools/paths.env" ]; then
    [ -n "${CHROMEDRIVER:-}" ] || CHROMEDRIVER="$tools/$(sed -n 's/^chromedriver=//p' "$tools/paths.env" | tr -d '\r')"
    [ -n "${CHROME_EXECUTABLE:-}" ] || CHROME_EXECUTABLE="$tools/$(sed -n 's/^chrome=//p' "$tools/paths.env" | tr -d '\r')"
  fi
  chromedriver="${CHROMEDRIVER:-chromedriver}"
  # Chrome refuses to start as root (a container, a cloud agent) without
  # --no-sandbox, so run it through a small wrapper that adds the flag.
  if [ -n "${CHROME_EXECUTABLE:-}" ] && [ "$(id -u)" = 0 ]; then
    mkdir -p "$tools"
    wrapper="$tools/chrome-no-sandbox.sh"
    printf '#!/bin/sh\nexec "%s" --no-sandbox --disable-dev-shm-usage "$@"\n' "$CHROME_EXECUTABLE" >"$wrapper"
    chmod +x "$wrapper"
    CHROME_EXECUTABLE="$wrapper"
  fi
  chrome_args=()
  [ -z "${CHROME_EXECUTABLE:-}" ] || chrome_args=(--chrome-binary="$CHROME_EXECUTABLE")
  server_pid=""
  driver_pid=""
  echo_pid=""
  stop_server() {
    if [ -n "$echo_pid" ]; then kill "$echo_pid" 2>/dev/null || true; echo_pid=""; fi
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
    server_args=()
    [ "$(basename "$file")" != contest_lifecycle_journey_test.dart ] || server_args+=(--publishing)
    (cd "$root/apps/soar_score_server" && exec dart run tool/e2e_server.dart --port "$port" "${server_args[@]}") >"$log" 2>&1 &
    server_pid=$!
    for _ in $(seq 1 120); do
      if grep -q E2E_SERVER_READY "$log"; then
        # A browser journey prints nothing live; it posts its progress to the
        # server (`POST /__e2e/log`), whose `[E2E]` lines are echoed here.
        tail -n +1 -f "$log" 2>/dev/null | grep --line-buffered '^\[E2E\]' &
        echo_pid=$!
        return 0
      fi
      kill -0 "$server_pid" 2>/dev/null || break
      sleep 1
    done
    cat "$log" >&2
    echo "E2E server did not start" >&2
    exit 1
  }
  # Seconds a file may run: E2E_TEST_TIMEOUT for all files, else 1800 for the
  # lifecycle journey and 300 for the rest.
  timeout_for() {
    if [ -n "${E2E_TEST_TIMEOUT:-}" ]; then echo "$E2E_TEST_TIMEOUT"
    elif [ "$(basename "$1")" = contest_lifecycle_journey_test.dart ]; then echo 1800
    else echo 300; fi
  }
  if ! command -v "$chromedriver" >/dev/null 2>&1; then
    echo "chromedriver not found ('$chromedriver'). Run ./scripts/e2e-setup.sh to install Chrome and chromedriver, or set CHROMEDRIVER=<path>." >&2
    exit 1
  fi
  "$chromedriver" --port=$driver_port >/dev/null 2>&1 &
  driver_pid=$!
  # Fail fast when chromedriver cannot serve (port taken, version mismatch),
  # instead of letting flutter drive wait for it.
  ready=
  for _ in $(seq 1 20); do
    if curl -sf "http://localhost:$driver_port/status" >/dev/null 2>&1; then ready=1; break; fi
    kill -0 "$driver_pid" 2>/dev/null || break
    sleep 0.5
  done
  if [ -z "$ready" ]; then
    echo "chromedriver did not answer on port $driver_port (is another one running?)." >&2
    exit 1
  fi
  status=0
  for file in "${files[@]}"; do
    test_timeout="$(timeout_for "$file")"
    with_timeout=()
    if command -v timeout >/dev/null 2>&1; then
      with_timeout=(timeout --kill-after=10 "$test_timeout")
    fi
    start_server
    "${with_timeout[@]+"${with_timeout[@]}"}" flutter drive --driver=test_driver/integration_test.dart --target="$file" \
      -d web-server --browser-name=chrome ${chrome_args[@]+"${chrome_args[@]}"} \
      --no-web-resources-cdn \
      --dart-define=SOAR_SCORE_E2E=true \
      --dart-define=SOAR_SCORE_API_BASE_URL="http://localhost:$port" \
      $( [ "$(basename "$file")" = "signed_out_landing_journey_test.dart" ] && printf '%s' '--dart-define=SOAR_SCORE_E2E_SIGNED_OUT=true' ) \
      ${stop_after[@]+"${stop_after[@]}"} ${extra[@]+"${extra[@]}"} || {
        code=$?
        [ "$code" -eq 124 ] && echo "TIMEOUT: $file ran longer than ${test_timeout}s and was stopped." >&2
        status=1
      }
    stop_server
  done
  exit $status
fi

# One flutter test run per file: the Windows app allows a single instance, and
# a second file's launch fails while the previous run's app is still alive.
status=0
for file in "${files[@]}"; do
  e2e_args=(--dart-define=SOAR_SCORE_DEMO=true --dart-define=SOAR_SCORE_DEMO_RESET=true)
  [ "$(basename "$file")" = "signed_out_landing_journey_test.dart" ] && e2e_args+=(--dart-define=SOAR_SCORE_E2E_SIGNED_OUT=true)
  [ "$(basename "$file")" = "matrix_draw_cancel_test.dart" ] && e2e_args+=(--dart-define=SOAR_SCORE_E2E_SLOW_DRAW=true)
  flutter test "$file" -d "$device" "${e2e_args[@]}" ${stop_after[@]+"${stop_after[@]}"} ${extra[@]+"${extra[@]}"} || status=1
done
exit $status
