<#
********************************************************************************
# SUMMARY:      Search and Export Mailbox Audit Log Entries
# AUTHOR:       Joshua Ogden
# DESCRIPTION:  This script searches the mailbox audit logs for specific deletion operations based on user input and 
#               exports the log entries to a CSV file.
# COMPATIBILITY: Compatible with systems that have the requisite permissions to access mailbox audit logs.
# NOTES:        Ensure adequate permissions are in place for running the Search-MailboxAuditLog command.
********************************************************************************
#>

# Variable Declaration
$emailAddress = Read-Host "Enter email address"
$subjectContains = Read-Host "Enter subject contains"
$date = Get-Date -Format "MM-dd-yyyy"
$howManyDays = Read-Host "Enter how many days back to search (e.g., 7)"
$dateminues = (Get-Date).AddDays(-$howManyDays)
$path = "C:\temp\AuditLogs_$date.csv"

try {
    # Search the audit log for specific deletion operations
    $AuditLogs = Search-MailboxAuditLog -Identity $emailAddress -LogonTypes Delegate -ShowDetails -StartDate $dateminues -EndDate $date |
    Where-Object {
        ($_.Operation -eq "SoftDelete" -or $_.Operation -eq "HardDelete" -or $_.Operation -eq "MoveToDeletedItems") -and 
        ($_.SourceItemSubjectsList -like "*$subjectContains*" -or $_.ItemSubject -like "*$subjectContains*")
    }

    # Check for any matching logs
    if ($AuditLogs) {
        # Select important properties and export to CSV
        $AuditLogs | Select-Object RunDate, MailboxOwnerUPN, LogonUserDisplayName, Operation, ItemSubject, ModifiedProperties, DateTime | 
        Export-Csv -Path $path -NoTypeInformation

        Write-Host "Comprehensive audit log search results have been exported to CSV."
    }
    else {
        Write-Host "No relevant audit log entries found within the comprehensive search criteria."
    }

    # Output audit log to screen
    $AuditLogs | Select-Object RunDate, MailboxOwnerUPN, LogonUserDisplayName, Operation, ItemSubject, ModifiedProperties, DateTime
} 
catch {
    Write-Host "An error occurred while searching the audit logs or exporting to CSV: $_.Exception.Message" -ForegroundColor Red
}