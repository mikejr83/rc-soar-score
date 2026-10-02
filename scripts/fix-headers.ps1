# scripts/fix-headers.ps1
# Fix the entity doc header blocks in plan/data-model/entities/*.md so each
# meta line (**Relationship**, **Purpose**, **Identifier**, **Parent entity**,
# **Child entities**) renders on its own line: two trailing spaces on every
# interior header line, none on the last (Prettier strips the last; the
# following blank line ends the paragraph). Idempotent.
# Exit code 0 = all headers already correct, 1 = files were changed.

$ErrorActionPreference = 'Stop'
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$root = Split-Path -Parent $scriptDir
$entityDir = Join-Path $root 'plan\data-model\entities'

if (-not (Test-Path -LiteralPath $entityDir)) {
    Write-Error "Entity directory not found: $entityDir"
    exit 1
}

function Get-Is-Header([string]$line) {
    # Bold meta line with a colon; skips banner notes like ** NOTE - ... ** or **SEEMS TO HAVE ISSUES**
    return ($line -match '^\*\*' -and $line -match ':' -and $line -notmatch '^\*\* (NOTE|SEEMS)')
}

$changed = 0
foreach ($file in Get-ChildItem -LiteralPath $entityDir -Filter '*.md' | Sort-Object Name) {
    $lines = [System.IO.File]::ReadAllLines($file.FullName)
    $fileChanged = $false

    # Find the header block: first run of header lines after the title.
    $start = -1
    for ($i = 0; $i -lt $lines.Count; $i++) {
        if ($start -eq -1) {
            if ($lines[$i] -match '^# ' -and $i -eq 0) { continue }
            if ((Get-Is-Header $lines[$i])) { $start = $i }
            elseif ($lines[$i] -match '^\S' -and $lines[$i] -notmatch '^# ') {
                break # some other content before the header; no header block
            }
        } elseif (-not (Get-Is-Header $lines[$i])) {
            break # end of the header block
        }
    }
    if ($start -eq -1) { continue }

    $end = $start
    while ($end -lt $lines.Count -and (Get-Is-Header $lines[$end])) {
        $end++
    }
    $end-- # last header line index

    for ($i = $start; $i -le $end; $i++) {
        $trimmed = $lines[$i].TrimEnd()
        if ($i -lt $end) {
            $expected = $trimmed + "  "
        } else {
            $expected = $trimmed
        }
        if ($lines[$i] -ne $expected) {
            $lines[$i] = $expected
            $fileChanged = $true
        }
    }

    if ($fileChanged) {
        # Write LF line endings (repo .prettierrc uses endOfLine: "lf"), no BOM.
        $content = ($lines -join "`n") + "`n"
        [System.IO.File]::WriteAllText($file.FullName, $content, (New-Object System.Text.UTF8Encoding($false)))
        Write-Host "fixed $($file.Name)" -ForegroundColor Yellow
        $changed++
    }
}

if ($changed -eq 0) {
    Write-Host "All entity headers OK" -ForegroundColor Green
    exit 0
} else {
    Write-Host ("Fixed " + $changed + " files") -ForegroundColor Cyan
    exit 1
}
