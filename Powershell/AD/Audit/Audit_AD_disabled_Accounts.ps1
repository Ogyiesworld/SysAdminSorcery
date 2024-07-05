<#
********************************************************************************
# SUMMARY:      Audit Accounts considered deprecated in Active Directory
# AUTHOR:       Joshua Ogden
# DESCRIPTION:  This script scans for deprecated accounts in Active 
#               Directory, retrieves their details, and provides an option to 
#               remove them.
# COMPATIBILITY: Windows PowerShell 5.1, Windows PowerShell 7, Active Directory Module
# NOTES:        Ensure you have the necessary permissions to run AD commands.
********************************************************************************
#>

# Import the Active Directory module
Import-Module ActiveDirectory

# Define the threshold date for determining deprecated accounts (e.g., accounts not logged in for over a year)
$ThresholdDate = (Get-Date).AddYears(-1)

# Initialize an array to hold account details
$AccountDetails = @()

# Retrieve all disabled accounts that haven't logged in since the threshold date
$DeprecatedAccounts = Get-ADUser -Filter {
    Enabled -eq $false -and LastLogonDate -lt $ThresholdDate
} -Properties SamAccountName, Name, Enabled, Description, MemberOf, LastLogonDate

# Loop through each deprecated account and collect details
foreach ($User in $DeprecatedAccounts) {
    try {
        $AccountDetails += [pscustomobject]@{
            Username    = $User.SamAccountName
            Name        = $User.Name
            Email       = $User.EmailAddress
            Enabled     = $User.Enabled
            Description = $User.Description
            LastLogon   = $User.LastLogonDate
            MemberOf    = ($User.MemberOf | ForEach-Object { (Get-ADGroup $_).Name }) -join ", "
        }
    }
    catch {
        Write-Host "Error occurred while processing account $($User.SamAccountName): $_"
    }
}

# Display the account details
$AccountDetails | Format-Table -AutoSize

# Export the account details to a CSV file
$CsvFilePath = "C:\temp\DeprecatedAccounts_$(Get-Date -Format 'MMMM-d-yyyy').csv"
$AccountDetails | Export-Csv -Path $CsvFilePath -NoTypeInformation

Write-Host "Account details have been exported to $CsvFilePath"

