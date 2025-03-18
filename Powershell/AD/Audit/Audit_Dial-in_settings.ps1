#Requires -Modules ActiveDirectory
#Script to check all AD accounts dial-in settings and export to a CSV file
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
$logFile = Join-Path $logPath "Dial-in_Audit_$(Get-Date -Format 'yyyyMMdd_HHmmss').log"
$csvFile = Join-Path $logPath "Dial-in_Audit_$(Get-Date -Format 'yyyyMMdd_HHmmss').csv"

# Function to write to log file
function Write-Log {
    param($Message)
    $logMessage = "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss'): $Message"
    Add-Content -Path $logFile -Value $logMessage
    Write-Host $logMessage
}

try {
    Write-Log "Starting AD dial-in settings audit"
    
    # Get all AD users
    Write-Log "Retrieving all AD user accounts..."
    $users = Get-ADUser -Filter * -Properties msNPAllowDialin, Name, SamAccountName, Enabled, DistinguishedName
    Write-Log "Found $($users.Count) user accounts"

    # Create array to store results
    $results = @()

    foreach ($user in $users) {
        Write-Log "Processing user: $($user.SamAccountName)"
        
        $userDetails = [PSCustomObject]@{
            Username = $user.SamAccountName
            Name = $user.Name
            Enabled = $user.Enabled
            DialInAllowed = $user.msNPAllowDialin
            DistinguishedName = $user.DistinguishedName
            AuditDate = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
        }
        
        $results += $userDetails
    }

    # Export to CSV
    Write-Log "Exporting results to CSV: $csvFile"
    $results | Export-Csv -Path $csvFile -NoTypeInformation

    Write-Log "Audit completed successfully"
    Write-Log "Results exported to: $csvFile"
    Write-Log "Log file location: $logFile"

} catch {
    $errorMessage = $_.Exception.Message
    Write-Log "ERROR: $errorMessage"
    Write-Error $errorMessage
}
