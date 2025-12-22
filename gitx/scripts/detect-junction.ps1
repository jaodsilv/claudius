# Detect if a path is a junction point or symlink and return its target
# Usage: detect-junction.ps1 <path>
# Output: JSON { "isLink": true/false, "target": "path" }

param(
    [Parameter(Mandatory=$true)]
    [string]$Path
)

if (-not (Test-Path $Path)) {
    Write-Output '{"error": "Path does not exist"}'
    exit 1
}

$item = Get-Item $Path -Force -ErrorAction SilentlyContinue

if ($null -eq $item) {
    Write-Output '{"error": "Cannot access path"}'
    exit 1
}

# Check if it's a reparse point (junction or symlink)
$isReparsePoint = ($item.Attributes -band [System.IO.FileAttributes]::ReparsePoint) -eq [System.IO.FileAttributes]::ReparsePoint

if ($isReparsePoint) {
    # Try to get the target using fsutil
    $fsutilOutput = & fsutil reparsepoint query $Path 2>&1
    $target = ""

    foreach ($line in $fsutilOutput) {
        if ($line -match "Print Name:\s*(.+)") {
            $target = $Matches[1].Trim()
            break
        }
        if ($line -match "Substitute Name:\s*(.+)") {
            $target = $Matches[1].Trim()
            # Continue looking for Print Name as it's preferred
        }
    }

    # Clean up the target path (remove \??\ prefix if present)
    $target = $target -replace '^\\\?\?\\', ''

    # Escape backslashes and quotes for JSON
    $target = $target -replace '\\', '\\' -replace '"', '\"'

    Write-Output "{`"isLink`": true, `"target`": `"$target`"}"
} else {
    Write-Output '{"isLink": false}'
}

exit 0
