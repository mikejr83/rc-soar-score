# scripts/reset-server-db.ps1
# Empties the local server's PostgreSQL database by dropping and recreating
# its `public` schema, which is much quicker than dropping the database. The
# server rebuilds the tables the next time it starts. Local databases only:
# a host other than localhost needs -Force.
#
# Connection settings come from the same variables the server reads
# (POSTGRES_HOST, POSTGRES_PORT, POSTGRES_DB, POSTGRES_USER,
# POSTGRES_PASSWORD) or the parameters below. Stop the server first; it holds
# connections open.
#
#   ./scripts/reset-server-db.ps1                 # uses psql on PATH
#   ./scripts/reset-server-db.ps1 -Docker         # uses `docker compose exec db psql`
#   $env:POSTGRES_CONTAINER = 'my-postgres'       # or -Container my-postgres:
#   ./scripts/reset-server-db.ps1                 # runs psql inside that container
#   ./scripts/reset-server-db.ps1 -Database rc_soar_score -Port 5432

param(
    [string]$PgHost = $(if ($env:POSTGRES_HOST) { $env:POSTGRES_HOST } else { 'localhost' }),
    [int]$Port = $(if ($env:POSTGRES_PORT) { [int]$env:POSTGRES_PORT } else { 5432 }),
    [string]$Database = $(if ($env:POSTGRES_DB) { $env:POSTGRES_DB } else { 'rc_soar_score' }),
    [string]$User = $(if ($env:POSTGRES_USER) { $env:POSTGRES_USER } else { 'postgres' }),
    # Name of a running Docker container to run psql in, instead of on this
    # machine. Set POSTGRES_CONTAINER to use it without the parameter.
    [string]$Container = $env:POSTGRES_CONTAINER,
    # Run psql inside the compose `db` container instead.
    [switch]$Docker,
    [switch]$Force
)

$ErrorActionPreference = 'Stop'

if (-not $Docker -and -not $Container -and $PgHost -notin 'localhost', '127.0.0.1', '::1' -and -not $Force) {
    Write-Host "Refusing to reset $PgHost; it is not local. Pass -Force if you mean it." -ForegroundColor Red
    exit 1
}

$sql = 'DROP SCHEMA public CASCADE; CREATE SCHEMA public;'
Write-Host "==> Resetting $Database" -ForegroundColor Cyan

if ($Container) {
    # psql runs inside the container, so host, port and password do not apply.
    docker exec -i $Container psql -U $User -d $Database -v ON_ERROR_STOP=1 -c $sql
} elseif ($Docker) {
    docker compose exec -T db psql -U $User -d $Database -v ON_ERROR_STOP=1 -c $sql
} else {
    if (-not (Get-Command psql -ErrorAction SilentlyContinue)) {
        Write-Host 'psql was not found on PATH. Install the PostgreSQL client tools or use -Docker.' -ForegroundColor Red
        exit 1
    }
    $savedPassword = $env:PGPASSWORD
    try {
        if ($env:POSTGRES_PASSWORD) { $env:PGPASSWORD = $env:POSTGRES_PASSWORD }
        psql -h $PgHost -p $Port -U $User -d $Database -v ON_ERROR_STOP=1 -c $sql
    } finally {
        $env:PGPASSWORD = $savedPassword
    }
}
if ($LASTEXITCODE -ne 0) {
    Write-Host 'Reset failed (is the server still running?).' -ForegroundColor Red
    exit $LASTEXITCODE
}
Write-Host 'Done. Start the server to recreate the tables.' -ForegroundColor Green
