<#
****************************************************************************************************
# SUMMARY:      Exports a List of AD Users Without a Manager Attribute to a CSV File
# AUTHOR:       Joshua Ogden
# DESCRIPTION:  This script searches Active Directory for users lacking a defined 'Manager' attribute 
#               and exports their details to a CSV file. It aims to assist in identifying and 
#               rectifying missing user manager information within an organization's Active Directory environment.
# COMPATIBILITY: Windows Server with Active Directory module for Windows PowerShell.
# NOTES:        Version 1.3. Last Updated: [04/03/2024]. Ensure you have appropriate permissions to 
#               query Active Directory. Users are prompted to specify an output directory for the CSV.
****************************************************************************************************
#>

# Import Active Directory Module
try {
    Import-Module ActiveDirectory -ErrorAction Stop
} catch {
    Write-Error "Failed to load Active Directory module. Error: $_"
    exit
}

# Prompt for output directory
$outputDir = Read-Host "Please enter the output directory path (e.g., C:\Users\Admin\Desktop)"
$FileName = "UsersWithoutManager.csv"
$FilePath = Join-Path -Path $outputDir -ChildPath $FileName

# Validate output directory
if (-not (Test-Path -Path $outputDir)) {
    Write-Error "The specified output directory does not exist."
    exit
}

# Retrieve and export AD users without a manager attribute
try {
    $usersWithoutManager = Get-ADUser -Filter 'Manager -notlike "*"' -Properties DisplayName, EmailAddress, Department, Title, Manager |
    Select-Object DisplayName, EmailAddress, Department, Title, Manager

    if ($usersWithoutManager) {
        $usersWithoutManager | Export-Csv -Path $FilePath -NoTypeInformation
        Write-Host "Users without manager attribute have been exported to '$FilePath'." -ForegroundColor Green
    } else {
        Write-Host "No users without a manager attribute were found." -ForegroundColor Yellow
    }
} catch {
    Write-Error "Failed to query Active Directory or export data. Error: $_"
}
