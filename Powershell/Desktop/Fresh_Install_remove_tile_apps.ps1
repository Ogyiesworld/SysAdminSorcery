# IMPORTANT: ONLY RUN THIS SCRIPT ON FRESH INSTALLS OF WINDOWS
Write-Host "WARNING: This script is intended ONLY for FRESH installations of Windows." -ForegroundColor Red -BackgroundColor Yellow

# Get list of installed Appx packages, excluding apps with names containing Microsoft, Windows, Realtek, NVIDIA, or AMD
$installedApps = Get-AppxPackage | Where-Object {
    $_.PackageFullName -and
    -not ($_.Name -match 'Microsoft') -and
    -not ($_.Name -match 'Windows') -and
    -not ($_.Name -match 'Realtek') -and
    -not ($_.Name -match 'NVIDIA') -and
    -not ($_.Name -match 'AMD') -and
    -not ($_.Name -match 'Ncsi') -and
    -not ($_.Name -match '[a-fA-F0-9]{8}-[a-fA-F0-9]{4}-[a-fA-F0-9]{4}-[a-fA-F0-9]{4}-[a-fA-F0-9]{12}')

}

foreach ($app in $installedApps) {
    $appName = $app.Name
    $packageFullName = $app.PackageFullName

    # Log the removal attempt
    Write-Host "Attempting to remove $appName ($packageFullName)..." -ForegroundColor Yellow

    try {
        Remove-AppxPackage -Package $packageFullName -ErrorAction Stop
        Write-Host "Successfully removed $appName." -ForegroundColor Green
    } catch {
        Write-Host "Failed to remove $appName $_" -ForegroundColor Red
    }
}

Write-Host "App removal process completed." -ForegroundColor Cyan
 
