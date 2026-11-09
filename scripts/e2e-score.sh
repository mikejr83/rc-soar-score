#!/usr/bin/env bash
# scripts/e2e-score.sh
# Runs the self-scoring app's end-to-end tests (Flutter integration_test) in
# headless Chrome against the real web build and a real API: the token-free
# apps/soar_score_server/tool/e2e_server.dart on a fresh database, with
# invitations on. The contest app has its own script, e2e-contest.sh.
# Not part of CI (Actions has no credits); run it locally or from an agent.
#
#   ./scripts/e2e-score.sh                     # every file in integration_test
#   ./scripts/e2e-score.sh -f self_score_lifecycle_journey_test.dart
#   E2E_STOP_AFTER=3 ./scripts/e2e-score.sh    # end the journey after phase 3
#   ./scripts/e2e-score.sh -- --dart-define=E2E_SCREENSHOTS=steps
#
# The self-scoring app is a web app, so there is no device option. Needs
# Chrome and a matching chromedriver: run ./scripts/e2e-setup.sh once (they
# go into .e2e-tools/, which git ignores), or put chromedriver on PATH, or
# set CHROMEDRIVER=<path> (and CHROME_EXECUTABLE=<path>).
# Each test file gets a fresh server, hence a fresh database. A file that runs
# longer than E2E_TEST_TIMEOUT seconds (default 900) is stopped and counted as
# failed, so a hung browser cannot stall a run.
set -eu
stop_after=()
[ -z "${E2E_STOP_AFTER:-}" ] || stop_after=(--dart-define=E2E_STOP_AFTER="$E2E_STOP_AFTER")
test_file=
extra=()
while [ $# -gt 0 ]; do
  case "$1" in
    -f | --file) test_file="$2"; shift 2 ;;
    --) shift; extra=("$@"); break ;;
    *) echo "usage: $(basename "$0") [-f <test-file>] [-- <flutter drive args>]" >&2; exit 1 ;;
  esac
done
root="$(cd "$(dirname "$0")/.." && pwd)"
cd "$root/apps/soar_score_self_score"
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

port="${E2E_SERVER_PORT:-18080}"
driver_port=4444
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
  (cd "$root/apps/soar_score_server" && exec dart run tool/e2e_server.dart --port "$port" --profile server) >"$log" 2>&1 &
  server_pid=$!
  for _ in $(seq 1 120); do
    if grep -q E2E_SERVER_READY "$log"; then
      # The journey posts its progress to the server (`POST /__e2e/log`),
      # whose `[E2E]` lines are echoed here.
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
test_timeout="${E2E_TEST_TIMEOUT:-900}"
if ! command -v "$chromedriver" >/dev/null 2>&1; then
  echo "chromedriver not found ('$chromedriver'). Run ./scripts/e2e-setup.sh to install Chrome and chromedriver, or set CHROMEDRIVER=<path>." >&2
  exit 1
fi
"$chromedriver" --port=$driver_port >/dev/null 2>&1 &
driver_pid=$!
# Fail fast when chromedriver cannot serve (port taken, version mismatch).
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
  with_timeout=()
  if command -v timeout >/dev/null 2>&1; then
    with_timeout=(timeout --kill-after=10 "$test_timeout")
  fi
  start_server
  "${with_timeout[@]+"${with_timeout[@]}"}" flutter drive --driver=test_driver/integration_test.dart --target="$file" \
    -d web-server --browser-name=chrome ${chrome_args[@]+"${chrome_args[@]}"} \
    --no-web-resources-cdn \
    --dart-define=SOAR_SCORE_API_BASE_URL="http://localhost:$port" \
    ${stop_after[@]+"${stop_after[@]}"} ${extra[@]+"${extra[@]}"} || {
      code=$?
      [ "$code" -eq 124 ] && echo "TIMEOUT: $file ran longer than ${test_timeout}s and was stopped." >&2
      status=1
    }
  stop_server
done
exit $status
