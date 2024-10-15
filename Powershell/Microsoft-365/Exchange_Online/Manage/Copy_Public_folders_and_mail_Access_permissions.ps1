<#
********************************************************************************
# SUMMARY:      Copy user's public folders and mailbox permissions from one user to another in Exchange Online
# AUTHOR:       Joshua Ogden
# DESCRIPTION:  This script copies public folder access and mailbox permissions from a source user to a target user across all relevant folders in Exchange Online.
# COMPATIBILITY: Exchange Online, PowerShell
# NOTES:        Ensure you have the proper permissions to access Exchange Online and Azure AD.
********************************************************************************
#>

# Variable Declaration
$SourceUser = Read-Host "Enter the source user's email address"
$TargetUser = Read-Host "Enter the target user's email address"
$ExportFolderPath = "C:\exports\"
$Date = Get-Date -Format "MMMM-d-yyyy"

# Connect to Exchange Online securely using OAuth 2.0
Write-Output "Connecting to Exchange Online..."
Connect-ExchangeOnline

# Function to log messages
Function Write-Message {
    Param (
        [string]$Message
    )
    $Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $LogMessage = "$Timestamp - $Message"
    $LogFile = $ExportFolderPath + "PermissionTransferLog_" + $Date + ".txt"
    Write-Output $LogMessage
    $LogMessage | Out-File -FilePath $LogFile -Append
}

# Function to copy mailbox permissions
Function Copy-MailboxPermissions {
    Param (
        [string]$Source,
        [string]$Target
    )
    
    Write-Message "Copying mailbox permissions from $Source to $Target..."
    Get-MailboxPermission -Identity $Source | Where-Object { ($null -ne $_.User) -and ($_.User.ToString() -ne "NT AUTHORITY\SELF") } | ForEach-Object {
        Try {
            Add-MailboxPermission -Identity $Target -User $_.User -AccessRights $_.AccessRights -InheritanceType $_.InheritanceType -AutoMapping $_.AutoMapping
            Write-Message "Permission copied: User $_.User, Rights $_.AccessRights"
        }
        Catch {
            Write-Message "Error copying permission for $_.User: $_"
        }
    }
}

# Function to copy public folder permissions
Function Copy-PublicFolderPermissions {
    Param (
        [string]$Source,
        [string]$Target
    )
    
    Write-Message "Copying public folder permissions from $Source to $Target..."
    $Folders = Get-PublicFolder -Recurse
    foreach ($Folder in $Folders) {
        $Permissions = Get-PublicFolderClientPermission -Identity $Folder.Identity | Where-Object { $_.User -eq $Source }
        foreach ($Permission in $Permissions) {
            Try {
                Add-PublicFolderClientPermission -Identity $Folder.Identity -User $Target -AccessRights $Permission.AccessRights -IsInherited $Permission.IsInherited
                Write-Message "Permission for folder $($Folder.Identity) copied: User $Permission.User, Rights $Permission.AccessRights"
            }
            Catch {
                Write-Message "Error copying permission for folder $($Folder.Identity): $_"
            }
        }
    }
}

# Begin operations
Try {
    Copy-MailboxPermissions -Source $SourceUser -Target $TargetUser
    Copy-PublicFolderPermissions -Source $SourceUser -Target $TargetUser

    Write-Message "Permissions have been successfully copied."
}
Catch {
    Write-Message "An unexpected error occurred during the operation: $_"
}
Finally {
    # Disconnect from Exchange Online
    Disconnect-ExchangeOnline -Confirm:$false
    Write-Message "Disconnected from Exchange Online."
}

Write-Message "Script execution completed."