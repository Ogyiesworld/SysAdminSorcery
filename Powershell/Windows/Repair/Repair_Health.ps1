<#
********************************************************************************
# SUMMARY:      PowerShell Script for System Health Check and Repair
# AUTHOR:       Joshua Ogden
# DESCRIPTION:  Provides a comprehensive check and repair of system integrity including disk, 
#               component, and file system health using CHKDSK, DISM, and SFC utilities. 
#               Features visual progress tracking.
# COMPATIBILITY: Windows 8 and above (limited functionality on Windows 7).
# NOTES:        Version 1.3. Last Updated: 04/04/2024. Requires administrative privileges.
********************************************************************************
#>

# Variable Declaration
$ProgressPreference = 'SilentlyContinue'
$TotalSteps = 4
$CurrentStep = 0

# Verify Administrative Privileges
if (-NOT ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Warning "Please rerun this script with administrative privileges."
    exit
}

# Function: Update Progress Bar (hidden in background)
Function Update-ProgressBar {
    param (
        [Parameter(Mandatory = $true)]
        [int]$Step,
        [Parameter(Mandatory = $true)]
        [string]$Status
    )
    $PercentComplete = ($Step / $TotalSteps) * 100
    Write-Progress -Activity "System Health Check and Repair" -Status $Status -PercentComplete $PercentComplete
}

# Function: Process Invocation with Output Redirection
Function Invoke-Process {
    param (
        [string]$FilePath,
        [string]$Arguments
    )
    Try {
        $ProcessInfo = New-Object System.Diagnostics.ProcessStartInfo
        $ProcessInfo.FileName = $FilePath
        $ProcessInfo.RedirectStandardOutput = $true
        $ProcessInfo.UseShellExecute = $false
        $ProcessInfo.Arguments = $Arguments
        $ProcessInfo.CreateNoWindow = $true
        $Process = New-Object System.Diagnostics.Process
        $Process.StartInfo = $ProcessInfo
        $Process.Start() | Out-Null
        $Process.WaitForExit()
        $Output = $Process.StandardOutput.ReadToEnd()
        Write-Output $Output
    } Catch {
        Write-Warning "Error during operation: $_"
    }
}

# Disk Integrity Check
$CurrentStep++
Update-ProgressBar -Step $CurrentStep -Status "Checking Disk with CHKDSK (Step 1 of 4)"
Invoke-Process -FilePath "chkdsk" -Arguments "C: /scan"

# Windows Component Repair
$CurrentStep++
Update-ProgressBar -Step $CurrentStep -Status "Cleaning Windows Components with DISM (Step 2 of 4)"
Invoke-Process -FilePath "Dism.exe" -Arguments "/Online /Cleanup-Image /StartComponentCleanup /ResetBase"

# Windows Image Health Check and Repair
$CurrentStep++
Update-ProgressBar -Step $CurrentStep -Status "Repairing Windows Image with DISM (Step 3 of 4)"
Invoke-Process -FilePath "DISM" -Arguments "/Online /Cleanup-Image /ScanHealth"
Invoke-Process -FilePath "DISM" -Arguments "/Online /Cleanup-Image /CheckHealth"
Invoke-Process -FilePath "DISM" -Arguments "/Online /Cleanup-Image /RestoreHealth"

# System File Integrity Check
$CurrentStep++
Update-ProgressBar -Step $CurrentStep -Status "Verifying System Files with SFC (Step 4 of 4)"
Invoke-Process -FilePath "sfc.exe" -Arguments "/scannow"

Write-Host "System Health Check and Repair processes completed successfully. Review output for any necessary supplemental actions." -ForegroundColor Green

# Reset the progress bar preference
$ProgressPreference = 'SilentlyContinue'