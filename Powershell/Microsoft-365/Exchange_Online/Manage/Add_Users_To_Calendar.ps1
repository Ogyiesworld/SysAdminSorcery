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

    # What is the domain of the users? This will be used to append to the users email addresses and the calendars getting permission changes
    $UserDomain = Read-Host "Enter the domain of the users (e.g., 'example.com')"
   
    # Prompt for the input user
    $UserEmails = Read-Host "Enter the username of the users to add to the calendar (separated by commas)"
    $UserEmails = $UserEmails -split "," | ForEach-Object { $_.Trim() }
    $UserEmails = $UserEmails | ForEach-Object { "$_@$UserDomain" }

    # Output what each permission level means to make the user aware of the options
    Write-Host "Permissions levels:" -ForegroundColor Cyan 
    Write-Host "Owner: Create, read, modify, and delete all items and files, and create subfolders." -ForegroundColor Green
    Write-Host "PublishingEditor: Create, read, modify, and delete all items and files." -ForegroundColor Green
    Write-Host "Editor: Create, read, modify, and delete all items." -ForegroundColor Green
    Write-Host "PublishingAuthor: Create and read items, create subfolders, and modify and delete items and files you create." -ForegroundColor Green
    Write-Host "Author: Create and read items, and modify and delete items you create." -ForegroundColor Green
    Write-Host "NonEditingAuthor: Create and read items, and delete items you create." -ForegroundColor Green
    Write-Host "Reviewer: Read items." -ForegroundColor Green
    Write-Host "Custom: Define custom permissions." -ForegroundColor Green

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

    # Get multiple calendar owners emails that users will be added to
    $CalendarOwners = Read-Host "Enter the username of the calendar owners (separated by commas)"
    $CalendarOwnersSplit = $CalendarOwners -split "," | ForEach-Object { $_.Trim() }
    $CalendarOwnersSplit = $CalendarOwnersSplit | ForEach-Object { "$_@$UserDomain" }

    # Apply the calendar permissions to each user
    foreach ($CalendarOwner in $CalendarOwnersSplit) {
        foreach ($UserEmail in $UserEmails) {
            # If permissions already exist, change them
            if (Get-MailboxFolderPermission -Identity "${CalendarOwner}:\Calendar" -User $UserEmail) {
                Set-MailboxFolderPermission -Identity "${CalendarOwner}:\Calendar" -User $UserEmail -AccessRights $CalendarPermissions
            }
            # Otherwise, add new permissions
            else {
                Add-MailboxFolderPermission -Identity "${CalendarOwner}:\Calendar" -User $UserEmail -AccessRights $CalendarPermissions
            }
        }
    }

    Write-Host "Permissions applied successfully!" -ForegroundColor Green
}
catch {
    Write-Error "An error occurred: $_" -ForegroundColor Red
}
finally {
    # Disconnect from Exchange Online
    Disconnect-ExchangeOnline -Confirm:$false
}