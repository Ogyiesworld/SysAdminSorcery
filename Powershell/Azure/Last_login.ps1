<#
********************************************************************************
# SUMMARY:      Retrieve Last Login Time for Azure AD Users
# AUTHOR:       Joshua Ogden
# DESCRIPTION:  This script connects to Azure AD and retrieves the last login time 
#               for all users in Azure AD. The users will be listed in descending 
#               order of their last login time. This will create a list of users 
#               that should be removed or have their licenses downgraded.
# COMPATIBILITY: Azure AD, PowerShell
# NOTES:        Requires the AzureAD and Microsoft.Graph modules to be installed.
********************************************************************************
#>
# connect to Azure AD
Connect-AzureAD

try {
    # Get all users
    $users = Get-AzureADUser -All $true

    # Get last login time for each user
    $userLogins = $users | ForEach-Object {
        $lastLogin = Get-AzureADAuditSignInLogs -Filter "userPrincipalName eq '$($_.UserPrincipalName)'" -Top 1
        [PSCustomObject]@{
            UserPrincipalName = $_.UserPrincipalName
            DisplayName       = $_.DisplayName
            LastLogin         = $lastLogin.CreatedDateTime
        }
    }

    # Sort users by last login time in descending order and display
    $userLogins | Sort-Object -Property LastLogin -Descending | Format-Table -AutoSize
}
catch {
    Write-Error "An error occurred: $_"
}
finally {
    # Disconnect from Microsoft Graph and Azure AD
    write-host "close window to disconnect"
}
