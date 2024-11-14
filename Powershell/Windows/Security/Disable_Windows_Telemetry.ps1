<#
****************************************************************************************************
# SUMMARY:      Disables Data Collection and Telemetry Services on Windows
# AUTHOR:       Joshua Ogden
# DESCRIPTION:  This script sets a registry policy to disable data collection, disables the Diagnostic 
#               Tracking Service and the Connected User Experiences and Telemetry service, and removes 
#               the scheduled task for the Connected User Experiences and Telemetry service. It's designed 
#               to enhance user privacy by limiting the amount of data collected by Microsoft.
# COMPATIBILITY: Windows 10, Windows Server 2016, and later versions.
# NOTES:        Version 1.1. Last Updated: [04/03/2024]. Before running this script, ensure you have the 
#               necessary permissions to modify system settings and services. Be aware that disabling these 
#               services might affect Windows features and capabilities. Execution Policy should be set to 
#               allow script execution.
****************************************************************************************************
#>

# Function to check for administrative privileges
function Ensure-Admin {
    if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
        throw "This script must be run as an administrator."
    }
}

# Function to disable a service
function Disable-ServiceByName {
    param (
        [string]$ServiceName
    )
    try {
        $service = Get-Service -Name $ServiceName -ErrorAction Stop
        $service | Set-Service -StartupType Disabled
        Write-Verbose "$ServiceName disabled."
    } catch {
        Write-Error "Failed to disable $ServiceName. Error: $_"
    }
}

# Function to set registry value
function Set-RegistryPolicy {
    param (
        [string]$Path,
        [string]$Name,
        [int]$Value
    )
    try {
        Set-ItemProperty -Path $Path -Name $Name -Value $Value
        Write-Verbose "Registry policy $Name set to $Value."
    } catch {
        Write-Error "Failed to set registry policy $Name. Error: $_"
    }
}

# Function to remove a scheduled task
function Remove-ScheduledTaskByName {
    param (
        [string]$TaskName,
        [string]$TaskPath
    )
    try {
        Unregister-ScheduledTask -TaskName $TaskName -TaskPath $TaskPath -Confirm:$false
        Write-Verbose "Scheduled task $TaskName removed."
    } catch {
        Write-Error "Failed to remove scheduled task $TaskName. Error: $_"
    }
}

# Main script execution
Ensure-Admin

# Setting registry to disable data collection
Set-RegistryPolicy -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection" -Name "AllowTelemetry" -Value 0

# Disable services
Disable-ServiceByName -ServiceName "DiagTrack"
Disable-ServiceByName -ServiceName "dmwappushservice"

# Remove the scheduled task
Remove-ScheduledTaskByName -TaskName "dmwappush" -TaskPath "\Microsoft\Windows\Application Experience\"

Write-Host "Script execution completed." -ForegroundColor Green
