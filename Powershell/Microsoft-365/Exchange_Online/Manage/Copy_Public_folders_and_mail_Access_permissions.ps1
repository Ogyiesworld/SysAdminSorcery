<#
********************************************************************************
# SUMMARY:      Copy Office 365 group memberships, distribution list memberships, and public folder permissions from one user to another
# AUTHOR:       Joshua Ogden
# DESCRIPTION:  This script copies Office 365 group memberships, distribution list memberships, and public folder permissions from a source user to a target user in Exchange Online.
# COMPATIBILITY: Exchange Online, Microsoft Graph PowerShell, PowerShell
# NOTES:        Ensure you have the proper permissions to access Exchange Online and Microsoft Graph API.
********************************************************************************
#>

# Variable Declaration
$SourceUser = Read-Host "Enter the source user's email address"
$TargetUser = Read-Host "Enter the target user's email address"
$ExportFolderPath = "C:\temp\"
$Date = Get-Date -Format "MMMM-d-yyyy"

# Connect to Exchange Online securely using OAuth 2.0
Write-Output "Connecting to Exchange Online..."
Connect-ExchangeOnline

# Connect to Microsoft Graph
Write-Output "Connecting to Microsoft Graph..."
Connect-MgGraph -Scopes "Group.ReadWrite.All"

# Function to log messages
Function Write-Message {
    Param (
        [string]$Message
    )
    $Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $LogMessage = "$Timestamp - $Message"
    $LogFile = $ExportFolderPath + "PermissionTransferLog_" + $Date + ".txt"

    # Ensure the directory exists
    if (-not (Test-Path -Path $ExportFolderPath)) {
        New-Item -ItemType Directory -Path $ExportFolderPath -Force
    }

    Write-Output $LogMessage
    $LogMessage | Out-File -FilePath $LogFile -Append
}

# Function to list and confirm Office 365 group memberships
Function Get-GroupMemberships {
    Param (
        [string]$Source
    )

    Write-Message "Listing Office 365 group memberships for $Source..."
    
    $SourceUserId = (Get-MgUser -UserId $Source).Id
    $Groups = Get-MgUserMemberOf -UserId $SourceUserId | Where-Object { $_.ODataType -eq '#microsoft.graph.group' }
    
    if ($Groups) {
        Write-Host "Groups found for $Source"
        $Groups | ForEach-Object { Write-Host "- $($_.DisplayName)" }
        $Continue = Read-Host "Continue with copying these group memberships? (Y/N)"
        if ($Continue -eq "N") {
            throw "Operation aborted by user."
        }
    } else {
        Write-Host "No groups found for $Source."
    }
    return $Groups
}

# Function to list and confirm distribution list memberships
Function Get-DistributionLists {
    Param (
        [string]$Source
    )

    Write-Message "Listing distribution list memberships for $Source..."
    
    $DistributionLists = Get-DistributionGroup | Where-Object { (Get-DistributionGroupMember -Identity $_.Identity).PrimarySmtpAddress -contains $Source }
    
    if ($DistributionLists) {
        Write-Host "Distribution lists found for $Source"
        $DistributionLists | ForEach-Object { Write-Host "- $($_.DisplayName)" }
        $Continue = Read-Host "Continue with copying these distribution list memberships? (Y/N)"
        if ($Continue -eq "N") {
            throw "Operation aborted by user."
        }
    } else {
        Write-Host "No distribution lists found for $Source."
    }
    return $DistributionLists
}

# Function to list and confirm public folder permissions
Function Get-PublicFolderPermissions {
    Param (
        [string]$Source
    )

    Write-Message "Listing public folder permissions for $Source..."
    $Folders = Get-PublicFolder -Recurse
    $Permissions = @()
    foreach ($Folder in $Folders) {
        $FolderPermissions = Get-PublicFolderClientPermission -Identity $Folder.Identity | Where-Object { $_.User -eq $Source }
        if ($FolderPermissions) {
            $Permissions += $FolderPermissions | ForEach-Object { 
                [PSCustomObject]@{
                    Folder = $Folder.Identity
                    User = $_.User
                    Rights = $_.AccessRights
                }
            }
        }
    }

    if ($Permissions) {
        Write-Host "Public folder permissions found for $Source"
        $Permissions | ForEach-Object { Write-Host "- Folder: $($_.Folder), Rights: $($_.Rights)" }
        $Continue = Read-Host "Continue with copying these public folder permissions? (Y/N)"
        if ($Continue -eq "N") {
            throw "Operation aborted by user."
        }
    } else {
        Write-Host "No public folder permissions found for $Source."
    }
    return $Permissions
}

# Function to copy Office 365 group memberships
Function Copy-GroupMemberships {
    Param (
        [array]$Groups,
        [string]$Target
    )

    Write-Message "Copying Office 365 group memberships to $Target..."
    $TargetUserId = (Get-MgUser -UserId $Target).Id

    foreach ($Group in $Groups) {
        Try {
            New-MgGroupMember -GroupId $Group.Id -DirectoryObjectId $TargetUserId
            Write-Message "Added $Target to group $($Group.DisplayName)."
        }
        Catch {
            Write-Message "Error adding $Target to group $($Group.DisplayName): $_"
        }
    }
}

# Function to copy distribution list memberships
Function Copy-DistributionLists {
    Param (
        [array]$DistributionLists,
        [string]$Target
    )

    Write-Message "Copying distribution list memberships to $Target..."
    
    foreach ($DL in $DistributionLists) {
        Try {
            Add-DistributionGroupMember -Identity $DL.Identity -Member $Target
            Write-Message "Added $Target to distribution list $($DL.DisplayName)."
        }
        Catch {
            Write-Message "Error adding $Target to distribution list $($DL.DisplayName): $_"
        }
    }
}

# Function to copy public folder permissions
Function Copy-PublicFolderPermissions {
    Param (
        [array]$Permissions,
        [string]$Target
    )

    Write-Message "Copying public folder permissions to $Target..."
    $Jobs = @()
    foreach ($Permission in $Permissions) {
        $Jobs += Start-Job -ScriptBlock {
            Param ($Folder, $Target, $Permission)
            Try {
                Add-PublicFolderClientPermission -Identity $Folder -User $Target -AccessRights $Permission.Rights -IsInherited $Permission.IsInherited
                Write-Message "Permission for folder $($Folder) copied: User $($Permission.User), Rights $($Permission.Rights)"
            }
            Catch {
                Write-Message "Error copying permission for folder $($Folder): $_"
            }
        } -ArgumentList $Permission.Folder, $Target, $Permission
    }
    $Jobs | Wait-Job | ForEach-Object { Receive-Job -Job $_; Remove-Job -Job $_ }
}

# Begin operations
Try {
    $Groups = Get-GroupMemberships -Source $SourceUser
    $DistributionLists = Get-DistributionLists -Source $SourceUser
    $Permissions = Get-PublicFolderPermissions -Source $SourceUser

    Copy-GroupMemberships -Groups $Groups -Target $TargetUser
    Copy-DistributionLists -DistributionLists $DistributionLists -Target $TargetUser
    Copy-PublicFolderPermissions -Permissions $Permissions -Target $TargetUser

    Write-Message "All permissions and memberships have been successfully copied."
}
Catch {
    Write-Message "An unexpected error occurred during the operation: $_"
    Write-Host "Script terminated: $_"
}
Finally {
    # Disconnect from Exchange Online
    Disconnect-ExchangeOnline -Confirm:$false
    Write-Message "Disconnected from Exchange Online."
}

Write-Message "Script execution completed."