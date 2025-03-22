<#
********************************************************************************
# SUMMARY:      List users enabled and changed their password in the last X days.
# AUTHOR:       Joshua Ogden
# DESCRIPTION:  This script retrieves Active Directory users who are enabled and 
#               have changed their password within the last X days, and 
#               exports the data to a CSV file.
# COMPATIBILITY: Windows PowerShell with Active Directory module installed.
# NOTES:        Ensure you have the necessary permissions to query Active Directory.
********************************************************************************
#>

# Import Active Directory module
Import-Module ActiveDirectory

# Variable Declaration
$X = Read-Host "Enter the number of days to check password changes for" # Days
$DaysAgo = (Get-Date).AddDays(-$X) # Calculate date threshold
$CurrentDate = Get-Date -Format "MMMM-d-yyyy" # Get current date for file naming
$csvfilepath = "C:\temp\EnabledUsersPasswordChanged_$CurrentDate.csv" # Define CSV file path

# Fetching the users
try {
    $Users = Get-ADUser -Filter {Enabled -eq $true -and PasswordLastSet -ge $DaysAgo} `
                        -Properties GivenName, Surname, SamAccountName, PasswordLastSet

    # Check if any users were found
    if ($Users.Count -eq 0) {
        Write-Host "No users found who changed their password in the last $X days." -ForegroundColor Yellow
    } else {
        $Users | Select-Object GivenName, Surname, SamAccountName, PasswordLastSet | `
                Export-Csv -Path $csvfilepath -NoTypeInformation
        Write-Host "CSV file with users' information has been created: $csvfilepath" -ForegroundColor Green
    }
} catch {
    Write-Host "An error occurred while fetching the users: $($_.Exception.Message)" -ForegroundColor Red
}
Finally {
   Write-Host "Displaying users who changed their password in the last $X days:" -ForegroundColor Cyan
   $Users | Select-Object GivenName, Surname, SamAccountName, PasswordLastSet | 
   Format-Table -AutoSize -Property @{Name="Given Name"; Expression={$_.GivenName}}, 
                                   @{Name="Surname"; Expression={$_.Surname}}, 
                                   @{Name="Password Last Set"; Expression={$_.PasswordLastSet}},
                                   @{Name="SamAccountName"; Expression={$_.SamAccountName}}
}