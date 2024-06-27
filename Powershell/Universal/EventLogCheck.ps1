<#
********************************************************************************
# SUMMARY:      Check Event Logs for Errors After Reboot
# AUTHOR:       Joshua Ogden
# DESCRIPTION:  This script checks the Windows Event Logs for any critical errors or warnings 
#               that occurred after the system reboot. It leverages the Get-WinEvent cmdlet to query 
#               the Application and System logs, filtering for entries marked as "Error" or "Warning." 
#               It helps in identifying potential issues that may affect system performance or stability 
#               post-reboot. Interpretations for specific event IDs are provided to assist in diagnosing 
#               common problems. This proactive measure aims to ensure the system's reliability and 
#               operational efficiency by addressing any significant events early.
# COMPATIBILITY: Compatible with Windows PowerShell 5.1 and above on Windows 7 SP1, Windows 8.1, 
#               and Windows 10. Administrative privileges are recommended for comprehensive log access.
# NOTES:        Version 1.0. Last Updated: [04/04/2024]. Ensure Event Log Service is running for accurate 
#               log retrieval. Adjustments may be necessary for environments with custom logging solutions.
********************************************************************************
#>

# Checking system uptime
Write-Host "Checking system uptime..."

# Retrieve the system uptime via the Get-CimInstance cmdlet and the Win32_OperatingSystem class
$Uptime = (Get-CimInstance -ClassName Win32_OperatingSystem).LastBootUpTime
$CurrentTime = Get-Date
$UptimeDuration = $CurrentTime - $Uptime

# Convert uptime duration to total hours
$TotalHours = [math]::Round($UptimeDuration.TotalHours, 2)

# Checking system uptime and advising a reboot if system has been running for more than 24 hours
Write-Host "Checking system uptime..."
try {
    $Uptime = (Get-CimInstance -ClassName Win32_OperatingSystem).LastBootUpTime
    $CurrentTime = Get-Date
    $UptimeDuration = $CurrentTime - $Uptime
    $TotalHours = [math]::Round($UptimeDuration.TotalHours, 2)

    if ($TotalHours -gt 24) {
        Write-Host "System has been up for more than 24 hours. It's recommended to reboot before proceeding." -ForegroundColor Red -BackgroundColor Black
        $UserChoice = Read-Host "Press 'K' to skip reboot and continue, or any other key to exit"
        if ($UserChoice -ne 'K') {
            Write-Host "Exiting script. Please reboot the machine and re-run the script." -ForegroundColor Yellow
            exit
        }
    } else {
        Write-Host "System uptime is within the recommended range. Continuing with diagnostics..." -ForegroundColor Green
    }
} catch {
    Write-Host "Error determining system uptime. Ensure you have the required permissions to perform this check." -ForegroundColor Red
}

# Define interpretation messages for specific Event IDs
$EventIDMessages = @{
    4625 = "Logon attempt failure, indicating a security concern."
    4740 = "User account lockout, suggesting potential brute-force attack."
    1102 = "Audit log clearance, could signal possible cover-up actions."
    4771 = "Failure of Kerberos pre-authentication, indicating potential brute-force or misconfiguration."
    4662 = "Operation performed on an object, suggesting potential unauthorized access or modification."
    4728 = "Addition of a member to a security-enabled global group, indicating potential unauthorized group change."
    4720 = "Creation of a user account, pointing to potential unauthorized user creation."
    4732 = "Addition of a member to a security-enabled local group, hinting at potential escalation of privileges."
    41 = "Unclean system reboot, indicating system failure or power loss."
    6008 = "Unexpected system shutdown, suggesting potential system crash."
    1074 = "Process-initiated shutdown, pointing to unexpected or unauthorized shutdown."
    7000 = "Service start failure, indicating service malfunction."
    7009 = "Service connection timeout, hinting at service malfunction."
    7011 = "Service response timeout, indicating service malfunction."
    1000 = "Application error, suggesting application crash or malfunction."
    1002 = "Application hang, indicating the application has stopped responding."
    1026 = ".NET Runtime error, hinting at potential application or system instability."
    55 = "File system corruption on the disk."
    129 = "Warning of potential impending disk issues due to reset."
    153 = "Disk connectivity issue due to surprise disk removal."
    157 = "Disk connectivity issue due to surprise disk removal."
    51 = "Disk error during a paging operation."
    57 = "File system error due to failure in data flushing to the transaction log."
    137 = "NTFS file system error on the default transaction resource manager."
    7031 = "Service crash indicating system instability or service issue."
    7034 = "Unexpected service termination, suggesting system instability or service issue."
    36888 = "Schannel SSL/TLS error, a security concern indicating potential data transmission errors."
    36874 = "SSL/TLS connection error, a security concern with failed secure connections."
}

try {
    $ErrorWarningLogs = Get-WinEvent -LogName Application, System -MaxEvents 100 | Where-Object { $_.LevelDisplayName -eq "Error" -or $_.LevelDisplayName -eq "Warning" }

    if ($ErrorWarningLogs.Count -eq 0) {
        Write-Host "No high-priority Error or Warning events found in the recent logs." -ForegroundColor Green
    } else {
        Write-Host "High-priority Error and Warning events found:" -ForegroundColor Yellow
        foreach ($log in $ErrorWarningLogs) {
            $message = if ($EventIDMessages.ContainsKey($log.Id)) { $EventIDMessages[$log.Id] } else { "Event ID: $($log.Id) does not match known high-priority issues." }
            Write-Host "Log: $($log.LogName) - Event ID: $($log.Id) - Level: $($log.LevelDisplayName) - Interpretation: $message"
        }
    }
} catch {
    Write-Host "Failed to retrieve event logs. Ensure you have the required permissions and that the Event Log service is running." -ForegroundColor Red
}
