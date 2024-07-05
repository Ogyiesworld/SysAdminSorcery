<#
********************************************************************************
# SUMMARY:      This script is to iterate through all servers and pull their disk size and disk space used and free
# AUTHOR:       Joshua Ogden
# DESCRIPTION:  This script will output the results to a CSV file with the server name, disk size, disk space used, and disk space free.
#               It will also show a progress bar as it goes through each server.
# COMPATIBILITY: Windows PowerShell 3.0 and above
# NOTES:        Ensure you have the necessary permissions to access the servers and WMI objects.
********************************************************************************
#>

# Get all servers in the domain
$Servers = Get-ADComputer -Filter {OperatingSystem -like "*Server*"} | Select-Object -ExpandProperty Name

# Define the output file path
$date = Get-Date -Format "MM-dd-yyyy"
$FilePath = Read-Host "Enter the path and filename to save the CSV file this will append .csv to the end of the file name "
$FilePath += "_$Date.csv"

# Create an empty array to store the results
$Results = @()

# Progress bar for counting servers
$Count = 0
$Total = $Servers.Count

# Loop through each server
foreach ($Server in $Servers) {
    $Count++
    Write-Progress -Activity "Checking disk space" -Status "Progress" -PercentComplete (($Count / $Total) * 100)
    Write-Host "Checking disk space on $Server..."
    
    # Get the disk information from the server
    $Disks = Get-WmiObject -ComputerName $Server -Class Win32_LogicalDisk -Filter "DriveType=3" -ErrorAction SilentlyContinue
    
    # If disks are found, add them to the results
    if ($Disks) {
        foreach ($Disk in $Disks) {
            $Results += [PSCustomObject]@{
                Server = $Server
                Drive = $Disk.DeviceID
                Size = "{0:N2}" -f ($Disk.Size / 1GB) + " GB"
                Used = "{0:N2}" -f ($Disk.Size / 1GB - $Disk.FreeSpace / 1GB) + " GB"
                Free = "{0:N2}" -f ($Disk.FreeSpace / 1GB) + " GB"
            }
        }
    }
}

# Output the results to a CSV
$Results | Export-Csv -Path $FilePath -NoTypeInformation
