param(
    [string]$ConfigDir = (Join-Path $HOME ".config\opencode"),
    [switch]$Force
)

$ErrorActionPreference = "Stop"

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$repoRoot = Split-Path -Parent $scriptDir
$kitHome = Join-Path $ConfigDir "opencode-memory-kit"

function Copy-ManagedFile {
    param(
        [string]$Source,
        [string]$Destination,
        [switch]$ForceCopy
    )

    $destinationDir = Split-Path -Parent $Destination
    if ($destinationDir -and -not (Test-Path $destinationDir)) {
        New-Item -ItemType Directory -Force -Path $destinationDir | Out-Null
    }

    $exists = Test-Path $Destination
    if ($exists -and -not $ForceCopy) {
        Write-Host "Skipped $Destination"
        return
    }

    Copy-Item $Source $Destination -Force
    if ($exists) {
        Write-Host "Updated $Destination"
    }
    else {
        Write-Host "Created $Destination"
    }
}

Get-ChildItem -File (Join-Path $repoRoot "agents") | ForEach-Object {
    $destination = Join-Path $ConfigDir (Join-Path "agents" $_.Name)
    Copy-ManagedFile -Source $_.FullName -Destination $destination -ForceCopy:$Force
}

Get-ChildItem -File (Join-Path $repoRoot "commands") | ForEach-Object {
    $destination = Join-Path $ConfigDir (Join-Path "commands" $_.Name)
    Copy-ManagedFile -Source $_.FullName -Destination $destination -ForceCopy:$Force
}

Get-ChildItem -File -Recurse (Join-Path $repoRoot "templates") | ForEach-Object {
    $relativePath = $_.FullName.Substring($repoRoot.Length + 1)
    $destination = Join-Path $kitHome (Join-Path "templates" $relativePath.Substring("templates\".Length))
    Copy-ManagedFile -Source $_.FullName -Destination $destination -ForceCopy:$Force
}

Get-ChildItem -File -Recurse (Join-Path $repoRoot "scripts") | Where-Object {
    $_.FullName -notmatch "[\\/]__pycache__[\\/]" -and $_.Extension -ne ".pyc"
} | ForEach-Object {
    $relativePath = $_.FullName.Substring($repoRoot.Length + 1)
    $destination = Join-Path $kitHome $relativePath
    Copy-ManagedFile -Source $_.FullName -Destination $destination -ForceCopy:$Force
}

Write-Host ""
Write-Host "OpenCode memory kit installed under $ConfigDir"
Write-Host "Commands now available: /remember-feature, /recall-feature, and /review-memory"
Write-Host "Bootstrap or refresh a repo with:"
$bootstrapPath = Join-Path $kitHome "scripts\bootstrap-project.ps1"
Write-Host ('  powershell -ExecutionPolicy Bypass -File "{0}" -Target .' -f $bootstrapPath)
Write-Host "Rerun the same bootstrap command later to refresh managed instructions without overwriting saved memory notes."
