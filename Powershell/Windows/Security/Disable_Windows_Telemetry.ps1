<#
****************************************************************************************************
# SUMMARY:      Disables Data Collection and Telemetry Services on Windows
# AUTHOR:       Joshua Ogden
# DESCRIPTION:  This script sets a registry policy to disable data collection, disables the Diagnostic 
#               Tracking Service and the Connected User Experiences and Telemetry service, and removes 
#               the scheduled task for the Connected User Experiences and Telemetry service. It's designed 
#               to enhance user privacy by limiting the amount of data collected by Microsoft.
# COMPATIBILITY: Windows 10, Windows Server 2016, and later versions.
# NOTES:        Version 1.0. Last Updated: [04/03/2024]. Before running this script, ensure you have the 
#               necessary permissions to modify system settings and services. Be aware that disabling these 
#               services might affect Windows features and capabilities. Execution Policy should be set to 
#               allow script execution.
****************************************************************************************************
#>

# Set the policy to disable data collection
try {
    Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection" -Name "AllowTelemetry" -Value 0
    Write-Host "Data collection policy set to disabled." -ForegroundColor Green
} catch {
    Write-Error "Failed to set data collection policy. Error: $_"
}

# Disable the Diagnostic Tracking Service
try {
    $diagTrackService = Get-Service -Name "DiagTrack" -ErrorAction Stop
    $diagTrackService | Set-Service -StartupType Disabled
    Write-Host "Diagnostic Tracking Service disabled." -ForegroundColor Green
} catch {
    Write-Error "Failed to disable Diagnostic Tracking Service. Error: $_"
}

# Disable the Connected User Experiences and Telemetry service
try {
    $dmwappushService = Get-Service -Name "dmwappushservice" -ErrorAction Stop
    $dmwappushService | Set-Service -StartupType Disabled
    Write-Host "Connected User Experiences and Telemetry service disabled." -ForegroundColor Green
} catch {
    Write-Error "Failed to disable Connected User Experiences and Telemetry service. Error: $_"
}

# Remove the scheduled task that starts the Connected User Experiences and Telemetry service
try {
    Unregister-ScheduledTask -TaskName "dmwappush" -TaskPath "\Microsoft\Windows\Application Experience\" -Confirm:$false
    Write-Host "Scheduled task for Connected User Experiences and Telemetry service removed." -ForegroundColor Green
} catch {
    Write-Error "Failed to remove scheduled task for Connected User Experiences and Telemetry service. Error: $_"
}
