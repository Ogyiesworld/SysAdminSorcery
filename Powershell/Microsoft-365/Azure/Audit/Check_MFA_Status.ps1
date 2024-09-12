<#
********************************************************************************
# SUMMARY:      Retrieve Azure AD Users MFA Status and Authentication Methods
# AUTHOR:       Joshua Ogden
# DESCRIPTION:  This script connects to Azure AD, retrieves all users, and 
#               checks each user's MFA status and authentication methods. 
#               It exports the information to a CSV file with the current date in the filename.
# COMPATIBILITY: Windows PowerShell with AzureAD module installed
# NOTES:        Ensure that you have the necessary permissions to access Azure AD 
#               and retrieve user information.
********************************************************************************
#>

# Variable Declaration
$Date = Get-Date -Format "MMMM-d-yyyy"
$OutputFile = "AzureAD_MFA_Status_$Date.csv"
$UsersMFAStatus = @()

# Connect to Azure AD
try {
    Connect-AzureAD
} catch {
    Write-Error "Failed to connect to Azure AD. Please ensure you have the necessary permissions and retry."
    exit
}

# Retrieve all users from Azure AD
$AllUsers = Get-AzureADUser -All $true

# Loop through each user and get their MFA status and authentication methods
foreach ($User in $AllUsers) {
    $UserId = $User.ObjectId
    
    try {
        $MFAStatus = Get-AzureADUserRegisteredDevice -ObjectId $UserId -ErrorAction Stop | ForEach-Object {
            @{
                UserPrincipalName = $User.UserPrincipalName
                MFAEnabled = $_.MFAStatus
                AuthMethod = $_.AuthenticationMethod
            }
        }
    } catch {
        Write-Error "Failed to retrieve MFA status for user: $($User.UserPrincipalName). Error: $_"
        continue
    }

    # Add user's MFA status and auth methods to the list
    $UsersMFAStatus += $MFAStatus
}

# Export MFA status and authentication methods to a CSV file
try {
    $UsersMFAStatus | Export-Csv -Path $OutputFile -NoTypeInformation
    Write-Output "MFA status and authentication methods have been successfully exported to $OutputFile."
} catch {
    Write-Error "Failed to export MFA status to CSV. Error: $_"
}