#Requires -Modules ActiveDirectory
#Script to update AD users' dial-in settings from a CSV file
#Author: Joshua Ogden
#Date: 2024-12-31

# Error handling
$ErrorActionPreference = "Stop"

# Create log directory if it doesn't exist
$logPath = "C:\temp\AD_Audit_Logs"
if (-not (Test-Path -Path $logPath)) {
    New-Item -ItemType Directory -Path $logPath | Out-Null
}

# Log file
$logFile = Join-Path $logPath "Dial-in_Update_$(Get-Date -Format 'yyyyMMdd_HHmmss').log"

# Function to write to log file
function Write-Log {
    param($Message)
    $logMessage = "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss'): $Message"
    Add-Content -Path $logFile -Value $logMessage
    Write-Host $logMessage
}

try {
    Write-Log "Starting AD dial-in settings update process"
    
    # Ask the user for the path to the CSV file
    $csvPath = Read-Host "Enter the full path to the CSV file"
    
    # Validate CSV file exists
    if (-not (Test-Path -Path $csvPath)) {
        throw "CSV file not found at path: $csvPath"
    }
    
    Write-Log "Using CSV file: $csvPath"
    
    # Import and check CSV headers
    $users = Import-Csv -Path $csvPath
    $headers = $users[0].PSObject.Properties.Name
    Write-Log "CSV Headers found: $($headers -join ', ')"
    
    # Counter for tracking progress
    $updated = 0
    $failed = 0
    
    # Loop through each user in the CSV file
    foreach ($user in $users) {
        try {
            # Get the username from SamAccountName field
            $username = $user.Username
            if (-not $username) { 
                Write-Log "WARNING: No Username found for user - skipping"
                $failed++
                continue
            }
            
            Write-Log "Processing user: $username"
            
            # Verify user exists in AD
            if (-not (Get-ADUser -Filter {SamAccountName -eq $username})) {
                Write-Log "WARNING: User $username not found in AD - skipping"
                $failed++
                continue
            }
            
            # Get dial-in setting
            $dialInValue = $user.DialInAllowed
            if ($null -eq $dialInValue) { 
                Write-Log "WARNING: Could not find dial-in setting for user $username - skipping"
                $failed++
                continue
            }
            
            # Convert string 'TRUE'/'FALSE' to boolean
            $dialInBool = if ($dialInValue -eq 'TRUE') {
                $true
            } elseif ($dialInValue -eq 'FALSE') {
                $false
            } else {
                Write-Log "WARNING: Invalid dial-in value '$dialInValue' for user $username - must be 'TRUE' or 'FALSE' - skipping"
                $null
            }
            
            if ($null -eq $dialInBool) {
                $failed++
                continue
            }
            
            # Update the dial-in information for the user
            Set-ADUser -Identity $username -Replace @{msNPAllowDialin=$dialInBool}
            Write-Log "Successfully updated dial-in settings for $username to: $dialInBool"
            $updated++
            
        } catch {
            Write-Log "ERROR processing user $username`: $($_.Exception.Message)"
            $failed++
        }
    }
    
    # Summary
    Write-Log "Update process completed"
    Write-Log "Successfully updated: $updated users"
    Write-Log "Failed to update: $failed users"
    Write-Log "Log file location: $logFile"
    
} catch {
    $errorMessage = $_.Exception.Message
    Write-Log "ERROR: $errorMessage"
    Write-Error $errorMessage
}
