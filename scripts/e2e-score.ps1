# scripts/e2e-score.ps1
# Runs the self-scoring app's end-to-end tests (Flutter integration_test) in
# headless Chrome against the real web build and a real API: the token-free
# apps/soar_score_server/tool/e2e_server.dart on a fresh database, with
# invitations on. The contest app has its own script, e2e-contest.ps1.
# Not part of CI (Actions has no credits); run it locally while testing.
#
#   .\scripts\e2e-score.ps1                       # every file in integration_test
#   .\scripts\e2e-score.ps1 -File self_score_lifecycle_journey_test.dart
#   $env:E2E_STOP_AFTER = 3; .\scripts\e2e-score.ps1   # end the journey after phase 3
#
# The self-scoring app is a web app, so there is no device option. Needs
# Chrome and a matching chromedriver: run .\scripts\e2e-setup.ps1 once (they
# go into .e2e-tools\, which git ignores), or put `chromedriver` on PATH, or
# set $env:CHROMEDRIVER (and $env:CHROME_EXECUTABLE).
# Each test file gets a fresh server, hence a fresh database. A file that runs
# longer than $env:E2E_TEST_TIMEOUT seconds (default 900) is stopped and
# counted as failed, so a hung browser cannot stall a run.

param(
    [Alias('File')]
    [string]$TestFileName = ''
)

$ErrorActionPreference = 'Stop'
$root = Resolve-Path (Join-Path $PSScriptRoot '..')
$port = if ($env:E2E_SERVER_PORT) { $env:E2E_SERVER_PORT } else { 18080 }
$chromedriver = $env:CHROMEDRIVER
$chrome = $env:CHROME_EXECUTABLE
$pathsFile = Join-Path $root '.e2e-tools/paths.env'
if (Test-Path $pathsFile) {
    $paths = @{}
    Get-Content $pathsFile | ForEach-Object {
        $k, $v = $_ -split '=', 2
        $paths[$k] = Join-Path $root ".e2e-tools/$v"
    }
    if (-not $chromedriver) { $chromedriver = $paths['chromedriver'] }
    if (-not $chrome) { $chrome = $paths['chrome'] }
}
if (-not $chromedriver) { $chromedriver = 'chromedriver' }
if (-not (Get-Command $chromedriver -ErrorAction SilentlyContinue)) {
    throw "chromedriver not found ('$chromedriver'). Run .\scripts\e2e-setup.ps1 to install Chrome and chromedriver, or set `$env:CHROMEDRIVER."
}
$driver = Start-Process $chromedriver '--port=4444' -PassThru -WindowStyle Hidden
# Fail fast when chromedriver cannot serve, instead of letting flutter drive
# wait for it.
$ready = $false
for ($i = 0; $i -lt 20 -and -not $ready -and -not $driver.HasExited; $i++) {
    try {
        Invoke-WebRequest 'http://localhost:4444/status' -UseBasicParsing -TimeoutSec 2 | Out-Null
        $ready = $true
    } catch { Start-Sleep -Milliseconds 500 }
}
if (-not $ready) {
    Stop-Process -Id $driver.Id -Force -ErrorAction SilentlyContinue
    throw 'chromedriver did not answer on port 4444 (is another one running?).'
}
$status = 0
try {
    Push-Location (Join-Path $root 'apps\soar_score_self_score')
    $testFiles = @(Get-ChildItem integration_test -Filter '*_test.dart')
    if ($TestFileName) {
        $testFiles = @($testFiles | Where-Object { $_.Name -eq $TestFileName })
        if ($testFiles.Count -eq 0) {
            throw "No E2E test file named '$TestFileName' found in integration_test."
        }
    }
    foreach ($file in $testFiles) {
        $log = New-TemporaryFile
        $server = Start-Process dart `
            -ArgumentList 'run', 'tool/e2e_server.dart', '--port', $port, '--profile', 'server' `
            -WorkingDirectory (Join-Path $root 'apps\soar_score_server') `
            -RedirectStandardOutput $log -PassThru -WindowStyle Hidden
        try {
            $deadline = (Get-Date).AddSeconds(120)
            while (-not (Select-String -Path $log -Pattern 'E2E_SERVER_READY' -Quiet)) {
                if ($server.HasExited -or (Get-Date) -gt $deadline) {
                    throw 'E2E server did not start'
                }
                Start-Sleep -Milliseconds 500
            }
            $flutterArgs = @(
                'drive', '--driver=test_driver/integration_test.dart',
                "--target=integration_test/$($file.Name)",
                '-d', 'web-server', '--browser-name=chrome',
                '--no-web-resources-cdn',
                "--dart-define=SOAR_SCORE_API_BASE_URL=http://localhost:$port"
            )
            if ($chrome) { $flutterArgs += "--chrome-binary=$chrome" }
            if ($env:E2E_STOP_AFTER) { $flutterArgs += "--dart-define=E2E_STOP_AFTER=$($env:E2E_STOP_AFTER)" }
            $testTimeout = 900
            if ($env:E2E_TEST_TIMEOUT) { $testTimeout = [int]$env:E2E_TEST_TIMEOUT }
            $flutter = Start-Process (Get-Command flutter).Source `
                -ArgumentList $flutterArgs -NoNewWindow -PassThru
            if (-not $flutter.WaitForExit($testTimeout * 1000)) {
                Write-Host "TIMEOUT: $($file.Name) ran longer than $testTimeout s and was stopped."
                taskkill /F /T /PID $flutter.Id | Out-Null
                $status = 1
            } elseif ($flutter.ExitCode -ne 0) { $status = 1 }
        }
        finally {
            # dart run starts a child process; kill the whole tree.
            taskkill /F /T /PID $server.Id | Out-Null
        }
    }
}
finally {
    Pop-Location
    Stop-Process -Id $driver.Id -Force -ErrorAction SilentlyContinue
}
exit $status
