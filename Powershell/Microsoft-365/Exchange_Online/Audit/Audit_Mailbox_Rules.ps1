<#
********************************************************************************
# SUMMARY:      List all Mailbox Rules for a User
# AUTHOR:       Joshua Ogden
# DESCRIPTION:  This script retrieves and lists all mailbox rules for a specified 
#               user in Microsoft Exchange. It outputs the details in a CSV file.
# COMPATIBILITY: Windows PowerShell, Exchange Online PowerShell
# NOTES:        Ensure that your environment has the necessary permissions to access
#               mailbox rules and that you are authenticated to your Exchange server.
********************************************************************************
#>

# Variable Declaration
$UserEmail = "user@example.com"
$CurrentDate = Get-Date -Format "MMM-dd-yyyy"
$OutputFile =  C:\TEMP\"MailboxRules_$CurrentDate.csv"

# Error Handling
try {
    # Connect to Exchange Online (uncomment and modify the line below as per your setup)
    # Connect-ExchangeOnline -UserPrincipalName admin@yourdomain.com -ShowProgress $true

    # Retrieve mailbox rules for specified user
    $MailboxRules = Get-InboxRule -Mailbox $UserEmail

    # Check if any rules are found
    if($MailboxRules) {
        # Export mailbox rules to CSV file
        $MailboxRules | Select-Object Name, Description, Enabled, Priority, From, SentTo, CopyToFolder, MoveToFolder, DeleteMessage, StopProcessingRules |
        Export-Csv -Path $OutputFile -NoTypeInformation

        Write-Output "Mailbox rules for $UserEmail have been successfully exported to $OutputFile"
    } else {
        Write-Output "No mailbox rules found for $UserEmail."
    }
}
catch {
    Write-Output "An error occurred: $_"
    # Handle exception
}

# Disconnect from Exchange Online (uncomment the line below if using Connect-ExchangeOnline)
# Disconnect-ExchangeOnline -Confirm:$false