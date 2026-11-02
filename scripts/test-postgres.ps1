# scripts/test-postgres.ps1
# Starts a throwaway PostgreSQL container, runs the data package tests against
# it (the SQLite and PostgreSQL groups), and removes the container, even when
# the tests fail. Needs Docker. Run from anywhere; exit code is the tests'.
#
#   ./scripts/test-postgres.ps1
#   ./scripts/test-postgres.ps1 -Port 55432
#   ./scripts/test-postgres.ps1 -- -n "unit of work"     # extra args go to dart test

param(
    [string]$Image = 'postgres:18',
    # Host port. Not 5432, so a PostgreSQL already on this machine is left alone.
    [int]$Port = 54329,
    [Parameter(ValueFromRemainingArguments = $true)]
    [string[]]$TestArgs = @()
)

$ErrorActionPreference = 'Stop'

$repoRoot = Split-Path -Parent $PSScriptRoot
$dataPackage = Join-Path $repoRoot 'packages/soar_score_data'
$container = "soar-pg-test-$PID"
$password = 'dev'

if (-not (Get-Command docker -ErrorAction SilentlyContinue)) {
    Write-Host 'docker was not found on PATH.' -ForegroundColor Red
    exit 1
}
docker info *> $null
if ($LASTEXITCODE -ne 0) {
    Write-Host 'The Docker daemon is not running.' -ForegroundColor Red
    exit 1
}

# Drop a leading "--" separator so `-- -n name` reaches dart test as `-n name`.
if ($TestArgs.Count -gt 0 -and $TestArgs[0] -eq '--') {
    $TestArgs = $TestArgs[1..($TestArgs.Count - 1)]
}

$savedEnv = @{}
foreach ($name in 'POSTGRES_PASSWORD', 'POSTGRES_HOST', 'POSTGRES_PORT') {
    $savedEnv[$name] = [Environment]::GetEnvironmentVariable($name)
}
$exitCode = 1
$started = $false

try {
    Write-Host "==> Starting $Image as $container on 127.0.0.1:$Port" -ForegroundColor Cyan
    # Bound to localhost only; --rm removes the container when it stops.
    docker run -d --rm --name $container `
        -e "POSTGRES_PASSWORD=$password" `
        -p "127.0.0.1:${Port}:5432" `
        $Image | Out-Null
    if ($LASTEXITCODE -ne 0) { throw "docker run failed (is port $Port in use? try -Port)." }
    $started = $true

    Write-Host '==> Waiting for PostgreSQL to accept connections' -ForegroundColor Cyan
    # The image initialises over a unix socket first and only then listens on
    # TCP, so check TCP (-h 127.0.0.1) to know it is really ready.
    $ready = $false
    for ($i = 0; $i -lt 60; $i++) {
        docker exec $container pg_isready -h 127.0.0.1 -U postgres *> $null
        if ($LASTEXITCODE -eq 0) { $ready = $true; break }
        Start-Sleep -Seconds 1
    }
    if (-not $ready) { throw 'PostgreSQL did not become ready within 60 seconds.' }

    $env:POSTGRES_PASSWORD = $password
    $env:POSTGRES_HOST = 'localhost'
    $env:POSTGRES_PORT = "$Port"

    Write-Host '==> dart test (packages/soar_score_data)' -ForegroundColor Cyan
    Push-Location $dataPackage
    try {
        dart test @TestArgs
        $exitCode = $LASTEXITCODE
    } finally {
        Pop-Location
    }
} catch {
    Write-Host $_.Exception.Message -ForegroundColor Red
    $exitCode = 1
} finally {
    foreach ($name in $savedEnv.Keys) {
        [Environment]::SetEnvironmentVariable($name, $savedEnv[$name])
    }
    if ($started) {
        Write-Host "==> Removing $container" -ForegroundColor Cyan
        docker rm -f $container *> $null
    }
}

Write-Host ""
if ($exitCode -eq 0) {
    Write-Host 'postgres tests PASSED' -ForegroundColor Green
} else {
    Write-Host 'postgres tests FAILED' -ForegroundColor Red
}
exit $exitCode
