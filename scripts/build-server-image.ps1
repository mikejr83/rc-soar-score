# scripts/build-server-image.ps1
# Builds the API server image (apps/soar_score_server/Dockerfile) as
# local/rc-soar-score-server with a version tag, tags it `latest`, keeps
# only the three newest versions of that image (deleting older ones), and
# offers to run the result as container rc-soar-score-api, removing any
# container that already has that name first.
#
#   ./scripts/build-server-image.ps1
#   ./scripts/build-server-image.ps1 -Tag 2026.11.2   # explicit version tag
#   ./scripts/build-server-image.ps1 -Start           # run the container without asking
#   ./scripts/build-server-image.ps1 -NoStart         # build only, never ask
#   ./scripts/build-server-image.ps1 -Port 9090       # publish the API on another port
#   ./scripts/build-server-image.ps1 -Network <compose network>
#       # attach to the docker compose network so POSTGRES_HOST=db reaches db
#
# Container environment comes from your environment (the variables the
# server reads, see lib/config/server_config.dart), falling back to the same
# defaults as docker-compose.yml. A DATABASE_URL in your environment wins
# over the discrete POSTGRES_* variables.
#
# Database connection: with no -Network, the container reaches the database
# at host.docker.internal (the Docker Desktop alias for this machine), so the
# Postgres it uses must listen on that interface. To use the docker compose
# `db` container instead, pass -Network with the compose network name
# (POSTGRES_HOST becomes `db`).

param(
    # Version tag for the new image. Defaults to a timestamp (yyyyMMdd-HHmmss).
    [string]$Tag = '',
    # Host port to publish the API on. The container listens on 8080.
    [int]$Port = 8080,
    # Docker network to attach the container to.
    [string]$Network = '',
    # Start the container without asking.
    [switch]$Start,
    # Never start the container.
    [switch]$NoStart
)

$ErrorActionPreference = 'Stop'

$repoRoot = Split-Path -Parent $PSScriptRoot
$image = 'local/rc-soar-score-server'
$container = 'rc-soar-score-api'
$containerPort = 8080
$keep = 3

if (-not (Get-Command docker -ErrorAction SilentlyContinue)) {
    Write-Host 'docker was not found on PATH. Install Docker Desktop (or Docker Engine) first.' -ForegroundColor Red
    exit 1
}
if ($Start -and $NoStart) {
    Write-Host 'Pass -Start or -NoStart, not both.' -ForegroundColor Red
    exit 1
}

if ($Tag -eq '') { $Tag = Get-Date -Format 'yyyyMMdd-HHmmss' }

# 1. Build the image.
Write-Host "==> Building ${image}:$Tag" -ForegroundColor Cyan
docker build --progress=plain -f "$repoRoot\apps\soar_score_server\Dockerfile" -t "${image}:$Tag" "$repoRoot" 2>&1 | Tee-Object -Variable buildOutput
if ($LASTEXITCODE -ne 0) {
    Write-Host ''
    Write-Host "Build failed (docker build exited with $LASTEXITCODE). Last lines of output:" -ForegroundColor Red
    $buildOutput | Select-Object -Last 50 | ForEach-Object { Write-Host $_ }
    exit $LASTEXITCODE
}
Write-Host "Built ${image}:$Tag" -ForegroundColor Green

# 2. Tag the new image as latest.
Write-Host "==> Tagging ${image}:latest" -ForegroundColor Cyan
$tagResult = docker tag "${image}:$Tag" "${image}:latest" 2>&1
if ($LASTEXITCODE -ne 0) {
    Write-Host 'docker tag failed:' -ForegroundColor Red
    $tagResult | Write-Host
    exit $LASTEXITCODE
}

# 3. Enumerate the versions of the image and keep the three newest.
# `latest` and the new version tag share one image ID, so rows are grouped by
# ID. `docker images` prints creation times in a locale-dependent format
# (and rebuilds of unchanged code reuse the first build's timestamp, so
# several images can share one), so each distinct ID's real creation time is
# read with `docker inspect` instead, in UTC.
Write-Host "==> Versions of ${image}:" -ForegroundColor Cyan
$lines = docker images --no-trunc "$image" --format '{{.ID}}|{{.Tag}}'
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

$versions = @{}
foreach ($line in $lines) {
    if ([string]::IsNullOrWhiteSpace($line)) { continue }
    $parts = $line.Split('|')
    $id = $parts[0]
    if (-not $versions.ContainsKey($id)) { $versions[$id] = New-Object System.Collections.Generic.List[string] }
    $versions[$id].Add($parts[1])
}
$versions = @($versions.Keys | ForEach-Object {
    [pscustomobject]@{ Id = $_; Tags = @($versions[$_]) }
})

# The image built in this run carries the `latest` tag; it always sorts first
# so it is always kept. Each other image sorts by its version tag (the tag
# that is not `latest`), which is a timestamp and therefore chronological.
# A tag that is not a timestamp sorts after the timestamps (it is never newer
# than one the script just built).
function SortKey($v) {
    $version = $v.Tags | Where-Object { $_ -ne 'latest' } | Select-Object -First 1
    if (-not $version) { $version = 'latest' }
    $rank = if ($version -match '^\d{8}-\d{6}$') { 1 } else { 0 }
    $latest = if ('latest' -in $v.Tags) { 1 } else { 0 }
    "$latest|$rank|$version"
}
$versions = @($versions | Sort-Object -Property @{ Expression = { SortKey $_ }; Descending = $true })
foreach ($v in $versions) {
    $created = (docker inspect --format '{{.Created}}' $v.Id 2>&1 | Select-Object -First 1)
    if ($LASTEXITCODE -ne 0) {
        Write-Host "Could not read the creation time of $($v.Id): $created" -ForegroundColor Red
    }
    Write-Host ("  {0}  {1}  {2}" -f $v.Id.Substring(0, 12), $created, ($v.Tags -join ', '))
}

# 4. Delete the older versions and report them.
$toRemove = @($versions | Select-Object -Skip $keep)
if ($toRemove.Count -eq 0) {
    Write-Host "Nothing to delete; all $($versions.Count) version(s) kept (max $keep)."
} else {
    Write-Host "Keeping the $keep newest of $($versions.Count) version(s)."
    foreach ($v in $toRemove) {
        $tagList = $v.Tags -join ', '
        $rm = docker rmi -f $v.Id 2>&1
        if ($LASTEXITCODE -ne 0) {
            Write-Host "Could not delete $($v.Id) ($tagList):" -ForegroundColor Red
            $rm | Write-Host
        } else {
            Write-Host "Deleted $($v.Id) ($tagList)." -ForegroundColor Green
        }
    }
}

# 5. Offer to start the container.
Write-Host ''
if ($NoStart) {
    Write-Host 'Not starting the container (-NoStart).'
    exit 0
}
if ($Start) {
    $startIt = $true
} else {
    $answer = Read-Host "Start ${image}:latest as container '$container' on port $Port? [Y/n]"
    if ([string]::IsNullOrWhiteSpace($answer)) {
        $startIt = $true
    } else {
        $startIt = $answer -match '^\s*[Yy](\s*|es)?\s*$'
    }
}
if (-not $startIt) {
    Write-Host 'Not starting the container.'
    exit 0
}

# 6. Remove any container that already has that name, then start the new one.
$existing = docker ps -a --filter "name=$container" --format '{{.Names}}' | Where-Object { $_ -eq $container }
if ($existing) {
    Write-Host "Removing existing container '$container'" -ForegroundColor Cyan
    $rmc = docker rm -f $container 2>&1
    if ($LASTEXITCODE -ne 0) {
        Write-Host 'docker rm failed:' -ForegroundColor Red
        $rmc | Write-Host
        exit $LASTEXITCODE
    }
}

$dbUrl = $env:DATABASE_URL
$envArgs = @()
$envVars = [ordered]@{
    LOG_LEVEL            = 'INFO'
    LOG_FORMAT           = 'text'
    POSTGRES_HOST        = $(if ($Network) { 'db' } else { 'host.docker.internal' })
    POSTGRES_PORT        = '5432'
    POSTGRES_DB          = 'rc_soar_score'
    POSTGRES_USER        = 'postgres'
    POSTGRES_PASSWORD    = 'soar-dev-only'
    AUTH0_DOMAIN         = 'login.rcsoarscore.com'
    API_AUDIENCE         = 'https://soar-score.com/server'
    CORS_ALLOWED_ORIGINS = 'http://127.0.0.1:8091,http://localhost:8091'
}
foreach ($key in $envVars.Keys) {
    if ($dbUrl -and $key.StartsWith('POSTGRES_')) { continue }
    $envItem = Get-Item "env:$key" -ErrorAction SilentlyContinue
    $value = if ($envItem) { $envItem.Value } else { '' }
    if (-not $value) { $value = $envVars[$key] }
    $envArgs += @('-e', "$key=$value")
}
if ($dbUrl) {
    $envArgs += @('-e', "DATABASE_URL=$dbUrl")
}

$runArgs = @('-d', '--name', $container, '-p', "${Port}:${containerPort}")
if ($Network) { $runArgs += @('--network', $Network) }
$runArgs += $envArgs
$runArgs += "${image}:latest"

Write-Host "==> Starting container '$container' on port $Port" -ForegroundColor Cyan
$run = docker run @runArgs 2>&1
if ($LASTEXITCODE -ne 0) {
    Write-Host 'docker run failed:' -ForegroundColor Red
    $run | Write-Host
    exit $LASTEXITCODE
}
Write-Host "Container '$container' started: $run" -ForegroundColor Green
Write-Host "Health: http://localhost:$Port/health   Logs: docker logs -f $container" -ForegroundColor Green
