<#
********************************************************************************
# SUMMARY:      Backup all print drivers on the server
# AUTHOR:       Joshua Ogden
# DESCRIPTION:  This script copies all installed print drivers to a specified 
#               directory, overwriting any existing files with the same names.
# COMPATIBILITY: Windows Server 2012/2016/2019
# NOTES:        Ensure you run PowerShell as Administrator.
********************************************************************************
#>

# Specify the directory where the print drivers will be saved
$backupDirectory = Read-Host "Enter the full path to the backup directory"

# Check if the backup directory exists, if not, create it
if (-Not (Test-Path -Path $backupDirectory)) {
    New-Item -ItemType Directory -Path $backupDirectory | Out-Null
}

# Get all installed print drivers
$printDrivers = Get-PrinterDriver

# Loop through each driver and copy its files to the specified directory
foreach ($driver in $printDrivers) {
    $driverName = $driver.Name
    $driverFiles = Get-ChildItem -Path $driver.DriverPath -File
    foreach ($file in $driverFiles) {
        $destinationPath = Join-Path -Path $backupDirectory -ChildPath $file.Name
        Copy-Item -Path $file.FullName -Destination $destinationPath -Force
        Write-Host "Copied file '$($file.Name)' of driver '$driverName' to '$destinationPath'"
    }
}

Write-Host "All drivers have been backed up to '$backupDirectory'."