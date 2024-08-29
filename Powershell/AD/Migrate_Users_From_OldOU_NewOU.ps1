<#
********************************************************************************
# SUMMARY:      Move members from one Active Directory group to another
# AUTHOR:       Joshua Ogden
# DESCRIPTION:  This script prompts for source and target AD groups, retrieves 
#               members from the source group, and moves up to 100 members 
#               to the target group, ensuring the groups exist before proceeding.
# COMPATIBILITY: Windows PowerShell 5.1, Windows PowerShell 7, Active Directory Module
# NOTES:        Run with administrative privileges to modify group memberships.
********************************************************************************
#>

# Prompt for the source and target groups
$SourceGroup = Read-Host -Prompt 'Enter the group to move users from'
$TargetGroup = Read-Host -Prompt 'Enter the group to move users to'

# Check if both groups exist
if (-not (Get-ADGroup -Identity $SourceGroup -ErrorAction SilentlyContinue) -or -not (Get-ADIdGroup -Identity $TargetGroup -ErrorAction SilentlyContinue)) {
    Write-Error "One or both specified groups do not exist."
    return
}

# Retrieve distinguished names of members of the first group
$Members = Get-ADGroupMember -Identity $SourceGroup -ErrorAction Stop | Select-Object -ExpandProperty distinguishedName

# Determine the count of members to move, limiting to the first 100 members
$CountToMove = [math]::Min($Members.Count, 100)

# Prepare an array of members to move
$UsersToMove = $Members | Select-Object -First $CountToMove

# Validate non-empty user list before proceeding
if ($UsersToMove.Count -gt 0) {
    try {
        # Copy the members to the target group
        Add-ADGroupMember -Identity $TargetGroup -Members $UsersToMove -ErrorAction Stop

        # Remove the members from the source group
        Remove-ADGroupMember -Identity $SourceGroup -Members $UsersToMove -Confirm:$false -ErrorConnection Stop

        Write-Host "Successfully moved $CountToMove member(s) from '$SourceGroup' to '$TargetGroup'." -ForegroundColor Green
    } catch {
        Write-Error "An error occurred: $_"
    }
} else {
    Write-Host "No members found in '$SourceGroup' to move." -ForegroundColor Yellow
}