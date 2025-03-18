#Requires -Modules ExchangeOnlineManagement
<#
.SYNOPSIS
    Removes all email forwarding configurations from mailboxes in Exchange Online.
.DESCRIPTION
    This script removes all email forwarding configurations from all mailboxes in the Exchange Online tenant.
    It disables both ForwardingSmtpAddress and DeliverToMailboxAndForward settings.
.NOTES
    Required Permissions: Exchange Administrator or Global Administrator
    Author: joshua ogden
    Last Modified: 2025-01-30
#>

# Create a log file
$logFile = ".\ForwardingRemoval_$(Get-Date -Format 'yyyyMMdd_HHmmss').log"
$ErrorActionPreference = "Stop"

function Write-Log {
    param($Message)
    $logMessage = "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss'): $Message"
    Write-Host $logMessage
    Add-Content -Path $logFile -Value $logMessage
}

try {
    Write-Log "Script started - Connecting to Exchange Online..."
    Connect-ExchangeOnline -ErrorAction Stop
    
    Write-Log "Getting all mailboxes..."
    $mailboxes = Get-Mailbox -ResultSize Unlimited
    $totalMailboxes = ($mailboxes | Measure-Object).Count
    Write-Log "Found $totalMailboxes mailboxes to process"
    
    $confirmation = Read-Host "Are you sure you want to remove forwarding from all $totalMailboxes mailboxes? (Y/N)"
    if ($confirmation -ne 'Y') {
        Write-Log "Operation cancelled by user"
        exit
    }
    
    $i = 0
    foreach ($mailbox in $mailboxes) {
        $i++
        $percentComplete = [math]::Round(($i / $totalMailboxes) * 100, 2)
        Write-Progress -Activity "Removing forwarding" -Status "$i of $totalMailboxes ($percentComplete%)" -PercentComplete $percentComplete
        
        try {
            $currentForwarding = $mailbox.ForwardingSmtpAddress
            Set-Mailbox -Identity $mailbox.Identity -ForwardingSmtpAddress $null -DeliverToMailboxAndForward $false -ErrorAction Stop
            if ($currentForwarding) {
                Write-Log "Removed forwarding from $($mailbox.UserPrincipalName) (Previous forwarding: $currentForwarding)"
            } else {
                Write-Log "Processed $($mailbox.UserPrincipalName) - No forwarding was configured"
            }
        }
        catch {
            Write-Log "ERROR processing $($mailbox.UserPrincipalName): $($_.Exception.Message)"
        }
    }
}
catch {
    Write-Log "CRITICAL ERROR: $($_.Exception.Message)"
}
finally {
    Write-Progress -Activity "Removing forwarding" -Completed
    Write-Log "Script completed - Disconnecting from Exchange Online"
    Disconnect-ExchangeOnline -Confirm:$false
    Write-Log "Log file saved to: $logFile"
}
