<#
********************************************************************************
# SUMMARY:      Audit Active Directory user information to CSV
# AUTHOR:       Joshua Ogden
# DESCRIPTION:  This script checks for the presence of the Active Directory module, 
#               retrieves all user accounts and specified properties, and exports 
#               the user details to a CSV file.
# COMPATIBILITY: Windows PowerShell 5.1, Windows PowerShell 7, Active Directory Module
# NOTES:        Ensure you have necessary permissions to run Active Directory commands.
#               Run this script as an administrator if required.
********************************************************************************
#>

# Ensure the Active Directory module is loaded
if (-not (Get-Module -ListAvailable -Name ActiveDirectory)) {
    Import-Module ActiveDirectory
}

# Initialize a list to hold user data
$UserData = New-Object System.Collections.Generic.List[object]

# Retrieve all user accounts in Active Directory with specific properties
$Users = Get-ADUser -Filter * -Properties PasswordLastSet, PasswordNeverExpires, LastLogonDate

# Loop through each user account
foreach ($User in $Users) {
    try {
        # Add user information to the list
        $UserData.Add([pscustomobject]@{
            Username               = $User.SamAccountName
            Email                  = $User.UserPrincipalName
            PasswordLastSet        = $User.PasswordLastSet
            PasswordNeverExpires   = $User.PasswordNeverExpiration
            LastAuthenticationTime = $User.LastLogonDate
        })
    } catch {
        Write-Host "Error occurred while processing user $($User.SamAccountName): $($_.Exception.Message)"
    }
}

# File Path
$CsvFilePath = "C:\temp\adusersinfo_$(Get-Date -Format 'MMMM-d-yyyy').csv"

# Export the user data to a CSV file
$UserData | Export-Csv -Path $CsvFilePath -NoTypeInformation

Write-Host "User information has been exported to $CsvFilePath"