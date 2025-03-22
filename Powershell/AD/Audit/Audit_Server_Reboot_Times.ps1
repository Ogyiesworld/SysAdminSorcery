<#
********************************************************************************
# SUMMARY:      Check Server Reboot Times
# AUTHOR:       Joshua Ogden
# DESCRIPTION:  This script checks the reboot times of a server for a specified number of months.
# COMPATIBILITY: Windows Server with PowerShell 5.1 or higher
# NOTES:        Ensure that the script is run with administrative privileges to access system logs.
#               Run this script directly on the server you want to check.
********************************************************************************
#>

# Prompt the user to enter the number of months to search
Write-Host "Please enter the number of months to search for reboots: " -ForegroundColor Green
$MonthsToSearch = Read-Host

# Validate the input
while ($MonthsToSearch -lt 1 -or $MonthsToSearch -gt 12) {
    Write-Host "Please enter a valid number of months between 1 and 12: " -ForegroundColor Red
    $MonthsToSearch = Read-Host
}

# Get the current date
$CurrentDate = Get-Date

# Calculate the date to search from
$SearchDate = $CurrentDate.AddMonths(-$MonthsToSearch)

# Retrieve the reboot events from the System log
$RebootEvents = Get-EventLog -LogName System -After $SearchDate | Where-Object {
    $_.EventID -eq 1074 -or $_.EventID -eq 6006
}

# Check if there are any reboot events
if ($RebootEvents) {
    # Display each event
    foreach ($Event in $RebootEvents) {
        Write-Output "Reboot Time: $($Event.TimeGenerated) | Event ID: $($Event.EventID) | Message: $($Event.Message)"
    }
} else {
    Write-Output "No reboot events found in the last $MonthsToSearch months."
}
