# scripts/reset-server-db.ps1
# Empties the local server's PostgreSQL database by dropping and recreating
# its `public` schema, which is much quicker than dropping the database. The
# server rebuilds the tables the next time it starts. Local databases only:
# a host other than localhost needs -Force.
#
# Connection settings come from DATABASE_URL when it is set (it wins over the
# discrete variables and must name the database), or from the same variables
# the server reads (POSTGRES_HOST, POSTGRES_PORT, POSTGRES_DB, POSTGRES_USER,
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
$dbUrl = $env:DATABASE_URL
$uriDb = ''
$guardHost = $PgHost
if ($dbUrl) {
    $sep = $dbUrl.IndexOf('://')
    if ($sep -lt 0) {
        Write-Host 'DATABASE_URL is set but is not a postgres:// URL.' -ForegroundColor Red
        exit 1
    }
    $rest = $dbUrl.Substring($sep + 3)
    $slash = $rest.IndexOf('/')
    $authority = $rest
    $path = ''
    if ($slash -ge 0) {
        $authority = $rest.Substring(0, $slash)
        $path = $rest.Substring($slash + 1)
    }
    $query = $path.IndexOf('?')
    if ($query -ge 0) {
        $path = $path.Substring(0, $query)
    }
    $at = $authority.LastIndexOf('@')
    $hostPort = $authority
    if ($at -ge 0) {
        $hostPort = $authority.Substring($at + 1)
    }
    if ($hostPort.StartsWith('[')) {
        # Bracketed IPv6 host, e.g. [::1]:5432.
        $uriHost = $hostPort.Substring(1, $hostPort.IndexOf(']') - 1)
    } else {
        $uriHost = $hostPort.Split([char] ':', 2)[0]
    }
    $uriDb = $path
    if ($uriDb -eq '') {
        Write-Host 'DATABASE_URL does not name a database; put it in the URL, e.g. postgresql://user:password@host/db' -ForegroundColor Red
        exit 1
    }
    $guardHost = $uriHost
}

if (-not $Docker -and -not $Container -and $guardHost -notin 'localhost', '127.0.0.1', '::1' -and -not $Force) {
    Write-Host "Refusing to reset $guardHost; it is not local. Pass -Force if you mean it." -ForegroundColor Red
    exit 1
}

$sql = 'DROP SCHEMA public CASCADE; CREATE SCHEMA public;'
Write-Host "==> Resetting $(if ($dbUrl) { $uriDb } else { $Database })" -ForegroundColor Cyan

if ($Container) {
    # psql runs inside the container, so host, port and password do not
    # apply; the URL names them all, or the parameters do.
    if ($dbUrl) {
        docker exec -i -e "PGCONNECT_URI=$dbUrl" $Container psql -v ON_ERROR_STOP=1 -c $sql
    } else {
        docker exec -i $Container psql -U $User -d $Database -v ON_ERROR_STOP=1 -c $sql
    }
} elseif ($Docker) {
    if ($dbUrl) {
        docker compose exec -T -e "PGCONNECT_URI=$dbUrl" db psql -v ON_ERROR_STOP=1 -c $sql
    } else {
        docker compose exec -T db psql -U $User -d $Database -v ON_ERROR_STOP=1 -c $sql
    }
} else {
    if (-not (Get-Command psql -ErrorAction SilentlyContinue)) {
        Write-Host 'psql was not found on PATH. Install the PostgreSQL client tools or use -Docker.' -ForegroundColor Red
        exit 1
    }
    $savedUri = $env:PGCONNECT_URI
    $savedPassword = $env:PGPASSWORD
    try {
        if ($dbUrl) {
            $env:PGCONNECT_URI = $dbUrl
            psql -v ON_ERROR_STOP=1 -c $sql
        } else {
            if ($env:POSTGRES_PASSWORD) {
                $env:PGPASSWORD = $env:POSTGRES_PASSWORD
            }
            psql -h $PgHost -p $Port -U $User -d $Database -v ON_ERROR_STOP=1 -c $sql
        }
    } finally {
        $env:PGCONNECT_URI = $savedUri
        $env:PGPASSWORD = $savedPassword
    }
}
if ($LASTEXITCODE -ne 0) {
    Write-Host 'Reset failed (is the server still running?).' -ForegroundColor Red
    exit $LASTEXITCODE
}
Write-Host 'Done. Start the server to recreate the tables.' -ForegroundColor Green
