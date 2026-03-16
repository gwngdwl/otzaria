# PowerShell Script to Install Inno Setup

# Install via winget (always gets the latest stable version)
Write-Host "Downloading Inno Setup..."
try {
    winget install -e --id JRSoftware.InnoSetup --silent --accept-package-agreements --accept-source-agreements
    Write-Host "Inno Setup installed successfully."
}
catch {
    Write-Error "Failed to download Inno Setup installer. Please check the URL and your network connection."
    exit
}

# 4. Add Inno Setup to the System PATH
Write-Host "Adding Inno Setup to the system PATH..."
try {
    # Default installation path for Inno Setup
    $innoSetupPath = "C:\Program Files (x86)\Inno Setup 6"

    if (Test-Path $innoSetupPath) {
        $currentPath = [System.Environment]::GetEnvironmentVariable("Path", "Machine")
        if (-not ($currentPath -like "*$innoSetupPath*")) {
            $newPath = "$currentPath;$innoSetupPath"
            [System.Environment]::SetEnvironmentVariable("Path", $newPath, "Machine")
            # Note: A system-wide PATH change requires a restart of the terminal/session to take effect.
            Write-Host "Inno Setup added to the system PATH. Please restart your terminal for the changes to take effect."
        } else {
            Write-Host "Inno Setup is already in the system PATH."
        }
    } else {
        Write-Warning "Could not find Inno Setup installation directory at '$innoSetupPath'. PATH not updated."
    }
}
catch {
    Write-Error "Failed to add Inno Setup to the PATH."
}

Write-Host "Script execution finished."