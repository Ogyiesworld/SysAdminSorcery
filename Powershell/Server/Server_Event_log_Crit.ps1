<#
********************************************************************************
# SUMMARY:      List Critical Alerts on Servers in Domain
# AUTHOR:       Joshua Ogden
# DESCRIPTION:  This script lists all critical alerts on servers in the domain by accessing each server remotely,
#               retrieving critical event logs, and exporting the results to a CSV file. Users specify the number of
#               days back to search for critical alerts. The script provides progress updates as it iterates through each server.
# COMPATIBILITY: Compatible with environments where PowerShell Remoting is enabled and proper permissions are set.
# NOTES:        Ensure that PowerShell Remoting is enabled and configured on all target servers. Execution policy
#               might need to be adjusted to allow script execution. The user running this script must have administrative
#               privileges on the target servers for remote access and event log retrieval.
********************************************************************************
#>

# Read the number of days to search for critical alerts
$days = Read-Host "How many days back do you want to search for critical alerts?"
$date = Get-Date -Format "MM-dd-yyyy"
$FilePath = Read-Host "Enter the path and filename to save the CSV file (this will append .csv to the end of the file name): "
$FilePath += "_$date.csv"

# Get all servers in the domain with 'Server' in their operating system description
$Servers = Get-ADComputer -Filter {OperatingSystem -like "*Server*"} | Select-Object -ExpandProperty Name

# Initialize an empty array to store results
$Results = @()

# Progress bar initialization
$Count = 0
$Total = $Servers.Count

# Iterate through each server
foreach ($Server in $Servers) {
    if (Test-Connection -ComputerName $Server -Count 1 -Quiet) {
        $Count++
        Write-Progress -Activity "Checking critical alerts" -Status "Progress: $Count of $Total" -PercentComplete (($Count / $Total) * 100)
        Write-Host "Checking critical alerts on $Server..."
        
        # Retrieve critical events from the server within the specified number of days
        $Events = Get-WinEvent -ComputerName $Server -FilterHashtable @{LogName='System'; Level=1,2; StartTime=(Get-Date).AddDays(-$days)} -ErrorAction SilentlyContinue
        
        # Store results if events are found
        if ($Events) {
            foreach ($Event in $Events) {
                $Results += [PSCustomObject]@{
                    Server = $Server
                    Time = $Event.TimeCreated
                    Message = $Event.Message
                }
            }
        }
    } else {
        Write-Host "Server $Server is offline. Skipping..."
    }
}

# Export results to CSV
$Results | Export-Csv -Path $FilePath -NoTypeInformation
Write-Host "Data exported to $FilePath"
