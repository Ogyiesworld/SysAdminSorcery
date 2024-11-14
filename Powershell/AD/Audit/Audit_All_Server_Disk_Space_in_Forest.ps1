<#
********************************************************************************
# SUMMARY:      This script iterates through all servers to collect disk size, used space, and free space.
# AUTHOR:       Joshua Ogden
# DESCRIPTION:  Outputs results in a CSV including server name, disk details, space used, and free space, showing a progress bar.
# COMPATIBILITY: Windows PowerShell 3.0 and above
# NOTES:        Ensure you have permissions to access servers and WMI objects.
********************************************************************************
#>

# Variable Declarations
$Servers = @()
$Results = @()
$Date = Get-Date -Format "MMM-dd-yyyy"
$FilePath = ""

# Server Information Retrieval
$Servers = Get-ADComputer -Filter {OperatingSystem -like "*Server*"} | Select-Object -ExpandProperty Name

# Obtain output file path
$UserFilePath = Read-Host "Enter the path and filename to save the CSV file (without extension)"
$FilePath = "${UserFilePath}_$Date.csv"

# Initialize Progress Tracking
$Count = 0
$Total = $Servers.Count

# Loop through each server to get disk info
foreach ($Server in $Servers) {
    $Count++
    Write-Progress -Activity "Checking disk space" -Status "Progress" -PercentComplete (($Count / $Total) * 100)
    Write-Host "Checking disk space on $Server..."

    try {
        # Retrieve disk information
        $Disks = Get-WmiObject -ComputerName $Server -Class Win32_LogicalDisk -Filter "DriveType=3" -ErrorAction Stop

        foreach ($Disk in $Disks) {
            $Results += [PSCustomObject]@{
                Server = $Server
                Drive = $Disk.DeviceID
                Size = "{0:N2} GB" -f ($Disk.Size / 1GB)
                Used = "{0:N2} GB" -f (($Disk.Size - $Disk.FreeSpace) / 1GB)
                Free = "{0:N2} GB" -f ($Disk.FreeSpace / 1GB)
            }
        }
    } catch {
        Write-Warning "Failed to retrieve disk information for server: $Server."
    }
}

# Export results to CSV
try {
    $Results | Export-Csv -Path $FilePath -NoTypeInformation
    Write-Host "Disk space information exported to $FilePath successfully."
} catch {
    Write-Error "An error occurred while exporting results to CSV: $_"
}