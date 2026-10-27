# scripts/draw-bench.ps1
# Runs the matrix draw benchmark (packages/soar_score_core/tool/draw_bench.dart)
# on the research layouts and prints MAD, never-met pairs, max repeat and
# variance. Pass --check to fail on a regression against the stored baselines.
# Not part of the default test run or scripts/verify.ps1.
#
#   .\scripts\draw-bench.ps1 --check
#   .\scripts\draw-bench.ps1 --layout c4 --seeds 10
Push-Location (Join-Path $PSScriptRoot '..\packages\soar_score_core')
try {
    dart run tool/draw_bench.dart @args
    exit $LASTEXITCODE
}
finally {
    Pop-Location
}
