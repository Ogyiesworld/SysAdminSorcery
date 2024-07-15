# Repository Coding Style Guide

Welcome to our coding style guide! This document aims to ensure consistency and quality across all PowerShell scripts in this repository. By following these guidelines, we can make our code more readable, maintainable, and efficient. Let's get started!

## Header and Author Box

Every script must begin with a standardized header and author box. This enhances documentation and clarity. The header format should be as follows:

```powershell
<#
********************************************************************************
# SUMMARY:      <Script Purpose>
# AUTHOR:       <Author Name>
# DESCRIPTION:  <Detailed Description>
# COMPATIBILITY: <Compatibility Information>
# NOTES:        <Additional Notes>
********************************************************************************
#>
```

Example:

```powershell
<#
********************************************************************************
# SUMMARY:      Export Active Directory User Information
# AUTHOR:       Joshua Ogden
# DESCRIPTION:  This script exports user information from Active Directory to a CSV file.
# COMPATIBILITY: Windows 10, Windows Server 2016 and above
# NOTES:        Requires the Active Directory module
********************************************************************************
#>
```

## Centralized Declarations

Declare all variables and functions immediately after the header. This practice ensures ease of maintenance and readability.

Example:

```powershell
# Variables
$ExportFileName = "adusersinfo_$((Get-Date).ToString('MMMM-d-yyyy')).csv"
$ServerName = "DC02"

# Functions
function Get-ADUserInfo {
    # Function implementation here
}
```

## Variable and Function Naming

Use PascalCase for naming variables and functions. This improves readability and consistency throughout the script.

Correct Example:

```powershell
$UserName
$UserEmail
function ExportUserInfo {
    # Function implementation here
}
```

Incorrect Example:

```powershell
$username
$useremail
function exportuserinfo {
    # Function implementation here
}
```

## Error Handling

Incorporate error checking and use try and catch blocks to handle exceptions gracefully. This makes the script robust and reliable.

Example:

```powershell
try {
    # Code that might throw an exception
}
catch {
    Write-Error "An error occurred: $_"
}
```

## Comments

Add comprehensive comments within the script, explaining each section in detail. This aids understanding for tier 1 and tier 2 technicians.

Example:

```powershell
# Connect to Active Directory
try {
    Import-Module ActiveDirectory -ErrorAction Stop
    Write-Output "Successfully imported Active Directory module."
}
catch {
    Write-Error "Failed to import Active Directory module. Error: $_"
    exit
}

# Function to get user information from Active Directory
function Get-ADUserInfo {
    param (
        [string]$UserName
    )

    # Get user properties from AD
    try {
        $User = Get-ADUser -Filter {SamAccountName -eq $UserName} -Properties DisplayName, EmailAddress
        return $User
    }
    catch {
        Write-Error "Failed to retrieve user info for $UserName. Error: $_"
    }
}
```

## File Naming Convention

Always include the date in the export file's name, formatted as Month-day-year.

Correct Example:

```powershell
$ExportFileName = "adusersinfo_$((Get-Date).ToString('MMMM-d-yyyy')).csv"
```

Incorrect Example:

```powershell
$ExportFileName = "adusersinfo.csv"
```
