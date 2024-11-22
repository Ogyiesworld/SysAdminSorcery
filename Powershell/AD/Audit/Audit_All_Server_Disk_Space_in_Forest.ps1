<#
********************************************************************************
# SUMMARY:      This script retrieves disk information and space analysis for servers.
# AUTHOR:       Joshua Ogden
# DESCRIPTION:  Outputs to CSV with server and disk details, including largest folders/files.
# COMPATIBILITY: PowerShell 7.0 and above
# NOTES:        Ensure permissions for accessing servers and WMI objects. Double-check all inputs.
********************************************************************************
#>

# Variable Declarations
$Servers = @()
$Results = @()
$Date = Get-Date -Format "MMM-dd-yyyy"
$FilePath = ""

# Server Information Retrieval
$Servers = Get-ADComputer -Filter {OperatingSystem -like "*Server*"} | Select-Object -ExpandProperty Name

#ping each server to check if it is online
foreach ($Server in $Servers) {
    if (Test-Connection -ComputerName $Server -Count 1 -Quiet) {
        Write-Host "$Server is online." -ForegroundColor Green
    }
    else {
        Write-Warning "$Server is offline. Skipping..."
        $Servers = $Servers | Where-Object { $_ -ne $Server }
    }
}

# Obtain output file path
$UserFilePath = Read-Host "Enter the path and filename to save the CSV file (without extension)"
$FilePath = "${UserFilePath}_$Date.csv"

# Initialize Progress Tracking
$Count = 0
$Total = $Servers.Count

# Function to get largest files on a drive
Function Get-LargestItems {
    param (
        [string]$DriveLetter,
        [string]$Server
    )
    
    Invoke-Command -ComputerName $Server -ScriptBlock {
        param ($drive)
        
        try {
            Get-ChildItem -Path "${drive}\" -Recurse -File -ErrorAction SilentlyContinue |
            Sort-Object -Property Length -Descending |
            Select-Object -First 10 |
            ForEach-Object {
                [PSCustomObject]@{
                    Name = $_.Name
                    Path = $_.FullName
                    SizeBytes = $_.Length
                    SizeGB = [math]::Round($_.Length / 1GB, 2)
                }
            }
        }
        catch {
            Write-Warning "Error collecting file data on drive ${drive} on server $Server. $_"
            return @()
        }
    } -ArgumentList $DriveLetter
}

# Function to calculate folder sizes
Function Get-LargestFolders {
    param (
        [string]$DriveLetter,
        [string]$Server
    )
    
    Invoke-Command -ComputerName $Server -ScriptBlock {
        param ($drive)
        
        try {
            Get-ChildItem -Path "${drive}\" -ErrorAction SilentlyContinue | 
            Where-Object { $_.PSIsContainer } |
            ForEach-Object {
                $FolderSize = (Get-ChildItem -Path $_.FullName -Recurse -File -ErrorAction SilentlyContinue |
                    Measure-Object -Property Length -Sum).Sum
                
                [PSCustomObject]@{
                    Name = $_.Name
                    Path = $_.FullName
                    SizeBytes = $FolderSize
                    SizeGB = [math]::Round($FolderSize / 1GB, 2)
                }
            } |
            Sort-Object -Property SizeBytes -Descending |
            Select-Object -First 10
        }
        catch {
            Write-Warning "Error collecting folder data on drive ${drive} on server $Server. $_"
            return @()
        }
    } -ArgumentList $DriveLetter
}

# Loop through each server to get disk info and largest items
foreach ($Server in $Servers) {
    $Count++
    Write-Progress -Activity "Checking disk space" -Status "Server: $Server" -PercentComplete (($Count / $Total) * 100)
    Write-Host "Checking disk space on $Server..." -ForegroundColor Cyan

    try {
        # Retrieve disk information using WMI
        $Disks = Get-WmiObject -ComputerName $Server -Class Win32_LogicalDisk -Filter "DriveType=3" -ErrorAction Stop
        
        foreach ($Disk in $Disks) {
            $DriveLetter = $Disk.DeviceID
            
            # Calculate drive statistics
            $TotalSize = $Disk.Size / 1GB
            $FreeSpace = $Disk.FreeSpace / 1GB
            $UsedSpace = ($Disk.Size - $Disk.FreeSpace) / 1GB
            $PercentFree = ($FreeSpace / $TotalSize) * 100
            $PercentUsed = 100 - $PercentFree

            # Add drive summary
            $Results += [PSCustomObject]@{
                Server = $Server
                Drive = $DriveLetter
                ItemType = "DriveSummary"
                Name = "Drive Summary"
                Path = $DriveLetter
                TotalSize = "{0:N2}" -f $TotalSize
                UsedSpace = "{0:N2}" -f $UsedSpace
                FreeSpace = "{0:N2}" -f $FreeSpace
                PercentFree = "{0:N2}" -f $PercentFree
                PercentUsed = "{0:N2}" -f $PercentUsed
                ItemSize = "N/A"
            }

            # Get largest files
            Write-Host "  Getting largest files on $DriveLetter..." -ForegroundColor Yellow
            $LargestFiles = Get-LargestItems -DriveLetter $DriveLetter -Server $Server
            foreach ($File in $LargestFiles) {
                $Results += [PSCustomObject]@{
                    Server = $Server
                    Drive = $DriveLetter
                    ItemType = "File"
                    Name = $File.Name
                    Path = $File.Path
                    TotalSize = "N/A"
                    UsedSpace = "N/A"
                    FreeSpace = "N/A"
                    PercentFree = "N/A"
                    PercentUsed = "N/A"
                    ItemSize = "{0:N2}" -f $File.SizeGB
                }
            }

            # Get largest folders
            Write-Host "  Getting largest folders on $DriveLetter..." -ForegroundColor Yellow
            $LargestFolders = Get-LargestFolders -DriveLetter $DriveLetter -Server $Server
            foreach ($Folder in $LargestFolders) {
                $Results += [PSCustomObject]@{
                    Server = $Server
                    Drive = $DriveLetter
                    ItemType = "Folder"
                    Name = $Folder.Name
                    Path = $Folder.Path
                    TotalSize = "N/A"
                    UsedSpace = "N/A"
                    FreeSpace = "N/A"
                    PercentFree = "N/A"
                    PercentUsed = "N/A"
                    ItemSize = "{0:N2}" -f $Folder.SizeGB
                }
            }
        }
    }
    catch {
        Write-Warning "Failed to retrieve disk information for server: $Server. Error: $_"
        continue
    }
}

# Export results to CSV
try {
    $Results | Export-Csv -Path $FilePath -NoTypeInformation
    Write-Host "`nDisk space information exported to $FilePath successfully." -ForegroundColor Green
}
catch {
    Write-Error "An error occurred while exporting results to CSV: $_"
}