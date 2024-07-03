<#
********************************************************************************
# SUMMARY:      Diagnostic Script for RDS Temp Profiles
# AUTHOR:       Joshua Ogden
# DESCRIPTION:  This script gathers diagnostic information to help determine 
#               why users are receiving temporary profiles on an RDS server.
# COMPATIBILITY: Windows Server 2012 and later
# NOTES:        This script performs only diagnostic checks and does not make 
#               any changes to the system.
********************************************************************************
#>

# Function to gather event log information related to user profiles
function Get-UserProfileLogs {
    Write-Host "Gathering User Profile Service logs..."
    Get-WinEvent -LogName "Microsoft-Windows-User Profile Service/Operational" |
    Where-Object { $_.Id -in 1511, 1515, 1518, 1521, 1530 } |
    Select-Object TimeCreated, Id, Message
}

# Function to check for profile list registry issues
function Get-ProfileListRegistry {
    Write-Host "Checking Profile List in Registry..."
    Get-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\ProfileList\*" |
    Select-Object PSChildName, ProfileImagePath, State
}

# Function to check disk space
function Get-DiskSpace {
    Write-Host "Checking Disk Space on C: Drive..."
    Get-PSDrive -Name C |
    Select-Object Name, Used, Free, @{Name="Used(GB)"; Expression={"{0:N2}" -f ($_.Used/1GB)}}, @{Name="Free(GB)"; Expression={"{0:N2}" -f ($_.Free/1GB)}}
}

# Function to check user profile directory permissions
function Get-UserProfilePermissions {
    Write-Host "Checking permissions on user profile directory..."
    Get-Acl -Path "C:\Users" |
    Select-Object Path, Owner, AccessToString
}

# Function to gather RDS session information
function Get-RDSSessionInfo {
    Write-Host "Gathering RDS Session information..."
    quser
}

# Function to gather system event logs
function Get-SystemLogs {
    Write-Host "Gathering System event logs..."
    Get-WinEvent -LogName System |
    Where-Object { $_.Id -in 6005, 6006, 6008, 41 } |
    Select-Object TimeCreated, Id, Message
}

# Main script execution
Write-Host "Starting RDS Temp Profile Diagnostics..."

$profileLogs = Get-UserProfileLogs
$profileRegistry = Get-ProfileListRegistry
$diskSpace = Get-DiskSpace
$profilePermissions = Get-UserProfilePermissions
$rdsSessionInfo = Get-RDSSessionInfo
$systemLogs = Get-SystemLogs

# Output the gathered information
Write-Host "User Profile Service Logs:"
$profileLogs | Format-Table -AutoSize

Write-Host "`nProfile List Registry Information:"
$profileRegistry | Format-Table -AutoSize

Write-Host "`nDisk Space Information:"
$diskSpace | Format-Table -AutoSize

Write-Host "`nUser Profile Directory Permissions:"
$profilePermissions | Format-Table -AutoSize

Write-Host "`nRDS Session Information:"
$rdsSessionInfo

Write-Host "`nSystem Event Logs:"
$systemLogs | Format-Table -AutoSize

Write-Host "Diagnostics complete. Please review the gathered information for potential issues."
