<#
********************************************************************************
# SUMMARY:      Retrieves user details and license information.
# AUTHOR:       Joshua Ogden
# DESCRIPTION:  This script fetches details about users including login name, email,
#               display name, user type, account enabled status, last sign-in time, 
#               and associated licenses using Microsoft Graph cmdlets.
# COMPATIBILITY: Requires the Microsoft Graph PowerShell module.
# NOTES:        Ensure you have the necessary permissions and have connected to 
#               Microsoft Graph prior to running this script.
********************************************************************************
#>

function Get-UserAndLicenseDetails {
    $userData = @()  # Initialize an array to store user data

    try {
        $users = Get-MgUser -All -Property "UserPrincipalName,Mail,DisplayName,UserType,AccountEnabled,SignInActivity"

        foreach ($user in $users) {
            if ($null -eq $user.UserType) {
                Write-Host "UserType is null for $($user.DisplayName)"
            }
            if ($null -eq $user.AccountEnabled) {
                Write-Host "AccountEnabled is null for $($user.DisplayName)"
            }
            if ($null -eq $user.SignInActivity) {
                Write-Host "LastSignIn is null for $($user.DisplayName)"
            }

            $licenses = Get-MgUserLicenseDetail -UserId $user.Id
            $userObject = [PSCustomObject]@{
                LoginName      = $user.UserPrincipalName
                Email          = $user.Mail
                DisplayName    = $user.DisplayName
                UserType       = $user.UserType
                AccountEnabled = $user.AccountEnabled
                LastSignIn     = $user.SignInActivity.LastSignInDateTime
                Licenses       = ($licenses | ForEach-Object { $_.SkuPartNumber }) -join ', '
            }
            $userData += $userObject
        }
    } catch {
        Write-Error "An error occurred: $_"
    }

    return $userData
}

$userData = Get-UserAndLicenseDetails
$userData | Export-Csv -Path 'C:\temp\user_login_and_Licenses.csv' -NoTypeInformation
Write-Host "Data exported successfully to C:\temp\user_login_and_Licenses.csv"
