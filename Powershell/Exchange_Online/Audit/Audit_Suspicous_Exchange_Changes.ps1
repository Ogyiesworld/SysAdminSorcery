<#
********************************************************************************
# SUMMARY:      Exchange Online Configuration Change Audit
# AUTHOR:       Joshua Ogden
# DESCRIPTION:  This script audits Exchange Online for any recent configuration changes that 
#               would be considered suspicious and exports the results to a CSV file.
# COMPATIBILITY: This script is compatible with Exchange Online 
# NOTES:        Ensure you have the necessary permissions to access audit logs in Exchange Online.
********************************************************************************
#>

# Variable Declaration
$StartDate = (Get-Date).AddDays(-30)  # Default: Last 30 days
$EndDate = Get-Date
$FileNameTemplate = "ExchangeOnlineConfigAudit_{0:MMMM-d-yyyy}.csv" -f (Get-Date)
$ResultFileName = Join-Path -Path "C:\Temp" -ChildPath $FileNameTemplate

# Function to get suspicious configuration changes
Function Get-SuspiciousConfigChanges {
    Param (
        [DateTime]$StartDate,
        [DateTime]$EndDate
    )

    Try {
        $AuditLogs = Search-UnifiedAuditLog -StartDate $StartDate -EndDate $EndDate -RecordType "ExchangeAdmin" -ErrorAction Stop
        $SuspiciousChanges = $AuditLogs | Where-Object { $_.Operations -match "Add-MailboxPermission|Set-Mailbox|Set-TransportRule|New-ManagementRoleAssignment" }
        
        If ($SuspiciousChanges.Count -gt 0) {
            $SuspiciousChanges | Select-Object -Property CreationDate, UserId, Operations, AuditData | Export-Csv -Path $ResultFileName -NoTypeInformation
            Write-Host "Suspicious configuration changes found and exported to $ResultFileName"
        }
        Else {
            Write-Host "No suspicious configuration changes found within the specified date range."
        }
    }
    Catch {
        Write-Error "An error occurred while fetching or processing audit logs: $_"
    }
}
# Adjust start and end dates as needed or uncomment the prompts to make them interactive
# $StartDate = Read-Host "Please enter the start date (e.g., '2023-01-01')"
# $EndDate = Read-Host "Please enter the end date (e.g., '2023-01-31')"

Get-SuspiciousConfigChanges -StartDate $StartDate -EndDate $EndDate