<#
********************************************************************************
# SUMMARY:      Audit Exchange mailbox export activity
# AUTHOR:       Joshua Ogden
# DESCRIPTION:  This script audits a specified user's Exchange mailbox to check if 
#               it has ever been exported.
# COMPATIBILITY: Exchange Server 2013 and later, Exchange Online
# NOTES:        Ensure that the user running the script has the necessary permissions 
#               to search mailbox audit logs.
********************************************************************************
#>

# Variables
$UserMailbox = "user@domain.com"   # The mailbox to be audited
$DateFrom = (Get-Date).AddYears(-1)  # Start date for the search, defaulting to one year ago
$DateTo = Get-Date  # End date for the search, defaulting to today

# Loading Exchange Online modules and initiating session (for Exchange Online)
Import-Module ExchangeOnlineManagement
Connect-ExchangeOnline -UserPrincipalName admin@domain.com

# Fetching audit logs for the specified mailbox
Write-Output "Fetching audit logs for $UserMailbox from $($DateFrom.ToShortDateString()) to $($DateTo.ToShortDateString())"
try {
    $AuditLogs = Search-MailboxAuditLog -Mailboxes $UserMailbox -LogonTypes Owner,Delegate -StartDate $DateFrom -EndDate $DateTo -ResultSize Unlimited
    if ($AuditLogs.Count -eq 0) {
        Write-Output "No audit logs found for the specified user."
    } else {
        $ExportEvents = $AuditLogs | Where-Object { $_.Operation -eq "Export" }  # Filtering for export operations
        if ($ExportEvents.Count -eq 0) {
            Write-Output "No mailbox export events found for the specified user."
        } else {
            Write-Output "$($ExportEvents.Count) export event(s) found for $UserMailbox"
            foreach ($Event in $ExportEvents) {
                Write-Output "Date: $($Event.CreationDate) | User: $($Event.UserId) | Operation: $($Event.Operation)"
            }
        }
    }
} catch {
    Write-Error "An error occurred while fetching audit logs: $_"
} finally {
    # Disconnect Exchange session if it's Exchange Online
    Disconnect-ExchangeOnline -Confirm:$false
}