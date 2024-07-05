<#
********************************************************************************
# SUMMARY:      Find and Export Users with UPN and SAM Account Name Mismatch
# AUTHOR:       Joshua Ogden
# DESCRIPTION:  This script retrieves all Active Directory users and identifies 
#               those where the User Principal Name (UPN) does not match the 
#               SAM account name, then exports the results to a CSV file.
# COMPATIBILITY: Windows PowerShell 5.1, PowerShell 7
# NOTES:        Ensure you have the Active Directory module installed and 
#               necessary permissions to query AD.
********************************************************************************
#>

# Import the Active Directory module
Import-Module ActiveDirectory

try {
    # Get all users from Active Directory
    $Users = Get-ADUser -Filter * -Properties UserPrincipalName

    # Initialize an array to hold the users where UPN and SAM do not match
    $UsersWithMismatch = @()

    # Loop through each user's UPN and SAM account name
    foreach ($User in $Users) {
        if ($null -ne $User.UserPrincipalName) {
            $Upn = $User.UserPrincipalName.Split("@")[0]  # Extract the username part of the UPN
            $Sam = $User.SamAccountName

            # Check if UPN and SAM do not match
            if ($Upn -ne $Sam) {
                $UsersWithMismatch += $User
            }
        }
    }

    # Output the list of users where UPN and SAM do not match
    $UsersWithMismatch | Select-Object Name, UserPrincipalName, SamAccountName | Format-Table

    # Export the results to a CSV file
    $CsvPath = "C:\Temp\UsersWithMismatch_SAM_UPN.csv"
    $UsersWithMismatch | Select-Object Name, UserPrincipalName, SamAccountName | Export-Csv -Path $CsvPath -NoTypeInformation
    Write-Host "Users with UPN and SAM account name mismatch exported to $CsvPath" -ForegroundColor Green
}
catch {
    Write-Error "An error occurred: $_"
}
