<#
********************************************************************************
# SUMMARY:      Retrieve User Login Attempts for the Last X Hours
# AUTHOR:       Joshua Ogden
# DESCRIPTION:  This script retrieves login attempts from the security event log 
#               for a specified user within the last X hours.
# COMPATIBILITY: Windows PowerShell 5.1, PowerShell 7
# NOTES:        Ensure that the script is run with administrative privileges to 
#               access the security event log.
********************************************************************************
#>

# Username
$UserName = Read-Host "Enter the username to check login attempts for"

# Hours
$X = Read-Host "Enter the number of hours to check login attempts for"

# Function to retrieve login attempts
function Get-UserLoginAttempts {
    param (
        [string]$UserName
    )
    
    # Calculate the time range
    $startTime = (Get-Date).AddHours(-$X)
    $endTime = Get-Date

    # Query the security event log for login attempts (both successful and failed)
    $filter = @{
        LogName = 'Security'
        ID = 4624, 4625
        StartTime = $startTime
        EndTime = $endTime
    }
    $events = Get-WinEvent -FilterHashtable $filter | Where-Object {
        $_.Properties[5].Value -eq $UserName
    }

    # Output the events with additional information
    $events | Select-Object `
        TimeCreated, `
        @{Name="UserName";Expression={$_.Properties[5].Value}}, `
        @{Name="IP Address";Expression={$_.Properties[18].Value}}, `
        @{Name="Status";Expression={if ($_.Id -eq 4624) {"Success"} else {"Failure"}}}, `
        @{Name="FailureReason";Expression={if ($_.Id -eq 4625) {$_.Properties[11].Value} else {"N/A"}}}
}

# Main script execution
try {
    # Retrieve login attempts
    $loginAttempts = Get-UserLoginAttempts -UserName $UserName

    # Display the results
    if ($loginAttempts) {
        Write-Output "Login attempts for user '$UserName' in the last $X hours:"
        $loginAttempts | Format-Table -AutoSize
    } else {
        Write-Output "No login attempts found for user '$UserName' in the last $X hours."
    }
} catch {
    Write-Error "An error occurred while retrieving login attempts: $_"
}
