# scripts/e2e.ps1
# Runs the contest app's end-to-end tests (Flutter integration_test) against
# the real app on the demo database, which is recreated for every run.
# Not part of CI (Actions has no credits); run it locally while testing.
#
#   .\scripts\e2e.ps1                      # Windows desktop
#   .\scripts\e2e.ps1 -Name journey        # only tests whose name matches
#   .\scripts\e2e.ps1 -File score_entry_test.dart -Name 'official score entry'
#                                               # one journey in one test file
#   .\scripts\e2e.ps1 -Device web          # headless Chrome against the E2E server
#   .\scripts\e2e.ps1 -Device <device>     # another `flutter test -d` device
#
# The web mode needs Chrome and a matching chromedriver (`chromedriver` on
# PATH, or $env:CHROMEDRIVER). It builds the app with SOAR_SCORE_E2E=true (an
# always-signed-in session) and points it at
# apps/soar_score_server/tool/e2e_server.dart, a token-free API server on demo
# data. Each test file gets a fresh server, hence fresh demo data.

param(
    [string]$Device = 'windows',
    [string]$Name = '',
    [Alias('File')]
    [string]$TestFileName = ''
)

$ErrorActionPreference = 'Stop'
$root = Resolve-Path (Join-Path $PSScriptRoot '..')

if ($Device -in 'web', 'chrome') {
    $port = if ($env:E2E_SERVER_PORT) { $env:E2E_SERVER_PORT } else { 18080 }
    $chromedriver = if ($env:CHROMEDRIVER) { $env:CHROMEDRIVER } else { 'chromedriver' }
    $driver = Start-Process $chromedriver '--port=4444' -PassThru -WindowStyle Hidden
    $status = 0
    try {
        Push-Location (Join-Path $root 'apps\soar_score_contest')
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
                -ArgumentList 'run', 'tool/e2e_server.dart', '--port', $port `
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
                    '--dart-define=SOAR_SCORE_E2E=true',
                    "--dart-define=SOAR_SCORE_API_BASE_URL=http://localhost:$port"
                )
                if ($Name) { $flutterArgs += @('--name', $Name) }
                & flutter @flutterArgs
                if ($LASTEXITCODE -ne 0) { $status = 1 }
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
}

Push-Location (Join-Path $PSScriptRoot '..\apps\soar_score_contest')
try {
    # One flutter test run per file. The Windows app allows a single instance
    # (its mutex), and flutter test can leave the previous app alive for a
    # moment or for good, so each run starts from a clean slate and a launch
    # that failed for that reason is retried once.
    function Stop-App {
        Get-Process soar_score_contest -ErrorAction SilentlyContinue |
            Stop-Process -Force -ErrorAction SilentlyContinue
        $deadline = (Get-Date).AddSeconds(15)
        while ((Get-Process soar_score_contest -ErrorAction SilentlyContinue) -and
               (Get-Date) -lt $deadline) {
            Start-Sleep -Milliseconds 250
        }
    }

    $status = 0
    $testFiles = @(Get-ChildItem integration_test -Filter '*_test.dart')
    if ($TestFileName) {
        $testFiles = @($testFiles | Where-Object { $_.Name -eq $TestFileName })
        if ($testFiles.Count -eq 0) {
            throw "No E2E test file named '$TestFileName' found in integration_test."
        }
    }
    foreach ($testFile in $testFiles) {
        Write-Host "Running $($testFile.Name)"
        $flutterArgs = @(
            'test', "integration_test/$($testFile.Name)", '-d', $Device,
            '--dart-define=SOAR_SCORE_DEMO=true',
            '--dart-define=SOAR_SCORE_DEMO_RESET=true'
        )
        if ($Name) { $flutterArgs += @('--name', $Name) }
        for ($attempt = 1; $attempt -le 2; $attempt++) {
            Stop-App
            $output = & flutter @flutterArgs 2>&1 | Tee-Object -Variable lines |
                ForEach-Object { Write-Host $_ }
            $code = $LASTEXITCODE
            Stop-App
            $launchFailed = ($lines -join "`n") -match 'Unable to start the app'
            if ($code -eq 0 -or -not $launchFailed) { break }
            Write-Host "Launch failed for $($testFile.Name); retrying once."
        }
        if ($code -ne 0) { $status = 1 }
    }
    exit $status
}
finally {
    Pop-Location
}
