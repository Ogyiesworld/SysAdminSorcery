<#
********************************************************************************
# SUMMARY:      Check Active Directory User Status
# AUTHOR:       Joshua Ogden
# DESCRIPTION:  This script checks if a specified user exists in Active Directory,
#               and if so, retrieves and displays their status, OU, and password expiry.
# COMPATIBILITY: Windows PowerShell 5.1, PowerShell 7
# NOTES:        Ensure you have the Active Directory module installed and 
#               necessary permissions to query AD.
********************************************************************************
#>

# Import the Active Directory module
Import-Module ActiveDirectory

# Prompt the user to enter the username
$Username = Read-Host "Enter the username"

try {
    # Check if the user exists in Active Directory
    $User = Get-ADUser -Filter {SamAccountName -eq $Username} -Properties Enabled, CanonicalName, PasswordExpired -ErrorAction Stop

    # Check if the user is disabled
    if ($User.Enabled -eq $false) {
        Write-Host "User '$Username' is disabled"
    }
    else {
        Write-Host "User '$Username' is enabled"
    }

    # Get the OUs the user is in
    $OU = $User.CanonicalName
    Write-Host "User '$Username' is in the following OU: $OU"

    # Check if the user's password is expired
    if ($User.PasswordExpired -eq $true) {
        Write-Host "User '$Username' has an expired password"
    }
    else {
        Write-Host "User '$Username' does not have an expired password"
    }
}
catch [Microsoft.ActiveDirectory.Management.ADIdentityNotFoundException] {
    Write-Host "User '$Username' not found"
}
catch {
    Write-Error "An unexpected error occurred: $_"
}
