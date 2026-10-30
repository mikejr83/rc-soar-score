#!/usr/bin/env bash
# Smoke check of a deployed API server: /health answers 200 and the guarded
# API refuses a request without a token. First step of the hosted checks
# (#296, #428).
#
#   scripts/hosted-smoke.sh [base-url]     default https://api.rcsoarscore.com
set -euo pipefail

base="${1:-https://api.rcsoarscore.com}"
base="${base%/}"

health=$(curl -sS -o /dev/null -w '%{http_code}' --max-time 60 "$base/health")
[ "$health" = "200" ] || { echo "FAIL: GET /health returned $health"; exit 1; }
echo "ok: GET /health 200"

guarded=$(curl -sS -o /dev/null -w '%{http_code}' --max-time 30 "$base/api/v1/contests")
[ "$guarded" = "401" ] || { echo "FAIL: unauthenticated GET /api/v1/contests returned $guarded, expected 401"; exit 1; }
echo "ok: unauthenticated /api/v1 request refused with 401"
