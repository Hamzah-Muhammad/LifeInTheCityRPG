# Rebuilds the Windows Desktop export of Life in the City from the current
# source and refreshes the Desktop shortcut so it always points at the
# latest build. Run this after any code/scene change you want reflected in
# the double-clickable .exe (an export is a snapshot, not a live view).

$ErrorActionPreference = "Stop"

$godot = "$env:LOCALAPPDATA\Microsoft\WinGet\Links\godot_console.exe"
$projectPath = Split-Path -Parent $PSScriptRoot
$exportOut = Join-Path $projectPath "export\windows\LifeInTheCity.exe"
$shortcutPath = Join-Path ([Environment]::GetFolderPath("Desktop")) "Life in the City.lnk"

New-Item -ItemType Directory -Force -Path (Split-Path $exportOut) | Out-Null

& $godot --headless --path $projectPath --export-release "Windows Desktop" $exportOut
if ($LASTEXITCODE -ne 0) {
    throw "Godot export failed with exit code $LASTEXITCODE"
}

$shell = New-Object -ComObject WScript.Shell
$shortcut = $shell.CreateShortcut($shortcutPath)
$shortcut.TargetPath = $exportOut
$shortcut.WorkingDirectory = Split-Path $exportOut
$shortcut.Description = "Life in the City (latest export)"
$shortcut.Save()

Write-Host "Exported to $exportOut"
Write-Host "Desktop shortcut refreshed: $shortcutPath"
