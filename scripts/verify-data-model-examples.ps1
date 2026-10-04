# scripts/verify-data-model-examples.ps1
# Check that every entity under plan/data-model/entities/ has a JSON example
# under plan/data-model/examples/entities/ and that the example's top-level
# keys match the entity's Fields/Properties table (same names, none missing,
# none extra). Does not check types or enum values.
# Exit code 0 = inventory consistent, 1 = mismatches found.

$ErrorActionPreference = 'Stop'
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$root = Split-Path -Parent $scriptDir
$entityDir = Join-Path $root 'plan\data-model\entities'
$exampleDir = Join-Path $root 'plan\data-model\examples\entities'

# Entity name -> set of documented field names (first column of the
# Fields/Properties table).
$entities = @{}
foreach ($file in Get-ChildItem -LiteralPath $entityDir -Filter '*.md') {
    $lines = [System.IO.File]::ReadAllLines($file.FullName)
    $title = ($lines | Where-Object { $_ -match '^# ' } | Select-Object -First 1) -replace '^# ', ''
    $fields = [System.Collections.Generic.List[string]]::new()
    $inFields = $false
    $inTable = $false
    foreach ($line in $lines) {
        if ($line -match '^## Fields') { $inFields = $true; continue }
        if ($inFields -and $line -match '^## ') { break }
        if (-not $inFields) { continue }
        if ($line -match '^\|\s*`([^`]+)`\s*\|') { $fields.Add($Matches[1]); $inTable = $true }
    }
    $entities[($title -replace '\s', '')] = [pscustomobject]@{ File = $file.Name; Fields = $fields }
}

# Entity name -> example JSON text(s): a "## Name" heading followed by a
# ```json block.
$examples = @{}
foreach ($file in Get-ChildItem -LiteralPath $exampleDir -Filter '*.md') {
    $text = [System.IO.File]::ReadAllText($file.FullName)
    # Each "## Name" section may hold prose and several ```json blocks
    # (variants of the same entity); every block is checked.
    foreach ($section in [regex]::Split($text, '(?m)^## ')) {
        $nl = $section.IndexOf("`n")
        if ($nl -lt 0) { continue }
        $name = $section.Substring(0, $nl).Trim()
        foreach ($m in [regex]::Matches($section, '(?s)```json\r?\n(?<json>.*?)\r?\n```')) {
            if (-not $examples.ContainsKey($name)) { $examples[$name] = @() }
            $examples[$name] += [pscustomobject]@{ File = $file.Name; Json = $m.Groups['json'].Value }
        }
    }
}

$problems = 0
foreach ($name in ($entities.Keys | Sort-Object)) {
    $entity = $entities[$name]
    if (-not $examples.ContainsKey($name)) {
        Write-Host "MISSING EXAMPLE  $name ($($entity.File))"
        $problems++
        continue
    }
    foreach ($example in $examples[$name]) {
        try {
            # -NoEnumerate keeps a JSON array as one value; the wrapping
            # comma then makes a single object a one-element list too.
            $parsed = $example.Json | ConvertFrom-Json -NoEnumerate
        } catch {
            Write-Host "INVALID JSON     $name in $($example.File): $($_.Exception.Message)"
            $problems++
            continue
        }
        # An example is one row or an array of rows; every row is checked.
        $rows = if ($parsed -is [System.Array]) { @($parsed) } else { @(, $parsed) }
        $index = 0
        foreach ($obj in $rows) {
            $index++
            $keys = @($obj.PSObject.Properties.Name)
            $missing = @($entity.Fields | Where-Object { $_ -notin $keys })
            $extra = @($keys | Where-Object { $_ -notin $entity.Fields })
            if ($missing.Count -or $extra.Count) {
                Write-Host "FIELD MISMATCH   $name row $index ($($example.File))"
                if ($missing.Count) { Write-Host "    in entity doc, not in example: $($missing -join ', ')" }
                if ($extra.Count) { Write-Host "    in example, not in entity doc: $($extra -join ', ')" }
                $problems++
            }
        }
    }
}
foreach ($name in ($examples.Keys | Sort-Object)) {
    if (-not $entities.ContainsKey($name)) {
        Write-Host "NO ENTITY DOC    example heading '$name' matches no entity title"
        $problems++
    }
}

Write-Host "$($entities.Count) entities, $($examples.Count) example headings, $problems problem(s)."
if ($problems -gt 0) { exit 1 }
exit 0
