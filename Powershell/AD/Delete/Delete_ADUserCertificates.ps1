# Delete-ADUserCertificates.ps1
# Purpose: Clear all certificates from all user accounts in Active Directory
# Warning: This script will remove ALL certificates. Use with caution.

# Ensure the Active Directory module is loaded
if (-not (Get-Module -Name ActiveDirectory)) {
    try {
        Import-Module ActiveDirectory -ErrorAction Stop
        Write-Host "Active Directory module loaded successfully." -ForegroundColor Green
    }
    catch {
        Write-Host "Error: Failed to load Active Directory module. Please ensure it's installed." -ForegroundColor Red
        Write-Host "You can install it using: Add-WindowsFeature RSAT-AD-PowerShell" -ForegroundColor Yellow
        exit 1
    }
}

# Create log file
$logFile = "AD_Certificate_Cleanup_$(Get-Date -Format 'yyyyMMdd_HHmmss').log"
$logPath = Join-Path -Path $PSScriptRoot -ChildPath $logFile

function Write-Log {
    param (
        [string]$Message,
        [string]$Level = "INFO"
    )
    
    $timeStamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logEntry = "[$timeStamp] [$Level] $Message"
    
    # Write to console with color based on level
    switch ($Level) {
        "ERROR" { Write-Host $logEntry -ForegroundColor Red }
        "WARNING" { Write-Host $logEntry -ForegroundColor Yellow }
        "SUCCESS" { Write-Host $logEntry -ForegroundColor Green }
        default { Write-Host $logEntry }
    }
    
    # Write to log file
    Add-Content -Path $logPath -Value $logEntry
}

# Prompt for confirmation
Write-Host "WARNING: This script will clear ALL certificates from ALL user accounts in the domain." -ForegroundColor Red
Write-Host "This action cannot be undone and may impact certificate-based authentication." -ForegroundColor Red
$confirmation = Read-Host "Are you sure you want to proceed? (Y/N)"

if ($confirmation -ne "Y") {
    Write-Host "Operation cancelled." -ForegroundColor Yellow
    exit
}

# Get all user accounts
Write-Log "Retrieving all user accounts from Active Directory..."
try {
    $users = Get-ADUser -Filter * -Properties userCertificate
    Write-Log "Retrieved $($users.Count) user accounts." -Level "SUCCESS"
}
catch {
    Write-Log "Failed to retrieve user accounts: $_" -Level "ERROR"
    exit 1
}

# Initialize counters
$processedCount = 0
$clearedCount = 0
$errorCount = 0
$noCertsCount = 0

# Process each user
foreach ($user in $users) {
    $processedCount++
    
    # Display progress
    $percentComplete = [math]::Round(($processedCount / $users.Count) * 100, 2)
    Write-Progress -Activity "Clearing user certificates" -Status "Processing $($user.SamAccountName)" -PercentComplete $percentComplete

    # Check if user has certificates
    if ($null -ne $user.userCertificate -and $user.userCertificate.Count -gt 0) {
        $certCount = if ($user.userCertificate -is [System.Array]) { $user.userCertificate.Count } else { 1 }
        
        Write-Log "Clearing $certCount certificate(s) for user: $($user.SamAccountName) ($($user.Name))"
        
        try {
            # Clear all certificates for the user
            Set-ADUser -Identity $user.DistinguishedName -Clear userCertificate
            $clearedCount++
            Write-Log "Successfully cleared certificates for $($user.SamAccountName)" -Level "SUCCESS"
        }
        catch {
            $errorCount++
            Write-Log "Error clearing certificates for $($user.SamAccountName): $_" -Level "ERROR"
        }
    }
    else {
        $noCertsCount++
        Write-Log "No certificates found for user: $($user.SamAccountName)" -Level "INFO"
    }
}

# Summary
Write-Host "`n----- Certificate Cleanup Summary -----" -ForegroundColor Cyan
Write-Host "Total users processed: $processedCount" -ForegroundColor White
Write-Host "Users with certificates cleared: $clearedCount" -ForegroundColor Green
Write-Host "Users with no certificates: $noCertsCount" -ForegroundColor Yellow
Write-Host "Errors encountered: $errorCount" -ForegroundColor $(if ($errorCount -gt 0) { "Red" } else { "Green" })
Write-Host "Log file saved to: $logPath" -ForegroundColor Cyan
Write-Host "----------------------------------------" -ForegroundColor Cyan

# Exit with appropriate code
if ($errorCount -gt 0) {
    exit 1
}
else {
    exit 0
}