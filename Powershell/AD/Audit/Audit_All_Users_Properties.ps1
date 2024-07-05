<#
********************************************************************************
# SUMMARY:      Export All Active Directory Users to CSV
# AUTHOR:       Joshua Ogden
# DESCRIPTION:  This script retrieves all properties of all Active Directory (AD) users 
#               and exports them to a CSV file named with the current date.
# COMPATIBILITY: Windows PowerShell 5.1, PowerShell 7
# NOTES:        Ensure you have the Active Directory module installed and 
#               necessary permissions to query AD.
********************************************************************************
#>

# Get the current date in the format "yyyyMMdd"
$Date = Get-Date -Format "yyyyMMdd"

# Define the CSV file path
$CsvPath = "C:\temp\ad_users_$Date.csv"

try {
    # Ensure the Active Directory module is imported
    if (-not (Get-Module -ListAvailable -Name ActiveDirectory)) {
        throw "The Active Directory module is not installed on this system."
    }

    Import-Module ActiveDirectory

    # Get all properties of all AD users and export them to a CSV file
    Get-ADUser -Filter * -Properties * |
        Select-Object -Property * |
        Export-Csv -Path $CsvPath -NoTypeInformation

    Write-Output "AD user information successfully exported to $CsvPath"
}
catch {
    Write-Error "An error occurred: $_"
}
