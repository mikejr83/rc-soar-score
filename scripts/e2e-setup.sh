#!/usr/bin/env bash
# scripts/e2e-setup.sh
# Installs Chrome and a matching chromedriver (both from Chrome for Testing)
# into .e2e-tools/ at the repo root, which git ignores. scripts/e2e.sh -d web
# and scripts/e2e.ps1 -Device web find them there, so no PATH or environment
# setup is needed.
#
#   ./scripts/e2e-setup.sh                 # latest Stable, unless already installed
#   ./scripts/e2e-setup.sh --channel Beta  # Stable (default), Beta, Dev or Canary
#   ./scripts/e2e-setup.sh --version 155.0.8059.84
#   ./scripts/e2e-setup.sh --dry-run       # print what it would download
#
# Needs curl and unzip (or python3). Downloads about 220 MB once, from
# storage.googleapis.com. On Linux, Chrome also needs its system libraries
# (on Debian/Ubuntu: `sudo apt-get install -y libnss3 libatk-bridge2.0-0
# libgtk-3-0 libgbm1 libasound2`).
set -eu
channel=Stable
version=
dry_run=
while [ $# -gt 0 ]; do
  case "$1" in
    --channel) channel="$2"; shift 2 ;;
    --version) version="$2"; shift 2 ;;
    --dry-run) dry_run=1; shift ;;
    *) echo "usage: $(basename "$0") [--channel <name>] [--version <x.y.z.w>] [--dry-run]" >&2; exit 1 ;;
  esac
done

case "$(uname -s)-$(uname -m)" in
  Linux-x86_64) platform=linux64; chrome_bin=chrome; driver_bin=chromedriver ;;
  Darwin-arm64) platform=mac-arm64; chrome_bin="Google Chrome for Testing.app/Contents/MacOS/Google Chrome for Testing"; driver_bin=chromedriver ;;
  Darwin-x86_64) platform=mac-x64; chrome_bin="Google Chrome for Testing.app/Contents/MacOS/Google Chrome for Testing"; driver_bin=chromedriver ;;
  MINGW*-* | MSYS*-* | CYGWIN*-*) platform=win64; chrome_bin=chrome.exe; driver_bin=chromedriver.exe ;;
  *) echo "No Chrome for Testing build for $(uname -s) $(uname -m)." >&2; exit 1 ;;
esac

root="$(cd "$(dirname "$0")/.." && pwd)"
tools="$root/.e2e-tools"
base=https://storage.googleapis.com/chrome-for-testing-public

if [ -z "$version" ]; then
  version="$(curl -sSf "https://googlechromelabs.github.io/chrome-for-testing/LATEST_RELEASE_$(echo "$channel" | tr '[:lower:]' '[:upper:]')")"
fi
chrome_url="$base/$version/$platform/chrome-$platform.zip"
driver_url="$base/$version/$platform/chromedriver-$platform.zip"

if [ -n "$dry_run" ]; then
  echo "version:      $version"
  echo "install into: $tools/$version"
  echo "chrome:       $chrome_url"
  echo "chromedriver: $driver_url"
  exit 0
fi

dir="$tools/$version"
unzip_to() { # <zip> <dir>
  if command -v unzip >/dev/null 2>&1; then unzip -q -o "$1" -d "$2"
  else python3 -m zipfile -e "$1" "$2"; fi
}
if [ ! -f "$dir/chrome-$platform/$chrome_bin" ] || [ ! -f "$dir/chromedriver-$platform/$driver_bin" ]; then
  mkdir -p "$dir"
  for url in "$chrome_url" "$driver_url"; do
    echo "Downloading $url"
    curl -sSfL -o "$dir/download.zip" "$url"
    unzip_to "$dir/download.zip" "$dir"
    rm -f "$dir/download.zip"
  done
  chmod +x "$dir/chrome-$platform/$chrome_bin" "$dir/chromedriver-$platform/$driver_bin" 2>/dev/null || true
fi

# The e2e scripts read these two lines (paths are relative to .e2e-tools).
cat >"$tools/paths.env" <<PATHS
chrome=$version/chrome-$platform/$chrome_bin
chromedriver=$version/chromedriver-$platform/$driver_bin
PATHS
"$dir/chromedriver-$platform/$driver_bin" --version
echo "Installed Chrome and chromedriver $version in $dir"
