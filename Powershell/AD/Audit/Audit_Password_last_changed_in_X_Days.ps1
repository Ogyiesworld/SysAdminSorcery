<#
********************************************************************************
# SUMMARY:      List users enabled and changed their password in the last X days.
# AUTHOR:       Joshua Ogden
# DESCRIPTION:  This script retrieves Active Directory users who are enabled and 
#               have changed their password within the last three days, and 
#               exports the data to a CSV file.
# COMPATIBILITY: Windows PowerShell with Active Directory module installed.
# NOTES:        Ensure you have the necessary permissions to query Active Directory.
********************************************************************************
#>

# Variable Declaration
$DaysAgo = (Get-Date).AddDays(-7) # Change the number of days as needed
$CurrentDate = Get-Date -Format "MMMM-d-yyyy" # Get current date for file naming
$csvfilepath = "C:\temp\EnabledUsersPasswordChanged_$CurrentDate.csv" # Define CSV file path

# Import Active Directory module
Import-Module ActiveDirectory

# Fetching the users
try {
    $Users = Get-ADUser -Filter {Enabled -eq $true -and PasswordLastSet -ge $DaysAgo} `
                        -Properties DisplayName, SamAccountName, Enabled, PasswordLastSet

    # Check if any users were found
    if ($Users.Count -eq 0) {
        Write-Host "No users found who changed their password in the last 3 days." -ForegroundColor Yellow
    } else {
        $Users | Select-Object DisplayName, SamAccountName, Enabled, PasswordLastSet | `
                Export-Csv -Path $csvfilepath -NoTypeInformation
        Write-Host "CSV file with users' information has been created: $csvfilepath" -ForegroundColor Green
    }
} catch {
    Write-Host "An error occurred while fetching the users: $($_.Exception.Message)" -ForegroundColor Red
}