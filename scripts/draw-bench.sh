#!/usr/bin/env bash
# scripts/draw-bench.sh
# Runs the matrix draw benchmark (packages/soar_score_core/tool/draw_bench.dart)
# on the research layouts and prints MAD, never-met pairs, max repeat and
# variance. Pass --check to fail on a regression against the stored baselines.
# Not part of the default test run or scripts/verify.ps1.
#
#   ./scripts/draw-bench.sh --check
#   ./scripts/draw-bench.sh --layout c4 --seeds 10
set -eu
cd "$(dirname "$0")/../packages/soar_score_core"
exec dart run tool/draw_bench.dart "$@"
