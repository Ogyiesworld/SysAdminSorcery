<#
****************************************************************************************************
# SUMMARY:      Formats and Updates User Phone Numbers in Azure AD
# AUTHOR:       Joshua Ogden
# DESCRIPTION:  This script connects to Azure AD, retrieves all user accounts, and formats their 
#               phone numbers to a standard format before updating the respective user profile. It 
#               aims to normalize phone number formats within the organization's Azure AD for 
#               consistency and easier management.
# COMPATIBILITY: Requires AzureAD or AzureADPreview module. Tested with PowerShell 5.1 and Azure PowerShell.
# NOTES:        Version 1.1. Last Updated: [04/03/2024]. Ensure the AzureAD or AzureADPreview module 
#               is installed and that you have the necessary permissions to update user attributes 
#               in Azure AD.
****************************************************************************************************
#>

# Connect to Azure AD
try {
    $connection = Connect-AzureAD
} catch {
    Write-Error "Failed to connect to Azure AD. Error: $_"
    exit
}

# Retrieve all user accounts from Azure AD
try {
    $users = Get-AzureADUser -All $true
} catch {
    Write-Error "Failed to retrieve users from Azure AD. Error: $_"
    exit
}

# Initialize updated users list
$updatedUsers = @()

foreach ($user in $users) {
    # Assume MobilePhone is the attribute to update; replace accordingly if necessary
    $phoneNumber = $user.MobilePhone

    if ($phoneNumber) {
        # Remove any non-numeric characters from the phone number
        $phoneNumber = $phoneNumber -replace "[^\d]"

        # Check and format phone number length; adjust format as needed
        if ($phoneNumber.Length -eq 10) {
            $formattedPhoneNumber = '{0:(###) ###-####}' -f [int64]$phoneNumber
        } elseif ($phoneNumber.Length -eq 11) {
            $formattedPhoneNumber = '{0:# (###) ###-####}' -f [int64]$phoneNumber
        } else {
            Write-Output "Phone number format for $($user.UserPrincipalName) is not standard. Skipping."
            continue
        }

        try {
            # Update the phone number attribute in Azure AD
            Set-AzureADUser -ObjectId $user.ObjectId -MobilePhone $formattedPhoneNumber
            # Collect updated users
            $updatedUsers += $user.UserPrincipalName
        } catch {
            Write-Error "Failed to update phone number for $($user.UserPrincipalName). Error: $_"
        }
    }
}

# Display the list of updated users
if ($updatedUsers.Count -gt 0) {
    Write-Output "Updated phone number for the following users:"
    $updatedUsers | ForEach-Object { Write-Output $_ }
} else {
    Write-Output "No users found with a valid phone number to update."
}
