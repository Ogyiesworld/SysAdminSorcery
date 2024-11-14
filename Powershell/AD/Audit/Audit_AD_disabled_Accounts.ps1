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

param (
    [datetime]$ThresholdDate = (Get-Date).AddYears(-1)
)

# Import the Active Directory module
Import-Module ActiveDirectory

# Initialize an array to hold account details
$AccountDetails = @()

# Retrieve all disabled accounts that haven't logged in since the threshold date
try {
    $DeprecatedAccounts = Get-ADUser -Filter {
        Enabled -eq $false -and LastLogonDate -lt $ThresholdDate
    } -Properties SamAccountName, Name, Enabled, Description, MemberOf, LastLogonDate -ErrorAction Stop
} catch {
    Write-Host "Failed to retrieve accounts: $($_.Exception.Message)" -ForegroundColor Red
    exit
}

# Loop through each deprecated account and collect details
foreach ($User in $DeprecatedAccounts) {
    try {
        $AccountDetails += [pscustomobject]@{
            Username    = $User.SamAccountName
            Name        = $User.Name
            Email       = $User.UserPrincipalName
            Enabled     = $User.Enabled
            Description = $User.Description
            LastLogon   = $User.LastLogonDate
            MemberOf    = ($User.MemberOf | ForEach-Object { (Get-ADGroup $_).Name }) -join ", "
        }
        Write-Verbose "Processed account: $($User.SamAccountName)"
    }
    catch {
        Write-Host "Error occurred while processing account $($User.SamAccountName): $($_.Exception.Message)" -ForegroundColor Yellow
    }
}

# Display the account details
$AccountDetails | Format-Table -AutoSize

# Define CSV file path
$CsvFilePath = "C:\temp\DeprecatedAccounts_$(Get-Date -Format 'yyyy-MM-dd').csv"

# Ensure the directory exists
$CsvDirectory = [System.IO.Path]::GetDirectoryName($CsvFilePath)
if (-not (Test-Path -Path $CsvDirectory)) {
    try {
        New-Item -Path $CsvDirectory -ItemType Directory -Force
    } catch {
        Write-Host "Failed to create directory: $($_.Exception.Message)" -ForegroundColor Red
        exit
    }
}

# Export the account details to a CSV file
try {
    $AccountDetails | Export-Csv -Path $CsvFilePath -NoTypeInformation
    Write-Host "Account details have been exported to $CsvFilePath" -ForegroundColor Green
} catch {
    Write-Host "Failed to export to CSV: $($_.Exception.Message)" -ForegroundColor Red
}
