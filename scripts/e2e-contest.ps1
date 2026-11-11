# scripts/e2e-contest.ps1
# Runs the contest app's end-to-end tests (Flutter integration_test) against
# the real app on the demo database, which is recreated for every run.
# Not part of CI (Actions has no credits); run it locally while testing.
#
#   .\scripts\e2e-contest.ps1                      # Windows desktop
#   .\scripts\e2e-contest.ps1 -Name journey        # only tests whose name matches
#   .\scripts\e2e-contest.ps1 -File save_failure_retry_test.dart -Name 'Retry saves'
#                                               # one journey in one test file
#   .\scripts\e2e-contest.ps1 -Device web          # headless Chrome against the E2E server
#   .\scripts\e2e-contest.ps1 -Device <device>     # another `flutter test -d` device
#
# The web mode needs Chrome and a matching chromedriver. Run
# .\scripts\e2e-setup.ps1 once to install both into .e2e-tools\ (git-ignored),
# where this script finds them; or put `chromedriver` on PATH, or set
# $env:CHROMEDRIVER (and $env:CHROME_EXECUTABLE). It builds the app with SOAR_SCORE_E2E=true (an
# always-signed-in session) and points it at
# apps/soar_score_server/tool/e2e_server.dart, a token-free API server on demo
# data. Each test file gets a fresh server, hence fresh demo data.
# A test file that runs longer than $env:E2E_TEST_TIMEOUT seconds (default 300)
# is stopped and counted as failed, so a hung browser cannot stall a run. The
# long contest_lifecycle_journey_test.dart gets 1800 seconds by default;
# setting $env:E2E_TEST_TIMEOUT overrides the limit for every file. These
# limits apply to web runs only; a Windows (native) run has no timeout.

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
    # Chrome and chromedriver from scripts/e2e-setup, unless the environment
    # already names them.
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
    # Fail fast when chromedriver cannot serve, instead of letting flutter
    # drive wait for it.
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
        Push-Location (Join-Path $root 'apps\soar_score_contest')
        $testFiles = @(Get-ChildItem integration_test -Filter '*_test.dart')
        if ($TestFileName) {
            $testFiles = @($testFiles | Where-Object { $_.Name -eq $TestFileName })
            if ($testFiles.Count -eq 0) {
                throw "No E2E test file named '$TestFileName' found in integration_test."
            }
        }
        $publishingFiles = @(Get-Content (Join-Path $root 'scripts/e2e-contest-publishing.txt'))
        foreach ($file in $testFiles) {
            $log = New-TemporaryFile
            $serverArgs = @('run', 'tool/e2e_server.dart', '--port', $port)
            if ($file.Name -cin $publishingFiles) { $serverArgs += '--publishing' }
            $server = Start-Process dart `
                -ArgumentList $serverArgs `
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
                    '--dart-define=SOAR_SCORE_E2E=true',
                    "--dart-define=SOAR_SCORE_API_BASE_URL=http://localhost:$port"
                )
                if ($chrome) { $flutterArgs += "--chrome-binary=$chrome" }
                if ($file.Name -eq 'signed_out_landing_journey_test.dart') {
                    $flutterArgs += '--dart-define=SOAR_SCORE_E2E_SIGNED_OUT=true'
                }
                if ($Name) { $flutterArgs += @('--name', $Name) }
                if ($env:E2E_STOP_AFTER) { $flutterArgs += "--dart-define=E2E_STOP_AFTER=$($env:E2E_STOP_AFTER)" }
                $testTimeout = 300
                if ($file.Name -eq 'contest_lifecycle_journey_test.dart') { $testTimeout = 1800 }
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
    # The journeys that send invitations (see below).
    $hostedServerFiles = @('contest_lifecycle_journey_test.dart')
    foreach ($testFile in $testFiles) {
        Write-Host "Running $($testFile.Name)"
        $flutterArgs = @(
            'test', "integration_test/$($testFile.Name)", '-d', $Device,
            '--dart-define=SOAR_SCORE_DEMO=true',
            '--dart-define=SOAR_SCORE_DEMO_RESET=true'
        )
        if ($Name) { $flutterArgs += @('--name', $Name) }
        if ($env:E2E_STOP_AFTER) { $flutterArgs += "--dart-define=E2E_STOP_AFTER=$($env:E2E_STOP_AFTER)" }
        if ($testFile.Name -eq 'signed_out_landing_journey_test.dart') {
            $flutterArgs += '--dart-define=SOAR_SCORE_E2E_SIGNED_OUT=true'
        }
        if ($testFile.Name -eq 'matrix_draw_cancel_test.dart') {
            $flutterArgs += '--dart-define=SOAR_SCORE_E2E_SLOW_DRAW=true'
        }
        # The app reads as offline when the hosted server it reports to does
        # not answer its health check, and the Reports page then will not
        # offer to send invitations. The Windows run has no hosted server, so
        # the journey that sends them gets the web run's server, started
        # without --publishing: it answers, and still says it does not publish.
        $hosted = $null
        if ($testFile.Name -cin $hostedServerFiles) {
            $hostedPort = if ($env:E2E_SERVER_PORT) { $env:E2E_SERVER_PORT } else { 18080 }
            $hostedLog = New-TemporaryFile
            $hosted = Start-Process dart `
                -ArgumentList @('run', 'tool/e2e_server.dart', '--port', $hostedPort) `
                -WorkingDirectory (Join-Path $root 'apps\soar_score_server') `
                -RedirectStandardOutput $hostedLog -PassThru -WindowStyle Hidden
            $deadline = (Get-Date).AddSeconds(120)
            while (-not (Select-String -Path $hostedLog -Pattern 'E2E_SERVER_READY' -Quiet)) {
                if ($hosted.HasExited -or (Get-Date) -gt $deadline) {
                    throw 'E2E server did not start'
                }
                Start-Sleep -Milliseconds 500
            }
            $flutterArgs += "--dart-define=SOAR_SCORE_API_BASE_URL=http://localhost:$hostedPort"
        }
        try {
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
        }
        finally {
            # dart run starts a child process; kill the whole tree.
            if ($hosted) { taskkill /F /T /PID $hosted.Id | Out-Null }
        }
        if ($code -ne 0) { $status = 1 }
    }
    exit $status
}
finally {
    Pop-Location
}
