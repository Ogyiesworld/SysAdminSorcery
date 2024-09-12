<#
********************************************************************************
# SUMMARY:      Export AD Security and Distribution Groups Information
# AUTHOR:       Joshua Ogden
# DESCRIPTION:  This script exports the name, SamAccountName, creation date, 
#               description, members, and groups in which the group is a member,
#               of all security and distribution groups in Active Directory to a CSV file.
# COMPATIBILITY: Windows PowerShell 5.1, PowerShell Core 7
# NOTES:        Requires Active Directory module. Run with administrator privileges.
********************************************************************************
#>

# Variable Declaration
[string]$OutputFilePath = "C:\Temp\ADGroupsInfo_$(Get-Date -Format 'MMM-d-yyyy').csv"

# Function to resolve group memberships recursively
function Get-GroupMembers {
    param (
        [ADSI]$Group
    )

    $Members = @()
    foreach ($Member in $Group.member) {
        $MemberObject = [ADSI]("LDAP://$Member")
        if ($MemberObject.objectClass -contains 'group') {
            $Members += Get-GroupMembers -Group $MemberObject
        } else {
            $Members += $MemberObject.samAccountName
        }
    }
    return $Members
}

# Function to resolve the groups a given group is a member of
function Get-MembersOf {
    param (
        [string]$GroupDN
    )

    $GroupMemberOf = Get-ADGroup -Identity $GroupDN -Properties MemberOf
    if ($GroupMemberOf.MemberOf) {
        return $GroupMemberOf.MemberOf
    } else {
        return @()
    }
}

# Import Active Directory module
Import-Module ActiveDirectory

# Initialize results array
$Results = @()

# Retrieve all Security and Distribution Groups
$AllGroups = Get-ADGroup -Filter * -Properties whenCreated, Description, member, SamAccountName, MemberOf

foreach ($Group in $AllGroups) {
    # Get group details
    $GroupName = $Group.Name
    $SamAccountName = $Group.SamAccountName
    $CreationDate = $Group.whenCreated
    $Description = $Group.Description
    $GroupADSI = [ADSI]("LDAP://$($Group.DistinguishedName)")

    # Get group members
    $Members = Get-GroupMembers -Group $GroupADSI -join "; "

    # Get groups in which this group is a member
    $MembersOfGroups = Get-MembersOf -GroupDN $Group.DistinguishedName -join "; "
    
    # Append group information to results
    $Results += [PSCustomObject]@{
        Name          = $GroupName
        SamAccountName = $SamAccountName
        CreationDate  = $CreationDate
        Description   = $Description
        Members       = $Members
        MembersOf     = $MembersOfGroups
    }
}

# Export results to CSV
$Results | Export-Csv -Path $OutputFilePath -NoTypeInformation

Write-Output "Export completed: $OutputFilePath"