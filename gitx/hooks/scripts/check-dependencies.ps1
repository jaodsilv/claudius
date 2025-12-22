# Check for git and gh CLI dependencies
# Returns JSON with systemMessage for warnings

$missingDeps = @()
$warnings = @()

# Check git
if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
    $missingDeps += "git"
}

# Check gh CLI
if (-not (Get-Command gh -ErrorAction SilentlyContinue)) {
    $missingDeps += "gh CLI"
} else {
    # Check gh authentication status
    $authStatus = gh auth status 2>&1
    if ($LASTEXITCODE -ne 0) {
        $warnings += "gh CLI is installed but not authenticated. Run 'gh auth login' to enable GitHub features."
    }
}

# Output result
if ($missingDeps.Count -gt 0) {
    $deps = $missingDeps -join ", "
    Write-Output "{`"systemMessage`": `"[gitx plugin] Missing dependencies: $deps. Some commands may not work. Install git from https://git-scm.com/ and gh from https://cli.github.com/`"}"
} elseif ($warnings.Count -gt 0) {
    $warn = $warnings -join " "
    Write-Output "{`"systemMessage`": `"[gitx plugin] Warning: $warn`"}"
}

# Always exit 0 to not block session
exit 0
