<#
********************************************************************************
# SUMMARY:      Generate a List of Users without MFA
# AUTHOR:       Joshua Ogden
# DESCRIPTION:  This script fetches users from Azure Active Directory who do 
#               not have Multi-Factor Authentication enabled and exports the 
#               list to a CSV file.
# COMPATIBILITY: MSOnline PowerShell Module
# NOTES:        Ensure that the MSOnline module is installed and you have the
#               necessary permissions to read user details.
********************************************************************************
#>

# Import the MSOnline module
Import-Module MSOnline

# Connect to MSOnline
Connect-MsolService 

# Variable Declaration
$Date = (Get-Date).ToString("MMMM-d-yyyy")
$ExportDirectory = "C:\temp\"
$ExportFilePath = "$ExportDirectory\UsersWithoutMfa_$Date.csv"

# Ensure directory exists
if (-not (Test-Path -Path $ExportDirectory)) {
    New-Item -ItemType Directory -Path $ExportDirectory
}

# Error Handling
try {
    # Fetch all users
    $AllUsers = Get-MsolUser -All

    # Fetch users with MFA disabled
    $UsersWithoutMfa = $AllUsers | Where-Object { $_.StrongAuthenticationMethods.Count -eq 0 }

    # Export the list to CSV
    $UsersWithoutMfa | Select-Object DisplayName, UserPrincipalName, EmailAddress, blockcredential, passwordneverexpires, lastpasswordchangetimestamp | Export-Csv -Path $ExportFilePath -NoTypeInformation

    Write-Output "Export Successful. File saved to $ExportFilePath."
} catch {
    Write-Error "An error occurred: $_"
}