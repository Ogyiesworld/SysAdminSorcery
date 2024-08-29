<#
********************************************************************************
# SUMMARY:      Generate a report on users with auto forwarding enabled in Exchange Online.
# AUTHOR:       Joshua Ogden
# DESCRIPTION:  This script connects to Exchange Online, retrieves users with auto forwarding 
#               enabled, and generates a CSV report with the current date in its filename.
# COMPATIBILITY: Exchange Online, PowerShell 5.1 or later, Exchange Online Management Module
# NOTES:        Ensure you have the Exchange Online Management Module installed and are connected 
#               to Exchange Online before running this script. The script includes error handling to 
#               manage common connection issues.
********************************************************************************
#>

# Import required modules and connect to services
try {
    # Import the Exchange Online module
    Import-Module ExchangeOnlineManagement -ErrorAction Stop

    # Connect to Exchange Online
    Connect-ExchangeOnline -Credential (Get-Credential) -ErrorAction Stop

    # Get users with auto forwarding enabled
    $AutoForward ForwardingUsers = Get-Mailbox -ResultSize Unlimited | Where-Object {
        $_.ForwardingSMTPAddress -ne $null -or $_.DeliverToMailboxAndForward -eq $true
    } | Select-Object DisplayName, UserPrincipalName, ForwardingSMTPAddress, DeliverToMailboxAndForward

    # Define the report path with the current date
    $Date = Get-Date -Format 'MMMM-d-yyyy'
    $ReportPath = "C:\working\AutoForwardingUsersReport_$Date.csv"

    # Export the results to a CSV file
    $AutoForwardingUsers | Export-Csv -Path $ReportPath -NoTypeInformation

    Write-Host "Report generated successfully at $ReportPath"
} catch {
    Write-Host "An error occurred: $_"
} finally {
    # Disconnect from Exchange Online
    Disconnect-ExchangeOnline -Confirm:$false
}