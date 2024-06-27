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

# PowerShell Script for Enhanced Windows Defender Troubleshooting and Monitoring with Progress Bar

# Start Logging Process
$logPath = "C:\DefenderLogs_$(Get-Date -Format 'yyyyMMdd_HHmmss').txt"

# Initialize progress bar parameters
$progressParams = @{
    Activity = "Windows Defender Troubleshooting and Monitoring"
    Status = "Initialization"
    PercentComplete = 0
}

# Show initial progress
Write-Progress @progressParams

# Attempt to start the WinDefend and WdNisSvc services
"Attempting to start WinDefend and WdNisSvc services..." | Out-File -FilePath $logPath -Append
$services = @("WinDefend", "WdNisSvc")
$serviceCount = $services.Count
$i = 0
foreach ($service in $services) {
    Try {
        Start-Service $service -ErrorAction Stop
        "$service service started successfully." | Out-File -FilePath $logPath -Append
    } Catch {
        "Failed to start $service $_" | Out-File -FilePath $logPath -Append
    }
    # Update progress bar
    $i++
    $progressParams.PercentComplete = ($i / $serviceCount) * 20 # 20% for services start
    Write-Progress @progressParams
}

# Run DISM to repair corruption
$progressParams.Status = "Running DISM"
$progressParams.PercentComplete = 10
Write-Progress @progressParams
"Running DISM to repair system corruption. This may take several minutes..." | Out-File -FilePath $logPath -Append

$dismLogPath = "$logPath"
Try {
    # Run DISM and wait for it to complete
    Start-Process -FilePath "dism.exe" -ArgumentList "/online /cleanup-image /restorehealth /LogPath:$dismLogPath /LogLevel:4" -Wait -NoNewWindow -PassThru
    
    # Filter out the progress bar lines from DISM log and append useful info to the main log
    Get-Content -Path $dismLogPath | Where-Object { $_ -notmatch "(\[\d+%\])" } | Out-File -FilePath $logPath -Append
    
    # Analyze the DISM log for various outcomes
    $patterns = 'corruption|repair|fixed|pending|error'
    $dismLogAnalysis = Select-String -Path $dismLogPath -Pattern $patterns

    If ($dismLogAnalysis) {
        "DISM log analysis found issues or actions taken. Refer to the DISM log entries in the main log for details:" | Out-File -FilePath $logPath -Append
        $dismLogAnalysis.Line | Out-File -FilePath $logPath -Append
    } Else {
        "DISM completed successfully with no issues found." | Out-File -FilePath $logPath -Append
    }
} Catch {
    "An error occurred while trying to run DISM: $_" | Out-File -FilePath $logPath -Append
}

# Check and potentially set the DisableAntiSpyware registry key
$progressParams.Status = "Checking DisableAntiSpyware registry key"
$progressParams.PercentComplete = 20
Write-Progress @progressParams
"Checking and potentially setting the DisableAntiSpyware registry key..." | Out-File -FilePath $logPath -Append

$regPath = "HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender"
$regName = "DisableAntiSpyware"
$desiredValue = 0 # This script assumes the goal is to ensure Defender is enabled. Adjust as necessary.

If (Test-Path $regPath) {
    $currentValue = (Get-ItemProperty -Path $regPath -Name $regName -ErrorAction SilentlyContinue).$regName
    If ($currentValue -ne $desiredValue) {
        Set-ItemProperty -Path $regPath -Name $regName -Value $desiredValue
        "Updated $regName to $desiredValue at $regPath." | Out-File -FilePath $logPath -Append
    }
    Else {
        "$regName already set to the desired value ($desiredValue) at $regPath." | Out-File -FilePath $logPath -Append
    }
}
Else {
    "Registry path $regPath does not exist. Windows Defender configuration is likely managed by another method." | Out-File -FilePath $logPath -Append
}

# Verify Windows Defender service settings (Automatic start)
$progressParams.Status = "Setting WinDefend service to Automatic"
$progressParams.PercentComplete = 30
Write-Progress @progressParams
"Setting WinDefend service to Automatic start..." | Out-File -FilePath $logPath -Append

Try {
    $winDefendService = Get-Service -Name WinDefend -ErrorAction Stop

    if ($winDefendService.StartType -ne 'Automatic') {
        Set-Service -Name WinDefend -StartupType Automatic -ErrorAction Stop
        "WinDefend service set to Automatic start successfully." | Out-File -FilePath $logPath -Append
    }
    else {
        "WinDefend service is already set to Automatic start. No action needed." | Out-File -FilePath $logPath -Append
    }
} Catch {
    $errorMessage = "Failed to set WinDefend service to Automatic start: $($_.Exception.Message)"
    $errorMessage | Out-File -FilePath $logPath -Append
    Write-Host $errorMessage
}

# Check for Conflicting Antivirus Software
$progressParams.Status = "Check for Conflicting Antivirus Software"
$progressParams.PercentComplete = 40
Write-Progress @progressParams
"Checking for conflicting antivirus software..." | Out-File -FilePath $logPath -Append
$antivirusSoftware = Get-CimInstance -Namespace "Root\SecurityCenter2" -ClassName "AntivirusProduct"
if ($antivirusSoftware) {
    foreach ($av in $antivirusSoftware) {
        $avDetails = "Antivirus Name: $($av.displayName), Product State: $($av.productState)"
        $avDetails | Out-File -FilePath $logPath -Append
    }
} else {
    "No conflicting antivirus software found." | Out-File -FilePath $logPath -Append
}

# Update Windows Defender Antivirus Signatures
$progressParams.Status = "Update Windows Defender Antivirus Signatures"
$progressParams.PercentComplete = 50
Write-Progress @progressParams
"Updating Windows Defender antivirus signatures..." | Out-File -FilePath $logPath -Append

Try {
    Update-MpSignature -ErrorAction Stop
    "Windows Defender antivirus signatures updated successfully." | Out-File -FilePath $logPath -Append
} Catch {
    "Failed to update Windows Defender antivirus signatures: $($_.Exception.Message)" | Out-File -FilePath $logPath -Append
}

# Perform a Quick Windows Defender Scan
$progressParams.Status = "Perform a Quick Windows Defender Scan"
$progressParams.PercentComplete = 60
Write-Progress @progressParams
"Performing a quick Windows Defender scan..." | Out-File -FilePath $logPath -Append

Try {
    $scanResult = Start-MpScan -ScanType QuickScan -ErrorAction Stop
    "Quick Windows Defender scan completed successfully." | Out-File -FilePath $logPath -Append
} Catch {
    "Failed to perform a quick Windows Defender scan: $($_.Exception.Message)" | Out-File -FilePath $logPath -Append
}

# Verify Windows Defender’s Exclusions
$progressParams.Status = "Verify Windows Defender’s Exclusions"
$progressParams.PercentComplete = 70
Write-Progress @progressParams
"Verifying Windows Defender’s exclusions..." | Out-File -FilePath $logPath -Append

$exclusions = Get-MpPreference | Select-Object -ExpandProperty ExclusionPath
if ($exclusions) {
    "Windows Defender exclusions:" | Out-File -FilePath $logPath -Append
    $exclusions | Out-File -FilePath $logPath -Append
} else {
    "No exclusions found in Windows Defender settings." | Out-File -FilePath $logPath -Append
}

# Health and Operational Status Check
$progressParams.Status = "Health and Operational Status Check"
$progressParams.PercentComplete = 80
Write-Progress @progressParams
"Checking Windows Defender’s health and operational status..." | Out-File -FilePath $logPath -Append

$status = Get-MpComputerStatus | Select-Object AMServiceEnabled, AntispywareEnabled, RealTimeProtectionEnabled, OnAccessProtectionEnabled
if ($status) {
    "Windows Defender health and operational status:" | Out-File -FilePath $logPath -Append
    $status | Out-File -FilePath $logPath -Append
} else {
    "Unable to retrieve Windows Defender health and operational status." | Out-File -FilePath $logPath -Append
}

# Extract and log any relevant Windows Defender logs
$progressParams.Status = "Extract Log"
$progressParams.PercentComplete = 99
Write-Progress @progressParams
"Extracting relevant Windows Defender logs..." | Out-File -FilePath $logPath -Append
Get-WinEvent -LogName "Microsoft-Windows-Windows Defender/Operational" | Where-Object {
    $_.LevelDisplayName -eq "Error" -or $_.LevelDisplayName -eq "Warning"
} | ForEach-Object {
    $logEntry = "Time: $($_.TimeCreated), ID: $($_.Id), Level: $($_.LevelDisplayName), Message: $($_.Message)"
    $logEntry | Out-File -FilePath $logPath -Append
}

"Windows Defender troubleshooting and monitoring process completed. Please review the log at $logPath for details." | Out-File -FilePath $logPath -Append
$progressParams.Status = "Completed"
$progressParams.PercentComplete = 100
Write-Progress @progressParams
