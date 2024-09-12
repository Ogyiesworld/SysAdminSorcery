<#
********************************************************************************
# SUMMARY:      Update AD Groups Description from CSV
# AUTHOR:       Joshua Ogden
# DESCRIPTION:  This script reads group descriptions from a CSV file and updates
#               the corresponding AD group descriptions.
#               The CSV file must have columns: SamAccountName, Description.
# COMPATIBILITY: Windows PowerShell 5.1, PowerShell Core 7
# NOTES:        Requires Active Directory module. Run with administrator privileges.
********************************************************************************
#>

# Variable Declaration
[string]$CsvFilePath = Read-Host "Enter the path to the CSV file containing group descriptions:"

# Import the Active Directory module
Import-Module ActiveDirectory

# Function to update group descriptions
function Update-GroupDescription {
    param (
        [PSCustomObject]$GroupInfo
    )
    try {
        # Get the group using its SamAccountName
        $Group = Get-ADGroup -Filter { SamAccountName -eq $GroupInfo.SamAccountName }

        # If the group is found, update its description
        if ($Group) {
            Set-ADGroup -Identity $Group.DistinguishedName -Description $GroupInfo.Description
            Write-Output "Updated description for group: $($GroupInfo.SamAccountName)"
        } else {
            Write-Error "Group not found: $($GroupInfo.SamAccountName)"
        }
    } catch {
        Write-Error "Failed to update group $($GroupInfo.SamAccountName): $_"
    }
}

# Import the CSV file
try {
    $GroupUpdates = Import-Csv -Path $CsvFilePath
    Write-Output "CSV file imported successfully: $CsvFilePath"
    
    # Loop through each record in the CSV and update group descriptions
    foreach ($GroupInfo in $GroupUpdates) {
        Update-GroupDescription -GroupInfo $GroupInfo
    }
} catch {
    Write-Error "Failed to import CSV file: $_"
}