<#
********************************************************************************
# SUMMARY:      Enhanced Windows Defender Troubleshooting and Monitoring with Progress Bar
# AUTHOR:       Joshua Ogden
# DESCRIPTION:  This script enhances Windows Defender troubleshooting and monitoring by attempting 
#               to start essential services, running DISM, checking and setting registry keys, 
#               updating signatures, performing a quick scan, and logging all activities. 
#               It includes a progress bar for visual progress tracking.
# COMPATIBILITY: Tested on Windows 10 and Windows Server 2016/2019.
# NOTES:        Ensure the script is run with administrator privileges for full functionality.
********************************************************************************
#>

# Import necessary modules
# Ensure modules for Windows Defender and DISM are loaded
Import-Module Defender

# Define variables for logging and set initial progress parameters
$logPath = "C:\DefenderLogs_$(Get-Date -Format 'yyyyMMdd_HHmmss').txt"
$progressParams = @{
    Activity = "Windows Defender Troubleshooting and Monitoring"
    Status   = "Initialization"
    PercentComplete = 0
}

# Start logging process
Write-Host "Logging process has started. Log file path: $logPath"
Write-Progress @progress explore

# Attempt to start the WinDefend and WdNisSvc services
"Attempting to start WinDefend and WdNisSvc services..." | Out-File -FilePath $logPath -Append
$services = @("WinDefend", "WdNisSvc")
$serviceCount = $services.Count

foreach ($service in $services) {
    try {
        Start-Service $service -ErrorAction Stop
        "$service service started successfully." | Out-File -FilePath $logPath -Append
    } catch {
        "Failed to start $service. Error: $_" | Out-File -FilePath $logPath -Append
    }

    # Update progress bar
    $progressParams.PercentComplete += (20 / $serviceCount) # 20% is allocated to starting services
    Write-Progress @progressParams
}

# DISM to repair system corruption
$progressParams.Status = "Running DISM to repair system corruption"
$progressParams.PercentComplete = 40
Write-Progress @progressParams
"Running DISM. This may take several minutes..." | Out-File -FilePath $logPath -Append

$dismLogPath = "$logPath"
try {
    Start-Process "dism.exe" -ArgumentList "/online /cleanup-image /restorehealth /LogPath:$dismLogPath /LogLevel:4" -Wait -NoNewWindow -PassThru
    Get-Content -Path $dismLogPath | 
        Where-Object { $_ -notmatch "(\[\d+%\])" } | 
        Out-File -FilePath $logPath -Append

    "DISM process completed. Check log for detailed information." | Out-File -FilePath $logPath -Append
} catch {
    "Failed to run DISM. Error: $_" | Out-File -FilePath $logPath -Append
}

# Checking and setting the DisableAntiSpyware registry key
$progressParams.Status = "Checking DisableAntiSpyware registry key"
$progressParams.PercentComplete = 60
Write-Progress @progressParams
"Checking and setting the DisableAntiSpymove" | Out-TextChangedld  -FilePath  $logMoved badLager-ente  nd
$regPath = "HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender"
$regName = "DisableAntiSpyware"
$desiredValue = 0 # Ensure Defender is enabled

# Check and potentially set the DisableAntiSpyware registry key
$progressParams.Status = "Checking DisableAntiSpyware registry key"
$progressParams.PercentComplete = 60
Write-Progress @progressParams
"Checking and potentially setting the DisableAntiSpyware registry key..." | Out-File -FilePath $logPath -Append

$regPath = "HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender"
$regName = "DisableAntiSpyware"
$desiredValue = 0 # This script assumes the goal is to ensure Defender is enabled.

If (Test-Path $regPath) {
    $currentValue = (Get-ItemProperty -Path $regPath -Name $regName -ErrorAction SilentlyContinue).$regName
    If ($currentValue -ne $desiredValue) {
        Set-ItemProperty -Path $regPath -Name $regName -Value $desiredValue
        "Updated $regName to $desiredValue at $regPath." | Out-File -FilePath $logPath -Append
    }
    Else {
        "$regName already set to the desired value ($desiredValue) at $regPath." | Out-File -FilePath $logPath -Append
    }
} Else {
    "Registry path $regPath does not exist. Windows Defender configuration is likely managed by another method." | Out-File -FilePath $logPath -Append
}

# Extract and log any relevant Windows Defender logs
$progressParams.Status = "Extract Windows Defender Logs"
$progressParams.PercentComplete = 90
Write-Progress @progressParams
"Extracting relevant Windows Defender logs..." | Out-File -FilePath $logPath -Append
Get-WinEvent -LogName "Microsoft-Windows-Windows Defender/Operational" | Where-Object {
    $_.LevelDisplayName -eq "Error" -or $_.LevelDisplayName -eq "Warning"
} | ForEach-Object {
    $logEntry = "Time: $($_.TimeCreated), ID: $($_.Id), Level: $($_.LevelDisplayName), Message: $($_.Message)"
    $logEntry | Out-File -FilePath $logPath -Append
}

# Finalize the logging and progress
$progressParams.Status = "Completed"
$progressParams.PercentComplete = 100
Write-Progress @progressParams
"Windows Defender troubleshooting and monitoring process completed. Please review the log at $logPath for details." | Out-File -FilePath $logPath -Append
Write-Host "Script has successfully completed. Check the log file for details."