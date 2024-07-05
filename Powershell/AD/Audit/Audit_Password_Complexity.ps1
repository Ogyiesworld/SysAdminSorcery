<#
********************************************************************************
# SUMMARY:      Export Active Directory user information to CSV
# AUTHOR:       Joshua Ogden
# DESCRIPTION:  This script imports the Active Directory module, retrieves all 
#               user accounts along with their password and logon information,
#               and exports the user details to a CSV file.
# COMPATIBILITY: Windows PowerShell 5.1, Windows PowerShell 7, Active Directory Module
# NOTES:        Ensure you have the necessary permissions to run AD commands.
********************************************************************************
#>

# Import the Active Directory module
Import-Module ActiveDirectory

# Initialize an array to hold user data
$UserData = @()

# Retrieve all user accounts in Active Directory with specific properties
$Users = Get-ADUser -Filter * -Properties PasswordLastSet, PasswordNeverExpires, LastLogonDate

# Loop through each user account
foreach ($User in $Users) {
    try {
        # Check if the password never expires
        $PasswordNeverExpires = $User.PasswordNeverExpires

        # Get the last authentication time
        $LastAuthTime = $User.LastLogonDate

        # Add user information to the array
        $UserData += [pscustomobject]@{
            Username               = $User.SamAccountName
            Emailaddress           = $User.EmailAddress
            PasswordNeverExpires   = $PasswordNeverExpires
            LastAuthenticationTime = $LastAuthTime
        }
    }
    catch {
        Write-Host "Error occurred while processing user $($User.SamAccountName): $_"
    }
}

# File Path
$CsvFilePath = "C:\temp\ADUserInformation_$(Get-Date -Format 'MMMM-d-yyyy').csv"

# Export the user data to a CSV file
$UserData | Export-Csv -Path $CsvFilePath -NoTypeInformation

Write-Host "User information has been exported to $CsvFilePath"
