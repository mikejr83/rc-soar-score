# scripts/e2e.ps1
# Runs the contest app's end-to-end tests (Flutter integration_test) against
# the real app on the demo database, which is recreated for every run.
# Not part of CI (Actions has no credits); run it locally while testing.
#
#   .\scripts\e2e.ps1                      # Windows desktop
#   .\scripts\e2e.ps1 -Name journey        # only tests whose name matches
#   .\scripts\e2e.ps1 -Device chrome       # another `flutter test -d` device

param(
    [string]$Device = 'windows',
    [string]$Name = ''
)

$ErrorActionPreference = 'Stop'
Push-Location (Join-Path $PSScriptRoot '..\apps\soar_score_contest')
try {
    $flutterArgs = @(
        'test', 'integration_test', '-d', $Device,
        '--dart-define=SOAR_SCORE_DEMO=true',
        '--dart-define=SOAR_SCORE_DEMO_RESET=true'
    )
    if ($Name) { $flutterArgs += @('--name', $Name) }
    & flutter @flutterArgs
    exit $LASTEXITCODE
}
finally {
    Pop-Location
}
