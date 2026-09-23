# scripts/verify.ps1
# Single entry point for agents and CI: format check, analyze, test, build.
# Exit code 0 = pass, non-zero = fail. Run from repo root.

$ErrorActionPreference = 'Stop'
$failures = @()

function Run-Step {
    param(
        [string]$Name,
        [scriptblock]$Command
    )
    Write-Host "==> $Name" -ForegroundColor Cyan
    & $Command
    if ($LASTEXITCODE -ne 0) {
        Write-Host "FAILED: $Name" -ForegroundColor Red
        $script:failures += $Name
    } else {
        Write-Host "OK: $Name" -ForegroundColor Green
    }
}

# 1. Bootstrap (fast no-op if already up to date; catches missing deps early)
Run-Step "melos bootstrap" { melos bootstrap }

# 2. Format check (fails, doesn't rewrite, so an agent sees the problem)
Run-Step "format check" { melos format -o none --set-exit-if-changed -c 3 }

# 3. Static analysis across every package
Run-Step "analyze" { melos analyze --fatal-infos }

# 4. Tests across every package (unit + widget tests via flutter test / dart test)
Run-Step "test" { melos test -c 3}

# 5. Build check for buildable targets (adjust package names to yours)
Run-Step "build" { melos run build }

# 6. Server package: dart compile / analyze is covered above; add a smoke test if you have one
# Run-Step "server smoke test" { melos exec --scope="soar_score_server" -- "dart run tool/smoke_test.dart" }

Write-Host ""
if ($failures.Count -gt 0) {
    Write-Host "verify FAILED: $($failures -join ', ')" -ForegroundColor Red
    exit 1
} else {
    Write-Host "verify PASSED" -ForegroundColor Green
    exit 0
}