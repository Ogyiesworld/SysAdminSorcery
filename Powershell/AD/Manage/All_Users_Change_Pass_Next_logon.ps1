<#
********************************************************************************
# SUMMARY:      Update Password Change Requirement for Users
# AUTHOR:       Joshua Ogden
# DESCRIPTION:  This script updates the "Password change on next logon" flag for 
#               all users who haven't changed their password in the last 7 days, 
#               except for those in an exception group, including both service accounts 
#               and a predefined list of users.
# COMPATIBILITY: Windows Server 2012 and above
# NOTES:        Make sure the Active Directory module is installed and imported.
********************************************************************************
#>

# Variable Declaration
$ExceptionGroup = "CN=ExceptionGroup,OU=Groups,DC=domain,DC=com,"
$CurrentDate = Get-Date
$DaysThreshold = 7
$DateThreshold = $CurrentDate.AddDays(-$DaysThreshold)

# Import the Active Directory module
Import-Module ActiveDirectory

# Function to check if a user is in the exception group
function Get-UserInExceptionGroup {
    param (
        [Parameter(Mandatory = $true)]
        [string]$UserDN
    )

    $isInExceptionGroup = Get-ADUser -Filter {MemberOf -RecursiveMatch $ExceptionGroup -and DistinguishedName -eq $UserDN}
    return $null -ne $isInExceptionGroup
}

# Retrieve all users who have not changed their password in the last 7 days
$Users = Get-ADUser -Filter {PasswordLastSet -lt $DateThreshold} -Properties PasswordLastSet

foreach ($User in $Users) {
    if (-not (Get-UserInExceptionGroup -UserDN $User.DistinguishedName)) {
        try {
            $User | Set-ADUser -ChangePasswordAtLogon $true
            Write-Output "Updated 'ChangePasswordAtLogon' for user: $($User.SamAccountName)"
        } catch {
            Write-Error "Failed to update 'ChangePasswordAtLogon' for user: $($User.SamAccountName). Error: $_"
        }
    } else {
        Write-Output "Skipped user: $($User.SamAccountName) as they are in the exception group."
    }
}