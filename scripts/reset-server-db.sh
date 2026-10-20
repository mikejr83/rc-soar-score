#!/usr/bin/env bash
# scripts/reset-server-db.sh
# Empties the local server's PostgreSQL database by dropping and recreating
# its `public` schema (much quicker than dropping the database). The server
# rebuilds the tables the next time it starts. Local databases only.
#
# Reads POSTGRES_HOST, POSTGRES_PORT, POSTGRES_DB, POSTGRES_USER and
# POSTGRES_PASSWORD like the server. Stop the server first.
#
#   ./scripts/reset-server-db.sh            # uses psql on PATH
#   ./scripts/reset-server-db.sh --docker   # uses `docker compose exec db psql`
#   POSTGRES_CONTAINER=my-postgres ./scripts/reset-server-db.sh
#                                           # runs psql inside that container
#   ./scripts/reset-server-db.sh --force    # allow a host other than localhost
set -euo pipefail

host="${POSTGRES_HOST:-localhost}"
port="${POSTGRES_PORT:-5432}"
db="${POSTGRES_DB:-rc_soar_score}"
user="${POSTGRES_USER:-postgres}"
container="${POSTGRES_CONTAINER:-}"
docker=0
force=0
for arg in "$@"; do
  case "$arg" in
    --docker) docker=1 ;;
    --force) force=1 ;;
    *) echo "Unknown option: $arg" >&2; exit 2 ;;
  esac
done

if [ "$docker" = 0 ] && [ -z "$container" ] && [ "$force" = 0 ] &&
  [ "$host" != localhost ] && [ "$host" != 127.0.0.1 ] && [ "$host" != ::1 ]; then
  echo "Refusing to reset $host; it is not local. Pass --force if you mean it." >&2
  exit 1
fi

sql='DROP SCHEMA public CASCADE; CREATE SCHEMA public;'
echo "==> Resetting $db"
if [ -n "$container" ]; then
  # psql runs inside the container, so host, port and password do not apply.
  docker exec -i "$container" psql -U "$user" -d "$db" -v ON_ERROR_STOP=1 -c "$sql"
elif [ "$docker" = 1 ]; then
  docker compose exec -T db psql -U "$user" -d "$db" -v ON_ERROR_STOP=1 -c "$sql"
else
  command -v psql >/dev/null || { echo "psql was not found on PATH. Install the PostgreSQL client tools or use --docker." >&2; exit 1; }
  PGPASSWORD="${POSTGRES_PASSWORD:-${PGPASSWORD:-}}" \
    psql -h "$host" -p "$port" -U "$user" -d "$db" -v ON_ERROR_STOP=1 -c "$sql"
fi
echo "Done. Start the server to recreate the tables."
