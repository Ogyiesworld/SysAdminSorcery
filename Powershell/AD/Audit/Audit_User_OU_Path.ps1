<#
********************************************************************************
# SUMMARY:      Extract Organizational Unit Path of a User
# AUTHOR:       Joshua Ogden
# DESCRIPTION:  This script prompts for a username, retrieves the Distinguished 
#               Name (DN) of the corresponding user account from Active Directory,
#               and extracts the Organizational Unit (OU) path by removing the
#               Common Name (CN) component.
# COMPATIBILITY: Windows PowerShell with Active Directory module
# NOTES:        Ensure the Active Directory module is installed and the user 
#               executing the script has the necessary permissions.
********************************************************************************
#>

# Variable Declaration
$Username = $null
$User = $null
$OuPath = $null

# Import the Active Directory module (if not already imported)
Import-Module ActiveDirectory -ErrorAction Stop

# Prompt for the username
try {
    $Username = Read-Host -Prompt "Enter the user's username"
    
    # Get the distinguished name of the user
    $User = Get-ADUser -Identity $Username -Properties DistinguishedName
    
    # Extract the OU path
    $OuPath = $User.DistinguishedName -replace '^CN=[^,]+,', ''
    
    # Output only the OU path for easy copying
    Write-Output $OuPath
}
catch {
    # Catch any errors and display a message to the user
    Write-Output "Error: Unable to retrieve the user's information. Please ensure the username is correct and you have the necessary permissions."
}