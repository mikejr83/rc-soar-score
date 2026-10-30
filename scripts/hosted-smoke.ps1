# scripts/hosted-smoke.ps1
# Smoke check of a deployed API server: /health answers 200 and the guarded
# API refuses a request without a token. First step of the hosted checks
# (#296, #428). PowerShell equivalent of hosted-smoke.sh.
#
#   ./scripts/hosted-smoke.ps1                              # https://api.rcsoarscore.com
#   ./scripts/hosted-smoke.ps1 -BaseUrl https://rc-soar-score-api.fly.dev

param(
    [string]$BaseUrl = 'https://api.rcsoarscore.com'
)

$ErrorActionPreference = 'Stop'
$BaseUrl = $BaseUrl.TrimEnd('/')

# Returns the HTTP status code; error statuses (401 and so on) do not throw.
function Get-StatusCode([string]$Url, [int]$TimeoutSec) {
    try {
        return [int](Invoke-WebRequest -Uri $Url -UseBasicParsing -TimeoutSec $TimeoutSec).StatusCode
    } catch {
        $response = $_.Exception.Response
        if ($null -eq $response) { throw }
        return [int]$response.StatusCode
    }
}

$health = Get-StatusCode "$BaseUrl/health" 60
if ($health -ne 200) {
    Write-Host "FAIL: GET /health returned $health"
    exit 1
}
Write-Host 'ok: GET /health 200'

$guarded = Get-StatusCode "$BaseUrl/api/v1/contests" 30
if ($guarded -ne 401) {
    Write-Host "FAIL: unauthenticated GET /api/v1/contests returned $guarded, expected 401"
    exit 1
}
Write-Host 'ok: unauthenticated /api/v1 request refused with 401'
