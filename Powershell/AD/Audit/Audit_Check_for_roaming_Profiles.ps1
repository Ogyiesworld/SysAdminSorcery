<#
********************************************************************************
# SUMMARY:      PowerShell Script for Reporting on AD Roaming Profiles
# AUTHOR:       Joshua Ogden
# DESCRIPTION:  This script identifies Active Directory users with configured roaming profiles, 
#               listing their names and profile paths. It's tailored for administrators seeking 
#               to audit roaming profiles within their IT environment. The script offers the option 
#               to export the findings to a CSV file for further analysis or reporting.
# COMPATIBILITY: Windows Server with Active Directory. PowerShell 5.1 or higher.
# NOTES:        Version 1.1. Last Updated: [04/03/2024]. Active Directory module for Windows PowerShell is required.
#               Example Usage: .\ReportRoamingProfiles.ps1
#               The script is designed for analysis and reporting purposes only. Always verify the data for accuracy.
********************************************************************************
#>

# Fetch all AD users with a configured roaming profile
$RoamingUsers = Get-ADUser -Filter {msTSProfilePath -like "\\server\share\*"} -Properties Name, msTSProfilePath |
                Select-Object Name, msTSProfilePath

# Determine if roaming users were located
if ($RoamingUsers.Count -gt 0) {
    # Present the found roaming users
    Write-Host "Identified roaming profile users:"
    $RoamingUsers | Format-Table Name, msTSProfilePath

    # Ask whether to export this list to a CSV file
    $ExportResponse = Read-Host "Do you wish to export this list to a CSV file? (Y/N)"
    if ($ExportResponse -eq 'Y') {
        $ExportPath = Read-Host "Specify the full path for the CSV file"
        $RoamingUsers | Export-Csv -Path $ExportPath -NoTypeInformation
        Write-Host "List has been exported to $ExportPath"
    }
} else {
    Write-Host "No users with roaming profiles found in Active Directory."
}

# Reminder: This script is for reporting purposes only, providing insights into roaming profile configurations within your AD environment.
