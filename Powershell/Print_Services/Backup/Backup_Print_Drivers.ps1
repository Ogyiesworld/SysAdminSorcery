<#
********************************************************************************
# SUMMARY:      Backup All Print Drivers on the Server
# AUTHOR:       Joshua Ogden
# DESCRIPTION:  This script copies all installed print drivers to a specified 
#               directory, overwriting any existing files with the same names.
# COMPATIBILITY: Windows Server 2012/2016/2019
# NOTES:        Ensure you run PowerShell as Administrator.
********************************************************************************
#>

# Function to ensure the backup directory exists
function Confirm-BackupDirectory {
    param (
        [string]$Path
    )
    # Check if the backup directory exists, if not, create it
    if (-Not (Test-Path -Path $Path)) {
        New-Item -ItemType Directory -Path $Path | Out-Null
    }
}

# Function to backup print drivers
function Backup-PrintDrivers {
    param (
        [string]$BackupDirectory
    )
    try {
        # Get all installed print drivers
        $PrintDrivers = Get-PrinterDriver

        # Loop through each driver and copy its files to the specified directory
        foreach ($Driver in $PrintDrivers) {
            $DriverName = $Driver.Name
            $DriverFiles = Get-ChildItem -Path $Driver.DriverPath -File

            foreach ($File in $DriverFiles) {
                $DestinationPath = Join-Path -Path $BackupDirectory -ChildPath $File.Name
                Copy-Item -Path $File.FullName -Destination $DestinationPath -Force
                Write-Host "Copied file '$($File.Name)' of driver '$DriverName' to '$DestinationPath'"
            }
        }

        Write-Host "All drivers have been backed up to '$BackupDirectory'." -ForegroundColor Green
    }
    catch {
        Write-Error "An error occurred while backing up print drivers: $_"
    }
}

# Main script execution
$BackupDirectory = Read-Host "Enter the full path to the backup directory"
Confirm-BackupDirectory -Path $BackupDirectory
Backup-PrintDrivers -BackupDirectory $BackupDirectory
