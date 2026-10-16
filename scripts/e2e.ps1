# scripts/e2e.ps1
# Runs the contest app's end-to-end tests (Flutter integration_test) against
# the real app on the demo database, which is recreated for every run.
# Not part of CI (Actions has no credits); run it locally while testing.
#
#   .\scripts\e2e.ps1                      # Windows desktop
#   .\scripts\e2e.ps1 -Name journey        # only tests whose name matches
#   .\scripts\e2e.ps1 -File score_entry_test.dart -Name 'official score entry'
#                                               # one journey in one test file
#   .\scripts\e2e.ps1 -Device chrome       # another `flutter test -d` device

param(
    [string]$Device = 'windows',
    [string]$Name = '',
    [Alias('File')]
    [string]$TestFileName = ''
)

$ErrorActionPreference = 'Stop'
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
