# PowerShell Script to Install Inno Setup

# Install via chocolatey (reliable in CI environments)
Write-Host "Downloading Inno Setup..."
try {
    choco install innosetup -y --no-progress
    Write-Host "Inno Setup installed successfully."
}
catch {
    Write-Error "Failed to download Inno Setup installer. Please check the URL and your network connection."
    exit
}

# Add Inno Setup to the system PATH (best-effort, not critical)
$innoSetupPath = "C:\Program Files (x86)\Inno Setup 6"
if (Test-Path $innoSetupPath) {
    try {
        $currentPath = [System.Environment]::GetEnvironmentVariable("Path", "Machine")
        if (-not ($currentPath -like "*$innoSetupPath*")) {
            $newPath = "$currentPath;$innoSetupPath"
            [System.Environment]::SetEnvironmentVariable("Path", $newPath, "Machine")
            Write-Host "Inno Setup added to the system PATH."
        } else {
            Write-Host "Inno Setup is already in the system PATH."
        }
    } catch {
        Write-Warning "Could not update system PATH (no admin rights). The workflow will locate ISCC.exe directly."
    }
} else {
    Write-Warning "Inno Setup directory not found at '$innoSetupPath', skipping PATH update."
}

Write-Host "Script execution finished."