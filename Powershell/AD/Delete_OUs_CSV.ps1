<#
****************************************************************************************************
# SUMMARY:      Interactively Deletes Specified Active Directory Organizational Units
# AUTHOR:       Joshua Ogden
# DESCRIPTION:  This interactive script deletes specific Active Directory Organizational Units (OUs) 
#               after reading their DistinguishedNames from a CSV file. Users are prompted to specify 
#               the CSV file path and confirm each OU deletion, ensuring intentional and accurate 
#               management of AD structure.
# COMPATIBILITY: Windows Server with Active Directory module for Windows PowerShell.
# NOTES:        Version 1.1. Last Updated: [04/03/2024]. Ensure you have backed up your Active 
#               Directory before proceeding. Confirm each deletion to prevent unintended data loss. 
#               The CSV file must include a 'DistinguishedName' column for OU entries.
****************************************************************************************************
#>

# Import Active Directory Module
try {
    Import-Module ActiveDirectory -ErrorAction Stop
} catch {
    Write-Error "Failed to load Active Directory module. Error: $_"
    exit
}

# Prompt for CSV File Path
$CsvPath = Read-Host "Please enter the path to the CSV file containing OUs to delete"

# Validate CSV File Path
if (-not (Test-Path $CsvPath)) {
    Write-Error "The specified CSV file path does not exist: $CsvPath"
    exit
}

# Read OU Distinguished Names from CSV
try {
    $OUsToDelete = Import-Csv -Path $CsvPath
} catch {
    Write-Error "Failed to read CSV file at $CsvPath. Error: $_"
    exit
}

# Interactive OU Deletion
foreach ($OU in $OUsToDelete) {
    $userConfirmation = Read-Host "Are you sure you want to delete the OU $($OU.DistinguishedName)? (Y/N)"
    if ($userConfirmation -eq 'Y' -or $userConfirmation -eq 'y') {
        try {
            Remove-ADOrganizationalUnit -Identity $OU.DistinguishedName -Recursive -Confirm:$false
            Write-Host "Successfully deleted OU: $($OU.DistinguishedName)" -ForegroundColor Green
        } catch {
            Write-Error "Failed to delete OU: $($OU.DistinguishedName). Error: $_"
        }
    } else {
        Write-Host "Skipping OU: $($OU.DistinguishedName)"
    }
}

Write-Host "Operation completed." -ForegroundColor Yellow
