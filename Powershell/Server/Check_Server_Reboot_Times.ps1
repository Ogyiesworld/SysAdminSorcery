<#
********************************************************************************
# SUMMARY:      Check Server Reboot Times
# AUTHOR:       Joshua Ogden
# DESCRIPTION:  This script checks the reboot times of a server for the last three months.
# COMPATIBILITY: Windows Server with PowerShell 5.1 or higher
# NOTES:        Ensure that the script is run with administrative privileges to access system logs.
********************************************************************************
#>

# Get the current date
$CurrentDate = Get-Date

# Calculate the date three months ago from the current date
$DateThreeMonthsAgo = $CurrentDate.AddMonths(-3)

# Retrieve the reboot events from the System log
$RebootEvents = Get-EventLog -LogName System -After $DateThreeMonthsAgo | Where-Object {
    $_.EventID -eq 1074 -or $_.EventID -eq 6006
}

# Check if there are any reboot events
if ($RebootEvents) {
    # Display each event
    foreach ($Event in $RebootEvents) {
        Write-Output "Reboot Time: $($Event.TimeGenerated) | Event ID: $($Event.EventID) | Message: $($Event.Message)"
    }
} else {
    Write-Output "No reboot events found in the last three months."
}
