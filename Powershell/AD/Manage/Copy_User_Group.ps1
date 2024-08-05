<#
********************************************************************************
# SUMMARY:      PowerShell Script to Synchronize Group Memberships Between Two AD Users
# AUTHOR:       Joshua Ogden
# DESCRIPTION:  This script compares and synchronizes the Active Directory (AD) group memberships 
#               of two users, ensuring both have identical access rights within an organization's IT infrastructure.
#               It's designed to streamline user permission management and maintain consistent access rights.
# COMPATIBILITY: Windows Server with Active Directory. PowerShell 5.1 or higher.
# NOTES:        Version 1.1. Last Updated: [04/03/2024]. Requires the Active Directory module for Windows PowerShell.
#               Example Usage: .\SyncADUserGroupMemberships.ps1 -SourceUser 'jdoe' -TargetUser 'jsmith'.
#               Deploy with caution to prevent unintended access rights assignments. Remember, with great power comes great responsibility!
********************************************************************************
#>

# Variable Declaration
$SourceUser = $null
$TargetUser = $null
$SourceGroups = $null
$TargetGroups = $null
$Response = $null
$GroupName = $null

# Initiate the script by prompting for source and target usernames. Think of them as the "copier" and the "paste" in this permission cloning adventure.
$SourceUser = Read-Host "Enter the username of the source user"
$TargetUser = Read-Host "Enter the username of the target user"

try {
    # Retrieve group memberships of both the source and target users. This is the heart of our cloning machine.
    $SourceGroups = Get-ADUser -Identity $SourceUser -Properties MemberOf | Select-Object -ExpandProperty MemberOf
    $TargetGroups = Get-ADUser -Identity $TargetUser -Properties MemberOf | Select-Object -ExpandProperty MemberOf

    # Display the group membership information, because visual confirmation is always reassuring.
    Write-Host "Group memberships for $SourceUser"
    $SourceGroups | ForEach-Object {
        $GroupName = (Get-ADGroup -Identity $_).Name
        Write-Host $GroupName
    }

    Write-Host "Group memberships for $TargetUser"
    $TargetGroups | ForEach-Object {
        $GroupName = (Get-ADGroup -Identity $_).Name
        Write-Host $GroupName
    }

    # Ask for confirmation before proceeding. It's like asking "Are you sure?" before pressing the big red button.
    $Response = Read-Host "Do you want to synchronize the groups from $SourceUser to $TargetUser ? (Y/N)"
    if ($Response -eq 'Y') {
        # Add the target user to any groups the source user is a member of, but the target user is not. Like making two peas in a pod.
        $SourceGroups | ForEach-Object {
            try {
                if ($TargetGroups -notcontains $_) {
                    Add-ADGroupMember -Identity $_ -Members $TargetUser -ErrorAction Stop
                    Write-Host "User $TargetUser successfully added to group $_"
                }
            } catch {
                Write-Host "Failed to add $TargetUser to group $_. Error: $_"
            }
        }
        Write-Host "Operation completed successfully. The Force is strong with this one."
    }
    elseif ($Response -eq 'N') {
        Write-Host "Operation cancelled by user. Better safe than sorry!"
    }
    else {
        Write-Host "Invalid response. Operation aborted. Remember, it's Y or N, not rocket science!"
    }
} catch {
    # Graceful error handling, because sometimes things don't go as planned.
    Write-Host "An unexpected disturbance in the Force was encountered: $($_.Exception.Message)"
}