<#
********************************************************************************
# SUMMARY:      List Critical Alerts on Servers and Desktops in Domain
# AUTHOR:       Joshua Ogden
# DESCRIPTION:  This script lists all critical alerts on servers and desktops in the domain by accessing each
#               computer remotely, retrieving critical event logs, and exporting the results to a CSV file. Users
#               specify the number of days back to search for critical alerts. The script provides progress updates
#               as it iterates through each computer.
# COMPATIBILITY: Compatible with environments where PowerShell Remoting is enabled and proper permissions are set.
# NOTES:        Ensure that PowerShell Remoting is enabled and configured on all target computers. Execution policy
#               might need to be adjusted to allow script execution. The user running this script must have administrative
#               privileges on the target computers for remote access and event log retrieval.
********************************************************************************
#>

# Read the number of days to search for critical alerts
$Days = Read-Host "How many days back do you want to search for critical alerts?"
$Date = Get-Date -Format "MM-dd-yyyy"
$FilePath = Read-Host "Enter the path and filename to save the CSV file (this will append .csv to the end of the file name): "
$FilePath += "_$Date.csv"

# Get all computers in the domain with 'Server' or 'Windows' in their operating system description
$Computers = Get-ADComputer -Filter {OperatingSystem -like "*Server*" -or OperatingSystem -like "*Windows*"} | Select-Object -ExpandProperty Name

# Initialize an empty array to store results
$Results = @()

# Progress bar initialization
$Count = 0
$Total = $Computers.Count

# Iterate through each computer
foreach ($Computer in $Computers) {
    if (Test-Connection -ComputerName $Computer -Count 1 -Quiet) {
        $Count++
        Write-Progress -Activity "Checking critical alerts" -Status "Progress: $Count of $Total" -PercentComplete (($Count / $Total) * 100)
        Write-Host "Checking critical alerts on $Computer..."
        
        # Retrieve critical events from the computer within the specified number of days
        $Events = Get-WinEvent -ComputerName $Computer -FilterHashtable @{LogName='System'; Level=1,2; StartTime=(Get-Date).AddDays(-$Days)} -ErrorAction SilentlyContinue
        
        # Store results if events are found
        if ($Events) {
            foreach ($Event in $Events) {
                $Results += [PSCustomObject]@{
                    Computer = $Computer
                    Time = $Event.TimeCreated
                    Message = $Event.Message
                }
            }
        }
    } else {
        Write-Host "Computer $Computer is offline. Skipping..."
    }
}

# Export results to CSV
$Results | Export-Csv -Path $FilePath -NoTypeInformation
Write-Host "Data exported to $FilePath"
