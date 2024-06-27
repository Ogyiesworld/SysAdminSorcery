 <#
********************************************************************************
# SUMMARY:      PowerShell Script for System Health Check and Repair
# AUTHOR:       Joshua Ogden
# DESCRIPTION:  This script performs thorough system checks and repairs, covering disk integrity, 
#               Windows component files, Windows image health, and system file integrity. 
#               It guides the user through CHKDSK, DISM, and SFC utilities, offering a comprehensive 
#               maintenance toolkit for Windows systems. Progress bar included for visual tracking.
# COMPATIBILITY: Compatible with Windows 8 and above. For Windows 7, CHKDSK and SFC functionalities are applicable.
# NOTES:        Version 1.2. Last Updated: [04/04/2024]. Administrative privileges are required to execute the script properly.
********************************************************************************
#>

# Ensure the script is running with administrative privileges
If (-NOT ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Warning "You do not have Administrator rights to run this script! Please rerun this script with elevated privileges."
    Exit
}

# Initialize Progress Bar Parameters
$progressPreference = 'Continue'
$TotalSteps = 4
$CurrentStep = 0

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

# Function to execute a process and display its output with error handling
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
        Write-Warning "An error occurred: $_"
    }
}

# Procedure 1: Disk Check with CHKDSK
$CurrentStep++
Update-ProgressBar -Step $CurrentStep -Status "Checking the Windows partition (Step 1 of 4)"
Invoke-Process -FilePath "chkdsk" -Arguments "C: /scan"

# Procedure 2: Windows Component Files Check and Cleanup DISM
$CurrentStep++
Update-ProgressBar -Step $CurrentStep -Status "Repairing Windows components (Step 2 of 4)"
Invoke-Process -FilePath "Dism.exe" -Arguments "/Online /Cleanup-Image /StartComponentCleanup /ResetBase"
Invoke-Process -FilePath "Dism.exe" -Arguments "/Online /Cleanup-Image /SPSuperseded"


# Procedure 3: Windows Image Health Check and Repair
$CurrentStep++
Update-ProgressBar -Step $CurrentStep -Status "Checking Windows image health (Step 3 of 4)"
Invoke-Process -FilePath "DISM" -Arguments "/Online /Cleanup-Image /CheckHealth"
Invoke-Process -FilePath "DISM" -Arguments "/Online /Cleanup-Image /ScanHealth"
Invoke-Process -FilePath "DISM" -Arguments "/Online /Cleanup-Image /RestoreHealth"

# Procedure 4: System File Check (SFC)
$CurrentStep++
Update-ProgressBar -Step $CurrentStep -Status "Running System File Checker (Step 4 of 4)"
Invoke-Process -FilePath "sfc" -Arguments "/scannow"

Write-Host "All procedures completed. Please check the above outputs for any errors or further actions." -ForegroundColor Green
$progressPreference = 'Continue'
 
