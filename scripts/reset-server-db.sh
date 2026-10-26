#!/usr/bin/env bash
# scripts/reset-server-db.sh
# Empties the local server's PostgreSQL database by dropping and recreating
# its `public` schema (much quicker than dropping the database). The server
# rebuilds the tables the next time it starts. Local databases only.
#
# Reads DATABASE_URL when it is set (it wins over the discrete variables and
# must name the database), or POSTGRES_HOST, POSTGRES_PORT, POSTGRES_DB,
# POSTGRES_USER and POSTGRES_PASSWORD like the server. Stop the server first.
#
#   ./scripts/reset-server-db.sh            # uses psql on PATH
#   ./scripts/reset-server-db.sh --docker   # uses `docker compose exec db psql`
#   POSTGRES_CONTAINER=my-postgres ./scripts/reset-server-db.sh
#                                           # runs psql inside that container
#   ./scripts/reset-server-db.sh --force    # allow a host other than localhost
set -euo pipefail

db_url="${DATABASE_URL:-}"
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

guard_host="$host"
uri_db=""
if [ -n "$db_url" ]; then
  case "$db_url" in
  *://*) ;;
  *) echo "DATABASE_URL is set but is not a postgres:// URL." >&2; exit 1 ;;
  esac
  rest="${db_url#*://}"
  case "$rest" in
  */*) authority="${rest%%/*}"; path="${rest#*/}" ;;
  *) authority="$rest"; path="" ;;
  esac
  case "$path" in
  *'?'*) path="${path%%'?'*}" ;;
  esac
  case "$authority" in
  *@*) hostport="${authority##*@}" ;;
  *) hostport="$authority" ;;
  esac
  if [ "${hostport:0:1}" = '[' ]; then
    # Bracketed IPv6 host, e.g. [::1]:5432.
    uri_host="${hostport#?}"
    uri_host="${uri_host%%\]*}"
  else
    uri_host="${hostport%%:*}"
  fi
  if [ -z "$path" ]; then
    echo "DATABASE_URL does not name a database; put it in the URL, e.g. postgresql://user:password@host/db" >&2
    exit 1
  fi
  guard_host="$uri_host"
  uri_db="$path"
fi

if [ "$docker" = 0 ] && [ -z "$container" ] && [ "$force" = 0 ] &&
  [ "$guard_host" != localhost ] && [ "$guard_host" != 127.0.0.1 ] &&
  [ "$guard_host" != ::1 ]; then
  echo "Refusing to reset $guard_host; it is not local. Pass --force if you mean it." >&2
  exit 1
fi

sql='DROP SCHEMA public CASCADE; CREATE SCHEMA public;'
if [ -n "$db_url" ]; then
  echo "==> Resetting $uri_db"
else
  echo "==> Resetting $db"
fi
if [ -n "$container" ]; then
  # psql runs inside the container, so host, port and password do not
  # apply; the URL names them all, or the variables do.
  if [ -n "$db_url" ]; then
    docker exec -i -e "PGCONNECT_URI=$db_url" "$container" psql -v ON_ERROR_STOP=1 -c "$sql"
  else
    docker exec -i "$container" psql -U "$user" -d "$db" -v ON_ERROR_STOP=1 -c "$sql"
  fi
elif [ "$docker" = 1 ]; then
  if [ -n "$db_url" ]; then
    docker compose exec -T -e "PGCONNECT_URI=$db_url" db psql -v ON_ERROR_STOP=1 -c "$sql"
  else
    docker compose exec -T db psql -U "$user" -d "$db" -v ON_ERROR_STOP=1 -c "$sql"
  fi
else
  command -v psql >/dev/null || { echo "psql was not found on PATH. Install the PostgreSQL client tools or use --docker." >&2; exit 1; }
  if [ -n "$db_url" ]; then
    PGCONNECT_URI="$db_url" psql -v ON_ERROR_STOP=1 -c "$sql"
  else
    PGPASSWORD="${POSTGRES_PASSWORD:-${PGPASSWORD:-}}" \
      psql -h "$host" -p "$port" -U "$user" -d "$db" -v ON_ERROR_STOP=1 -c "$sql"
  fi
fi
echo "Done. Start the server to recreate the tables."
