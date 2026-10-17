# scripts/e2e-setup.ps1
# Installs Chrome and a matching chromedriver (both from Chrome for Testing)
# into .e2e-tools\ at the repo root, which git ignores. scripts\e2e.ps1
# -Device web and scripts/e2e.sh -d web find them there, so no PATH or
# environment setup is needed.
#
#   .\scripts\e2e-setup.ps1                  # latest Stable, unless already installed
#   .\scripts\e2e-setup.ps1 -Channel Beta    # Stable (default), Beta, Dev or Canary
#   .\scripts\e2e-setup.ps1 -Version 155.0.8059.84
#   .\scripts\e2e-setup.ps1 -DryRun          # print what it would download
#
# Downloads about 220 MB once, from storage.googleapis.com.

param(
    [string]$Channel = 'Stable',
    [string]$Version = '',
    [switch]$DryRun
)

$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'

if ($IsLinux) {
    $platform = 'linux64'; $chromeBin = 'chrome'; $driverBin = 'chromedriver'
} elseif ($IsMacOS) {
    $platform = if ((uname -m) -eq 'arm64') { 'mac-arm64' } else { 'mac-x64' }
    $chromeBin = 'Google Chrome for Testing.app/Contents/MacOS/Google Chrome for Testing'
    $driverBin = 'chromedriver'
} else {
    $platform = 'win64'; $chromeBin = 'chrome.exe'; $driverBin = 'chromedriver.exe'
}

$root = Resolve-Path (Join-Path $PSScriptRoot '..')
$tools = Join-Path $root '.e2e-tools'
$base = 'https://storage.googleapis.com/chrome-for-testing-public'

if (-not $Version) {
    $Version = (Invoke-RestMethod "https://googlechromelabs.github.io/chrome-for-testing/LATEST_RELEASE_$($Channel.ToUpper())").ToString().Trim()
}
$chromeUrl = "$base/$Version/$platform/chrome-$platform.zip"
$driverUrl = "$base/$Version/$platform/chromedriver-$platform.zip"
$dir = Join-Path $tools $Version

if ($DryRun) {
    Write-Host "version:      $Version"
    Write-Host "install into: $dir"
    Write-Host "chrome:       $chromeUrl"
    Write-Host "chromedriver: $driverUrl"
    return
}

$chromePath = Join-Path $dir "chrome-$platform/$chromeBin"
$driverPath = Join-Path $dir "chromedriver-$platform/$driverBin"
if (-not ((Test-Path $chromePath) -and (Test-Path $driverPath))) {
    New-Item -ItemType Directory -Force $dir | Out-Null
    foreach ($url in $chromeUrl, $driverUrl) {
        Write-Host "Downloading $url"
        $zip = Join-Path $dir 'download.zip'
        Invoke-WebRequest $url -OutFile $zip
        Expand-Archive $zip -DestinationPath $dir -Force
        Remove-Item $zip
    }
    if (-not $IsWindows -and $PSVersionTable.PSEdition -eq 'Core' -and ($IsLinux -or $IsMacOS)) {
        chmod +x $chromePath $driverPath
    }
}

# The e2e scripts read these two lines (paths are relative to .e2e-tools).
Set-Content (Join-Path $tools 'paths.env') -Encoding ascii -Value @(
    "chrome=$Version/chrome-$platform/$chromeBin",
    "chromedriver=$Version/chromedriver-$platform/$driverBin"
)
& $driverPath --version
Write-Host "Installed Chrome and chromedriver $Version in $dir"
