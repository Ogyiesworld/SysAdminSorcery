<#
********************************************************************************
# SUMMARY:      Disable and Move User Accounts
# AUTHOR:       Joshua Ogden
# DESCRIPTION:  This script disables specified user accounts and moves them to 
#               the 'Disabled Accounts' Organizational Unit in Active Directory.
# COMPATIBILITY: Windows PowerShell, Active Directory Module
# NOTES:        Make sure the script is run with sufficient privileges to make
#               changes in Active Directory.
********************************************************************************
#>

# ----- Centralized Declaration -----
$Usernames = @('username')
$TargetOU = "OU=Disabled Accounts,DC=yourDC,DC=org" # Update with your actual domain's DN
$CurrentDate = Get-Date -Format "MMMM-dd-yyyy"
$LogFile = "C:\Logs\DisabledAccounts_$CurrentDate.log" # Log file to record actions

# Begin Script
try {
    Import-Module ActiveDirectory

    # Checking and creating log directory if necessary
    $LogDirectory = Split-Path $LogFile -Parent
    if (-not (Test-Path $LogDirectory)) {
        New-Item -ItemType Directory -Path $LogDirectory
    }

    # Logging the start of the script
    Add-Content -Path $LogFile -Value ("Script started on " + (Get-Date))

    foreach ($Username in $Usernames) {
        try {
            # Retrieve the user's current distinguished name
            $User = Get-ADUser -Identity $Username
            $OriginalOU = $User.DistinguishedName
            
            # Disable the user account
            Disable-ADAccount -Identity $Username

            # Move the user to the 'Disabled Accounts' OU
            Move-ADObject -Identity $OriginalOU -TargetPath $TargetOU

            # Log the success and original OU
            Add-Content -Path $LogFile -Value ("Successfully disabled and moved user " + $Username + " from " + $OriginalOU + " to " + $TargetOU + " on " + (Get-Date))
        } catch {
            # Log any errors encountered for this user
            Add-Content -Path $LogFile -Value ("Error processing user " + $Username + ": " + $_)
        }
    }

    # Logging the end of the script
    Add-Content -Path $LogFile -Value ("Script ended on " + (Get-Date))
} catch {
    Write-Error ("An error occurred: " + $_)
}