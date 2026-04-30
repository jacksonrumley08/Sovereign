$ErrorActionPreference = 'Stop'

$projectDir = $env:CLAUDE_PROJECT_DIR
if (-not $projectDir -or -not (Test-Path $projectDir)) { exit 0 }

$item = Get-Item $projectDir -ErrorAction SilentlyContinue
$isReparse = $item.Attributes.HasFlag([IO.FileAttributes]::ReparsePoint)
$looksLikeOneDrive = $projectDir -like '*OneDrive*'

if ($isReparse -or $looksLikeOneDrive) {
    [Console]::Error.WriteLine("[onedrive-guard] Project at '$projectDir' is OneDrive-synced.")
    [Console]::Error.WriteLine("[onedrive-guard] This causes file-lock issues with Godot's import pipeline (godotengine/godot#100387).")
    [Console]::Error.WriteLine("[onedrive-guard] Move the project off OneDrive before continuing.")
    exit 2
}

exit 0
