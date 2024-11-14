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

param (
    [string]$OutputFilePath = "C:\Temp\ADGroupsInfo_$(Get-Date -Format 'MMM-d-yyyy').csv"
)

# Import Active Directory module
Import-Module ActiveDirectory -ErrorAction Stop

# Initialize results array
$Results = @()

# Retrieve all Security and Distribution Groups
$AllGroups = Get-ADGroup -Filter * -Property whenCreated, Description, MemberOf, Members | Select-Object Name, SamAccountName, whenCreated, Description, DistinguishedName, MemberOf

foreach ($Group in $AllGroups) {
    try {
        # Get group details
        $GroupName = $Group.Name
        $SamAccountName = $Group.SamAccountName
        $CreationDate = $Group.whenCreated
        $Description = $Group.Description

        # Get group members
        $Members = Get-ADGroupMember -Identity $Group.DistinguishedName | Select-Object -ExpandProperty SamAccountName -ErrorAction SilentlyContinue -join "; "

        # Get groups in which this group is a member
        $MembersOfGroups = $Group.MemberOf -join "; "
        
        # Append group information to results
        $Results += [PSCustomObject]@{
            Name          = $GroupName
            SamAccountName = $SamAccountName
            CreationDate  = $CreationDate
            Description   = $Description
            Members       = $Members
            MembersOf     = $MembersOfGroups
        }
    } catch {
        Write-Warning "Failed to process group $($Group.Name): $_"
    }
}

# Export results to CSV
$Results | Export-Csv -Path $OutputFilePath -NoTypeInformation

Write-Output "Export completed: $OutputFilePath"
