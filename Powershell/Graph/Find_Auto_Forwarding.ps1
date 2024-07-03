<#
********************************************************************************
# SUMMARY:      Generate a report on users with auto forwarding enabled in Exchange Online.
# AUTHOR:       Joshua Ogden
# DESCRIPTION:  This script connects to Exchange Online, retrieves users with auto forwarding enabled, and generates a CSV report.
# COMPATIBILITY: Exchange Online, PowerShell 5.1 or later, Exchange Online Management Module
# NOTES:        Ensure you have the Exchange Online Management Module installed and are connected to Exchange Online before running this script.
********************************************************************************
#>

#connect to graph
Connect-Graph
# Import the Exchange Online module
Import-Module ExchangeOnlineManagement

# Connect to Exchange Online
Connect-ExchangeOnline 

# Get users with auto forwarding enabled
$AutoForwardingUsers = Get-Mailbox -ResultSize Unlimited | Where-Object {
    $_.ForwardingSMTPAddress -ne $null -or $_.DeliverToMailboxAndForward -eq $true
} | Select-Object DisplayName, UserPrincipalName, ForwardingSMTPAddress, DeliverToMailboxAndForward

# Export the results to a CSV file
$ReportPath = "C:\kworking\AutoForwardingUsersReport.csv"
$AutoForwardingUsers | Export-Csv -Path $ReportPath -NoTypeInformation

Write-Host "Report generated successfully at $ReportPath"

# Disconnect from Exchange Online
Disconnect-ExchangeOnline -Confirm:$false
