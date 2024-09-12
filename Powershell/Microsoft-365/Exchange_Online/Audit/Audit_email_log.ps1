<#
********************************************************************************
# SUMMARY:      Retrieve Exchange Online Audit Logs
# AUTHOR:       Joshua Ogden
# DESCRIPTION:  This script retrieves the audit logs for changes made to a user's 
#               Exchange Online account. It exports the logs to a CSV for easy review.
# COMPATIBILITY: Exchange Online, Office 365
# NOTES:        Ensure you have the necessary permissions to access audit logs.
********************************************************************************
#>

# Variable Declaration
$UserPrincipalName = Read-Host "Enter the user's UPN (email address):" # Prompted input for user's email address
$StartDate = (Get-Date).AddDays(-30) # Change the start date as required
$EndDate = Get-Date
$ResultSize = 1000 # Adjust the result size if needed
$FileName = "ExchangeAuditLog_$((Get-Date).ToString('MMMM-dd-yyyy')).csv"

# Import required module
Import-Module ExchangeOnlineManagement

# Connect to Exchange Online
Connect-ExchangeOnline

try {
    # Retrieve the audit logs
    $AuditLogs = Search-UnifiedAuditLog -StartDate $StartDate -EndDate $EndDate -UserIds $UserPrincipalName -RecordType ExchangeAdmin -ResultSize $ResultSize

    if ($AuditLogs) {
        # Export the logs to a CSV file
        $AuditLogs | Export-Csv -Path $FileName -NoTypeInformation
        Write-Host "Audit logs exported to $FileName"
    } else {
        Write-Host "No audit logs found for the specified user in the given date range."
    }
}
catch {
    Write-Host "An error occurred: $_"
}
finally {
    # Disconnect from Exchange Online
    Disconnect-ExchangeOnline -Confirm:$false
}