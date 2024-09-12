<#
********************************************************************************
# SUMMARY:      Script to add users to Office 365 calendar with specified permissions
# AUTHOR:       Joshua Ogden
# DESCRIPTION:  This script prompts the user for email addresses to add to the 
#               Office 365 calendar and the level of permissions to apply before 
#               actually applying those permissions.
# COMPATIBILITY: Office 365, Exchange Online
# NOTES:        Ensure you have the necessary Exchange Online modules installed
#               and have the required permissions to modify calendar settings.
********************************************************************************
#>

# Variable Declaration
$ModuleName = "ExchangeOnlineManagement"
$ErrorActionPreference = "Stop"

# Check if the required module is installed, if not install it
If (!(Get-Module -Name $ModuleName -ListAvailable)) {
    Install-Module -Name $ModuleName -Force -Scope CurrentUser
}
Import-Module $ModuleName

try {
    # Connect to Exchange Online
    Connect-ExchangeOnline

    # Prompt for the input user
    $UserEmails = Read-Host "Enter the email addresses of the users to add to the calendar (separated by commas)"
    $UserEmails = $UserEmails -split "," | ForEach-Object { $_.Trim() }

    # Output what each permission level means to make the user aware of the options
    Write-Host "Permissions levels:" -ForegroundColor Yellow 
    Write-Host "Owner: Create, read, modify, and delete all items and files, and create subfolders." -ForegroundColor Yellow
    Write-Host "PublishingEditor: Create, read, modify, and delete all items and files." -ForegroundColor Yellow
    Write-Host "Editor: Create, read, modify, and delete all items." -ForegroundColor Yellow
    Write-Host "PublishingAuthor: Create and read items, create subfolders, and modify and delete items and files you create." -ForegroundColor Yellow
    Write-Host "Author: Create and read items, and modify and delete items you create." -ForegroundColor Yellow
    Write-Host "NonEditingAuthor: Create and read items, and delete items you create." -ForegroundColor Yellow
    Write-Host "Reviewer: Read items." -ForegroundColor Yellow
    Write-Host "Custom: Define custom permissions." -ForegroundColor Yellow

    # Ask for calendar permissions
    $PermissionsOptions = @("Owner", "PublishingEditor", "Editor", "PublishingAuthor", "Author", "NonEditingAuthor", "Reviewer", "Custom")
    $Permissions = Read-Host "Enter the permissions level for the users ($($PermissionsOptions -join ', '))"

    # Validate permissions input
    if ($Permissions -notin $PermissionsOptions -and $Permissions -ne 'Custom') {
        throw "Invalid permissions option selected."
    }

    # If 'Custom', prompt for specific permissions
    if ($Permissions -eq 'Custom') {
        $CalendarPermissions = Read-Host "Enter the specific permissions in appropriate format"
    } else {
        $CalendarPermissions = $Permissions
    }

    # Get the calendar owner email
    $CalendarOwner = Read-Host "Enter the email address of the calendar owner"

    # Apply the calendar permissions to each user
    foreach ($UserEmail in $UserEmails) {
        # Applying permissions for the current user
        Add-MailboxFolderPermission -Identity "${CalendarOwner}:\Calendar" -User $UserEmail -AccessRights $CalendarPermissions
    }

    Write-Host "Permissions applied successfully!"
}
catch {
    Write-Error "An error occurred: $_"
}
finally {
    # Disconnect from Exchange Online
    Disconnect-ExchangeOnline -Confirm:$false
}