<#
********************************************************************************
# SUMMARY:      PowerShell Script for System Health Check and Repair
# AUTHOR:       Joshua Ogden
# DESCRIPTION:  Provides a comprehensive check and repair of system integrity including disk, 
#               component, and file system health using CHKDSK, DISM, and SFC utilities. 
#               Features visual progress tracking and detailed logging.
# COMPATIBILITY: Windows 8 and above (limited functionality on Windows 7).
********************************************************************************
#>

# Variable Declaration
$TotalSteps = 4
$CurrentStep = 0
$LogFile = "C:\temp\SystemHealthRepair.log"
$CurrentUser = [System.Security.Principal.WindowsIdentity]::GetCurrent().Name
$ErrorActionPreference = "Continue" # Don't stop on errors
$WarningPreference = "Continue" # Show warnings

# Create log directory if it doesn't exist
if (-not (Test-Path "C:\temp")) {
    New-Item -Path "C:\temp" -ItemType Directory -Force | Out-Null
}

# Function: Write to log file
Function Write-Log {
    param (
        [Parameter(Mandatory = $true)]
        [string]$Message,
        [Parameter(Mandatory = $false)]
        [string]$Status = "INFO"
    )
    
    # Format timestamp according to guidelines
    $Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $LogEntry = "[$Timestamp] [$Status] [$CurrentUser] $Message"
    
    # Write to log file
    Add-Content -Path $LogFile -Value $LogEntry
    
    # Also display in console with appropriate color
    switch ($Status) {
        "SUCCESS" { Write-Host $LogEntry -ForegroundColor Green }
        "ERROR" { Write-Host $LogEntry -ForegroundColor Red }
        "WARNING" { Write-Host $LogEntry -ForegroundColor Yellow }
        default { Write-Host $LogEntry }
    }
}

# Verify Administrative Privileges
if (-NOT ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Log -Message "Script execution failed: Administrative privileges required" -Status "ERROR"
    Write-Warning "Please rerun this script with administrative privileges."
    exit
}

Write-Log -Message "Starting System Health Check and Repair" -Status "INFO"

# Function: Update Progress Bar
Function Update-ProgressBar {
    param (
        [Parameter(Mandatory = $true)]
        [int]$Step,
        [Parameter(Mandatory = $true)]
        [string]$Status
    )
    $PercentComplete = ($Step / $TotalSteps) * 100
    Write-Progress -Activity "System Health Check and Repair" -Status $Status -PercentComplete $PercentComplete
    Write-Log -Message "Progress: $Status ($Step of $TotalSteps)" -Status "INFO"
}

# Function: Process Invocation with Output Redirection
Function Invoke-Process {
    param (
        [string]$FilePath,
        [string]$Arguments,
        [string]$OperationName,
        [switch]$UseShellExecute = $false,
        [int]$TimeoutSeconds = 3600 # Default timeout of 1 hour
    )
    Try {
        Write-Log -Message "Starting $OperationName $FilePath $Arguments" -Status "INFO"
        
        # Special handling for system commands that need direct console access
        if ($FilePath -eq "chkdsk" -or $FilePath -eq "DISM" -or $FilePath -eq "Dism.exe" -or $FilePath -eq "sfc.exe") {
            Write-Log -Message "Running $FilePath with direct console output" -Status "INFO"
            
            try {
                $process = Start-Process -FilePath $FilePath -ArgumentList $Arguments -NoNewWindow -Wait -PassThru
                $exitCode = $process.ExitCode
                
                if ($exitCode -eq 0) {
                    Write-Log -Message "$OperationName completed successfully with exit code: $exitCode" -Status "SUCCESS"
                } else {
                    Write-Log -Message "$OperationName completed with non-zero exit code: $exitCode" -Status "WARNING"
                }
            } catch {
                Write-Log -Message "Error executing $OperationName $_" -Status "ERROR"
            }
            return
        }
        
        # Standard process handling for other commands
        $ProcessInfo = New-Object System.Diagnostics.ProcessStartInfo
        $ProcessInfo.FileName = $FilePath
        $ProcessInfo.RedirectStandardOutput = -not $UseShellExecute
        $ProcessInfo.RedirectStandardError = -not $UseShellExecute
        $ProcessInfo.UseShellExecute = $UseShellExecute
        $ProcessInfo.Arguments = $Arguments
        $ProcessInfo.CreateNoWindow = -not $UseShellExecute
        
        $Process = New-Object System.Diagnostics.Process
        $Process.StartInfo = $ProcessInfo
        $Process.Start() | Out-Null
        
        # Create a timeout to prevent infinite hanging
        $completed = $Process.WaitForExit($TimeoutSeconds * 1000)
        
        if (-not $completed) {
            Write-Log -Message "$OperationName timed out after $TimeoutSeconds seconds. Attempting to terminate process." -Status "WARNING"
            try {
                $Process.Kill()
                Write-Log -Message "$OperationName process terminated due to timeout" -Status "WARNING"
            } catch {
                Write-Log -Message "Failed to terminate $OperationName process: $_" -Status "ERROR"
            }
            return
        }
        
        if (-not $UseShellExecute) {
            $Output = $Process.StandardOutput.ReadToEnd()
            $ErrorOutput = $Process.StandardError.ReadToEnd()
            
            if ($ErrorOutput) {
                Write-Log -Message "$OperationName reported errors: $ErrorOutput" -Status "WARNING"
            }
        }
        
        # Log the exit code
        if ($Process.ExitCode -eq 0) {
            Write-Log -Message "$OperationName completed successfully with exit code: $($Process.ExitCode)" -Status "SUCCESS"
        } else {
            Write-Log -Message "$OperationName completed with non-zero exit code: $($Process.ExitCode)" -Status "WARNING"
        }
        
        # Return the output if available
        if (-not $UseShellExecute -and $Output) {
            Write-Output $Output
        }
    } Catch {
        Write-Log -Message "Error during $OperationName $_" -Status "ERROR"
        Write-Warning "Error during operation $_"
    }
}

# Disk Integrity Check
$CurrentStep++
Update-ProgressBar -Step $CurrentStep -Status "Checking Disk with CHKDSK"
Invoke-Process -FilePath "chkdsk" -Arguments "C: /scan" -OperationName "Disk Integrity Check"

# Windows Component Repair
$CurrentStep++
Update-ProgressBar -Step $CurrentStep -Status "Cleaning Windows Components with DISM"
Invoke-Process -FilePath "Dism.exe" -Arguments "/Online /Cleanup-Image /StartComponentCleanup /ResetBase" -OperationName "Windows Component Cleanup"

# Windows Image Health Check and Repair
$CurrentStep++
Update-ProgressBar -Step $CurrentStep -Status "Repairing Windows Image with DISM"

# Run DISM commands sequentially with proper error handling
try {
    Write-Log -Message "Running DISM ScanHealth" -Status "INFO"
    Invoke-Process -FilePath "DISM" -Arguments "/Online /Cleanup-Image /ScanHealth" -OperationName "DISM ScanHealth"
    
    Write-Log -Message "Running DISM CheckHealth" -Status "INFO"
    Invoke-Process -FilePath "DISM" -Arguments "/Online /Cleanup-Image /CheckHealth" -OperationName "DISM CheckHealth"
    
    Write-Log -Message "Running DISM RestoreHealth" -Status "INFO"
    Invoke-Process -FilePath "DISM" -Arguments "/Online /Cleanup-Image /RestoreHealth" -OperationName "DISM RestoreHealth"
} catch {
    Write-Log -Message "Error in DISM sequence: $_" -Status "ERROR"
}

# System File Integrity Check
$CurrentStep++
Update-ProgressBar -Step $CurrentStep -Status "Verifying System Files with SFC"
Invoke-Process -FilePath "sfc.exe" -Arguments "/scannow" -OperationName "System File Check"

Write-Log -Message "System Health Check and Repair processes completed successfully" -Status "SUCCESS"
Write-Host "System Health Check and Repair processes completed successfully. Review the log file at $LogFile for details." -ForegroundColor Green