<#
********************************************************************************
# SUMMARY:      Find Least Used Microsoft License in Azure AD
# AUTHOR:       Joshua Ogden
# DESCRIPTION:  This script retrieves the last login time for all users in Azure AD
#               and analyzes the usage of each license type to determine the 
#               least used licenses.
# COMPATIBILITY: AzureAD Module
# NOTES:        Ensure you have the necessary permissions to access the Azure AD
#               tenant and read user details.
# STATUS:       Broken
********************************************************************************
#>

# Import necessary module
Import-Module AzureAD -WarningAction SilentlyContinue
connect-azuread 
# Function to get users and their licenses
function Get-UsersAndLicenses {
    $Users = Get-AzureADUser -All $true
    $UserLicenses = @()

    foreach ($User in $Users) {
        $Licenses = Get-AzureADUserLicenseDetail -ObjectId $User.ObjectId
        foreach ($License in $Licenses) {
            $UserLicenses += [PSCustomObject]@{
                UserPrincipalName = $User.UserPrincipalName
                DisplayName       = $User.DisplayName
                License           = $License.SkuPartNumber
            }
        }
    }

    return $UserLicenses
}

# Function to get last login time for a user
function Get-UserLastLogin {
    param (
        [Parameter(Mandatory=$true)]
        [string]$UserPrincipalName
    )

    $AuditLogs = Get-AzureADAuditSignInLogs -Filter "userPrincipalName eq '$UserPrincipalName'" -Top 1
    if ($AuditLogs) {
        return $AuditLogs[0].CreatedDateTime
    } else {
        return $null
    }
}

# Main script
Write-Host "Fetching users and their licenses..."
$UsersAndLicenses = Get-UsersAndLicenses

Write-Host "Fetching last login time for each user..."
$AllUserLogins = @()
foreach ($UserLicense in $UsersAndLicenses) {
    $LastLogin = Get-UserLastLogin -UserPrincipalName $UserLicense.UserPrincipalName
    $AllUserLogins += [PSCustomObject]@{
        UserPrincipalName = $UserLicense.UserPrincipalName
        DisplayName       = $UserLicense.DisplayName
        License           = $UserLicense.License
        LastLogin         = $LastLogin
    }
}

# Group by license and count logins
$LicenseUsage = $AllUserLogins | Group-Object -Property License | ForEach-Object {
    $License = $_.Name
    $TotalUsers = $_.Count
    $NoLoginUsers = $_.Group | Where-Object { $_.LastLogin -eq $null } | Measure-Object | Select-Object -ExpandProperty Count
    [PSCustomObject]@{
        License        = $License
        TotalUsers     = $TotalUsers
        NoLoginUsers   = $NoLoginUsers
        UtilizationRate = (($TotalUsers - $NoLoginUsers) / $TotalUsers) * 100
    }
}

Write-Host "License Utilization Summary:"
$LicenseUsage | Sort-Object UtilizationRate | Format-Table -AutoSize
