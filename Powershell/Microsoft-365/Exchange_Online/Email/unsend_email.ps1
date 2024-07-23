<#
********************************************************************************
# SUMMARY:      Manage Compliance Search and Purge in Exchange Online
# AUTHOR:       Joshua Ogden
# DESCRIPTION:  This script installs the Exchange Online Management Module if 
#               not already installed, connects to Exchange Online, creates and 
#               starts a compliance search, and optionally deletes emails based 
#               on the search results.
# COMPATIBILITY: Windows PowerShell 5.1, PowerShell 7
# NOTES:        Ensure you have the necessary permissions to connect to 
#               Exchange Online and perform compliance searches and purges.
********************************************************************************
#>

# Function to install the Exchange Online Management Module
function Install-ExchangeOnlineManagementModule {
    if (-not (Get-Module -ListAvailable -Name ExchangeOnlineManagement)) {
        Write-Host "Installing Exchange Online Management Module..." -ForegroundColor Cyan
        Install-Module -Name ExchangeOnlineManagement -Force -AllowClobber
    } else {
        Write-Host "Exchange Online Management Module is already installed." -ForegroundColor Green
    }
}

# Function to connect to Exchange Online
function Connect-ToExchangeOnline {
    param (
        [string]$UserPrincipalName
    )
    Connect-ExchangeOnline -UserPrincipalName $UserPrincipalName
}

# Function to create and start a compliance search
function Start-ComplianceSearch {
    param (
        [string]$SearchName,
        [string]$Mailbox,
        [string]$SentDates,
        [string]$Subject
    )
    $SearchQuery = "Received:$SentDates AND Subject:`"$Subject`""
    New-ComplianceSearch -Name $SearchName -ExchangeLocation $Mailbox -ContentMatchQuery $SearchQuery
    Start-ComplianceSearch -Identity $SearchName
    Write-Host "Compliance search started. Please wait for it to complete." -ForegroundColor Yellow
}

# Function to check and confirm deletion of emails
function Confirm-AndDeleteEmails {
    param (
        [string]$SearchName
    )
    $Confirmation = Read-Host -Prompt "Are you sure you want to delete the emails found by the search? (Y/N)"
    if ($Confirmation -eq "Y" -or $Confirmation -eq "y") {
        New-ComplianceSearchAction -SearchName $SearchName -Purge -PurgeType HardDelete
        Write-Host "Deletion initiated for emails found in the search. Checking progress..." -ForegroundColor Yellow
        Get-ComplianceSearchAction -Identity "$SearchName_Purge" | Format-List
    } else {
        Write-Host "Deletion cancelled by user." -ForegroundColor Red
    }
}

# Function to disconnect from Exchange Online
function Disconnect-FromExchangeOnline {
    Disconnect-ExchangeOnline -Confirm:$false
    Write-Host "Disconnected from Exchange Online." -ForegroundColor Green
}

# Main script execution

# Install the Exchange Online Management Module if not already installed
Install-ExchangeOnlineManagementModule

# Connect to Exchange Online PowerShell with a user account
$UserPrincipalName = Read-Host -Prompt "Enter your User Principal Name (e.g., user@domain.com)"
Connect-ToExchangeOnline -UserPrincipalName $UserPrincipalName

# Interactive inputs for creating a compliance search
$SearchName = Read-Host -Prompt "Enter a unique name for the compliance search"
$Mailbox = Read-Host -Prompt "Enter the target mailbox email address (e.g., target@domain.com)"
$SentDates = Read-Host -Prompt "Enter the sent dates range (e.g., YYYY/MM/DD..YYYY/MM/DD)"
$Subject = Read-Host -Prompt "Enter the exact subject line of the email"

# Create and start the compliance search
Start-ComplianceSearch -SearchName $SearchName -Mailbox $Mailbox -SentDates $SentDates -Subject $Subject

# Pause to let the user check the search results manually
Read-Host -Prompt "Press Enter to continue after you have checked the compliance search results and are ready to proceed"

# Confirm before deleting emails
Confirm-AndDeleteEmails -SearchName $SearchName

# Disconnect the session
Disconnect-FromExchangeOnline
