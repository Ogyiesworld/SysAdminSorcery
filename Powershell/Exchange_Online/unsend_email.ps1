# Install the Exchange Online Management Module if not already installed
# Check if the ExchangeOnlineManagement module is available
if (-not (Get-Module -ListAvailable -Name ExchangeOnlineManagement)) {
    Write-Host "Installing Exchange Online Management Module..." -ForegroundColor Cyan
    Install-Module -Name ExchangeOnlineManagement -Force -AllowClobber
} else {
    Write-Host "Exchange Online Management Module is already installed." -ForegroundColor Green
}

# Connect to Exchange Online PowerShell with a user account
$UserPrincipalName = Read-Host -Prompt "Enter your User Principal Name (e.g., user@domain.com)"
Connect-ExchangeOnline -UserPrincipalName $UserPrincipalName

# Interactive inputs for creating a compliance search
$SearchName = Read-Host -Prompt "Enter a unique name for the compliance search"
$Mailbox = Read-Host -Prompt "Enter the target mailbox email address (e.g., target@domain.com)"
$SentDates = Read-Host -Prompt "Enter the sent dates range (e.g., YYYY/MM/DD..YYYY/MM/DD)"
$Subject = Read-Host -Prompt "Enter the exact subject line of the email"

$SearchQuery = "Received:$SentDates AND Subject:`"$Subject`""
New-ComplianceSearch -Name $SearchName -ExchangeLocation $Mailbox -ContentMatchQuery $SearchQuery

# Start the compliance search
Start-ComplianceSearch -Identity $SearchName
Write-Host "Compliance search started. Please wait for it to complete." -ForegroundColor Yellow

# Pause to let the user check the search results manually
Read-Host -Prompt "Press Enter to continue after you have checked the compliance search results and are ready to proceed"

# Confirm before deleting emails
$confirmation = Read-Host -Prompt "Are you sure you want to delete the emails found by the search? (Y/N)"
if ($confirmation -eq "Y" -or $confirmation -eq "y") {
    New-ComplianceSearchAction -SearchName $SearchName -Purge -PurgeType HardDelete
    Write-Host "Deletion initiated for emails found in the search. Checking progress..." -ForegroundColor Yellow
    
    # Check the progress of the delete action
    Get-ComplianceSearchAction -Identity "$SearchName_Purge" | Format-List
} else {
    Write-Host "Deletion cancelled by user." -ForegroundColor Red
}

# Disconnect the session
Disconnect-ExchangeOnline -Confirm:$false
Write-Host "Disconnected from Exchange Online." -ForegroundColor Green
