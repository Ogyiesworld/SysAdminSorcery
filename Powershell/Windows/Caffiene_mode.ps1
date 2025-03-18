# Author: Joshua Ogden
# Purpose: Prevents computer from sleeping for 8 hours using Windows API calls
# Created: 2025-02-05
# Last Modified: 2025-02-05

# Function to write log entries
function Write-Log {
    param(
        [string]$Message,
        [string]$Status
    )
    
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $username = $env:USERNAME
    $logMessage = "$timestamp - User: $username - Status: $status - $Message"
    $logPath = "c:\temp\caffeine_mode.log"
    
    Add-Content -Path $logPath -Value $logMessage
}

# Function to start caffeine mode
function Start-CaffeineMode {
    $signature = @"
    [DllImport("kernel32.dll", CharSet = CharSet.Auto, SetLastError = true)]
    public static extern uint SetThreadExecutionState(uint esFlags);
"@

    $ES_CONTINUOUS = [uint32]"0x80000000"
    $ES_SYSTEM_REQUIRED = [uint32]"0x00000001"
    $ES_DISPLAY_REQUIRED = [uint32]"0x00000002"

    try {
        # Add the API type
        $API = Add-Type -MemberDefinition $signature -Name "WinAPI" -Namespace "Win32Functions" -PassThru

        # Create flag file to indicate script is running
        $flagFile = "c:\temp\caffeine_mode_running.flag"
        New-Item -Path $flagFile -ItemType File -Force | Out-Null

        # Log script start
        Write-Log -Message "Starting Caffeine Mode in background" -Status "Info"
        Write-Host "Caffeine Mode running in background."
        Write-Host "To stop it, either:"
        Write-Host "1. Delete the flag file: $flagFile"
        Write-Host "2. Run: Remove-Item '$flagFile'"
        
        # Prevent system sleep
        Write-Log -Message "Preventing system sleep" -Status "Attempting"
        $API::SetThreadExecutionState($ES_CONTINUOUS -bor $ES_SYSTEM_REQUIRED -bor $ES_DISPLAY_REQUIRED)
        Write-Log -Message "System sleep prevented successfully" -Status "Success"
        
        # Wait for 8 hours or until flag file is deleted
        $endTime = (Get-Date).AddHours(8)
        Write-Log -Message "Starting wait period until $endTime" -Status "Info"
        
        while ((Get-Date) -lt $endTime -and (Test-Path $flagFile)) {
            Start-Sleep -Seconds 1
        }
        
        # Restore default power settings
        Write-Log -Message "Restoring default power settings" -Status "Attempting"
        $API::SetThreadExecutionState($ES_CONTINUOUS)
        Write-Log -Message "Default power settings restored" -Status "Success"
        
        # Clean up flag file if it still exists
        if (Test-Path $flagFile) {
            Remove-Item $flagFile -Force
        }
        
        Write-Log -Message "Caffeine Mode completed successfully" -Status "Success"
    }
    catch {
        Write-Log -Message "Error occurred: $($_.Exception.Message)" -Status "Error"
        # Ensure we restore default power settings even if there's an error
        if ($API) {
            $API::SetThreadExecutionState($ES_CONTINUOUS)
            Write-Log -Message "Default power settings restored after error" -Status "Info"
        }
        # Clean up flag file if it exists
        if (Test-Path $flagFile) {
            Remove-Item $flagFile -Force
        }
        throw
    }
}

# Function to stop caffeine mode
function Stop-CaffeineMode {
    $flagFile = "c:\temp\caffeine_mode_running.flag"
    if (Test-Path $flagFile) {
        Remove-Item $flagFile -Force
        Write-Host "Stopping Caffeine Mode..."
    } else {
        Write-Host "Caffeine Mode is not running."
    }
}

# Check if -Stop parameter is provided
param(
    [switch]$Stop
)

if ($Stop) {
    Stop-CaffeineMode
} else {
    # Start the script in a background job
    $scriptPath = $MyInvocation.MyCommand.Path
    Start-Job -ScriptBlock { 
        param($path)
        & $path
    } -ArgumentList $scriptPath | Out-Null
    
    Write-Host "Caffeine Mode started in background. You can close this window."
    Write-Host "To stop it, run: $scriptPath -Stop"
}
