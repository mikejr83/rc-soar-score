#!/usr/bin/env bash
# scripts/test-postgres.sh
# Starts a throwaway PostgreSQL container, runs the data package tests and the
# server's API slice tests against it (the SQLite and PostgreSQL groups), and removes the container, even when
# the tests fail. Needs Docker. Run from anywhere; exit code is the tests'.
#
#   ./scripts/test-postgres.sh
#   ./scripts/test-postgres.sh --port 55432
#   ./scripts/test-postgres.sh -- -n "unit of work"   # extra args go to dart test

set -u

usage() {
  echo "usage: $(basename "$0") [--port <port>] [-- <dart test args>]" >&2
}

image='postgres:17'
port=54329
test_args=()

while [ $# -gt 0 ]; do
  case "$1" in
    -p | --port)
      if [ $# -lt 2 ]; then
        usage
        exit 1
      fi
      port="$2"
      shift 2
      ;;
    --)
      shift
      test_args=("$@")
      break
      ;;
    *)
      usage
      exit 1
      ;;
  esac
done

if ! command -v docker >/dev/null 2>&1; then
  echo 'docker was not found on PATH.' >&2
  exit 1
fi
if ! docker info >/dev/null 2>&1; then
  echo 'The Docker daemon is not running.' >&2
  exit 1
fi

# Drop a leading "--" separator so `-- -n name` reaches dart test as `-n name`.
if [ ${#test_args[@]} -gt 0 ] && [ "${test_args[0]}" = '--' ]; then
  test_args=("${test_args[@]:1}")
fi

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
repo_root="$(dirname "$script_dir")"
data_package="$repo_root/packages/soar_score_data"
server_app="$repo_root/apps/soar_score_server"
container="soar-pg-test-$$"
password='dev'

# Save any caller-provided configuration so it can be restored in cleanup.
saved_password="${POSTGRES_PASSWORD-}"
saved_host="${POSTGRES_HOST-}"
saved_port="${POSTGRES_PORT-}"

cleanup() {
  if [ -n "$saved_password" ]; then
    POSTGRES_PASSWORD="$saved_password"
  else
    unset POSTGRES_PASSWORD
  fi
  if [ -n "$saved_host" ]; then
    POSTGRES_HOST="$saved_host"
  else
    unset POSTGRES_HOST
  fi
  if [ -n "$saved_port" ]; then
    POSTGRES_PORT="$saved_port"
  else
    unset POSTGRES_PORT
  fi
  if [ "$started" = 'true' ]; then
    echo "==> Removing $container"
    docker rm -f "$container" >/dev/null 2>&1
  fi
}
trap cleanup EXIT
started=false

echo "==> Starting $image as $container on 127.0.0.1:$port"
# Bound to localhost only; --rm removes the container when it stops.
if ! docker run -d --rm --name "$container" \
  -e "POSTGRES_PASSWORD=$password" \
  -p "127.0.0.1:${port}:5432" \
  "$image" >/dev/null; then
  echo "docker run failed (is port $port in use? use --port)." >&2
  exit 1
fi
started=true

echo '==> Waiting for PostgreSQL to accept connections'
# The image initialises over a unix socket first and only then listens on
# TCP, so check TCP (-h 127.0.0.1) to know it is really ready.
ready=false
for _ in $(seq 60); do
  if docker exec "$container" pg_isready -h 127.0.0.1 -U postgres >/dev/null 2>&1; then
    ready=true
    break
  fi
  sleep 1
done
if [ "$ready" != 'true' ]; then
  echo 'PostgreSQL did not become ready within 60 seconds.' >&2
  exit 1
fi

POSTGRES_PASSWORD="$password"
POSTGRES_HOST='localhost'
POSTGRES_PORT="$port"
export POSTGRES_PASSWORD POSTGRES_HOST POSTGRES_PORT

failed=false

echo '==> dart test (packages/soar_score_data)'
(cd "$data_package" && dart test "${test_args[@]}") || failed=true

# The server's API slice tests (invitations and others) run on SQLite and
# PostgreSQL; without POSTGRES_PASSWORD their PostgreSQL group is skipped.
# Extra dart test args apply to the data package only.
echo '==> dart test test/api_slice (apps/soar_score_server)'
(cd "$server_app" && dart test test/api_slice) || failed=true

if [ "$failed" = 'false' ]; then
  echo ''
  echo 'postgres tests PASSED'
  exit 0
fi
echo ''
echo 'postgres tests FAILED' >&2
exit 1
