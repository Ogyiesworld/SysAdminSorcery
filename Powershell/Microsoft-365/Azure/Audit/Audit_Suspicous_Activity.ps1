<#
********************************************************************************
# SUMMARY:      Azure Suspicious Log Events Checker
# AUTHOR:       Joshua Ogden
# DESCRIPTION:  This script queries Azure Active Directory sign-in logs to find
#               and report suspicious activities related to Enterprise Applications.
# COMPATIBILITY: AzureAD Module, PowerShell 5.1 or later
# NOTES:        Ensure you have the AzureAD module installed and are logged in to Azure.
# AzureAD cmdlet has been deprecated in favor of Microsoft Graph. This script should be refactored to use Microsoft.Graph cmdlets
#********************************************************************************
#>

# Variable Declaration
$DateTimeFilter = [DateTime]::UtcNow.AddHours(-24)
$ExportFile = "AzureSuspiciousLogEvents_$([Cultureinfo]::CurrentCulture.DateTimeFormat.GetMonthName((Get-Date).Month))-$((Get-Date).Day)-$((Get-Date).Year).csv"

# Gather Azure AD sign-in logs
Write-Host "Gathering Azure AD sign-in logs from the past 24 hours..." -ForegroundColor Green
$SignInLogs = Get-AzureADAuditSignInLogs -Filter "createdDateTime ge $DateTimeFilter" -ErrorAction Stop

# Initialize an array to store suspicious events
$SuspiciousEvents = @()

Write-Host "Analyzing log events for suspicious activities..." -ForegroundColor Green
foreach ($Log in $SignInLogs) {
    # Check for failed login attempts
    if ($Log.Status.ErrorCode) {
        $SuspiciousEvents += $Log
        continue
    }

    # Check for sign-ins from unusual locations or unfamiliar devices
    $UserDisplayName = $Log.UserPrincipalName
    $IPAddress = $Log.IPAddress
    $DeviceDetail = $Log.DeviceDetail

    # Example criteria for suspicious activity:
    # Sign-ins from multiple countries within a short period
    # Sign-ins from unknown device models
    if ($IPAddress -match "^\d+\.\d+\.\d+\.\d+$" -or $DeviceDetail.DeviceOS -eq 'Unknown') {
        Write-Host "Suspicious activity detected for user: $UserDisplayName from IP: $IPAddress" -ForegroundColor Yellow
        $SuspiciousEvents += $Log
    }
}

# Export suspicious events to CSV
if ($SuspiciousEvents.Count -gt 0) {
    Write-Host "Exporting suspicious log events to $ExportFile..." -ForegroundColor Green
    $SuspiciousEvents | Export-Csv -Path $ExportFile -NoTypeInformation -ErrorAction Stop
    Write-Host "Export completed successfully!" -ForegroundColor Green
} else {
    Write-Host "No suspicious activities detected in the specified timeframe." -ForegroundColor Cyan
}

# Complete script
Write-Host "Script execution completed!" -ForegroundColor Green