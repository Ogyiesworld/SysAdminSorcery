<#
********************************************************************************
# SUMMARY:      Script to remove employee signatures for Exchange Online
# AUTHOR:       Joshua Ogden
# DESCRIPTION:  This script removes the email signatures for all users in Exchange Online
#               by setting their signature to a blank value.
# COMPATIBILITY: Exchange Online
# NOTES:        Ensure you have the necessary permissions to modify user attributes 
#               in Exchange Online.
********************************************************************************
#>

# Import necessary module
Import-Module ExchangeOnlineManagement

# Function to clear user signature in Exchange Online
Function Clear-UserSignature {
    Param (
        [string]$UserPrincipalName
    )
    Try {
        $Signature = ""
        Set-MailboxMessageConfiguration -Identity $UserPrincipalName -SignatureHtml $Signature
        Write-Output "Signature cleared for $UserPrincipalName"
    } Catch {
        Write-Error "Failed to clear signature: $_"
    }
}

# Connect to Exchange Online
Try {
    Connect-ExchangeOnline -UserPrincipalName "admin@yourdomain.com"
} Catch {
    Write-Error "Failed to connect to Exchange Online: $_"
    Exit
}

# Main script
$Users = Get-Mailbox -ResultSize Unlimited
ForEach ($User in $Users) {
    $UserPrincipalName = $User.UserPrincipalName
    Clear-UserSignature -UserPrincipalName $UserPrincipalName
}

# Disconnect from services
Disconnect-ExchangeOnline

