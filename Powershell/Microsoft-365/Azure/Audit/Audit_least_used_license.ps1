<#
********************************************************************************
# SUMMARY:      Find Least Used Microsoft License in Azure AD
# AUTHOR:       Joshua Ogden
# DESCRIPTION:  This script retrieves all users from Azure AD, gathers details about 
#               their assigned licenses, and calculates the usage rate to find the
#               least used licenses.
# COMPATIBILITY: AzureAD Module, PowerShell 5.1 or higher
# NOTES:        Ensure you have the AzureAD module installed and appropriate permissions
#               to access user and license information in Azure AD.
********************************************************************************
#>

# Import the required module
Import-Module AzureAD -ErrorAction Stop
try {
    Connect-AzureAD -ErrorAction Stop
} catch {
    Write-Error "Failed to connect to Azure AD. Please check your credentials and network connectivity."
    return
}

# Function to fetch all users and their assigned licenses
function Get-UsersAndLicenses {
    try {
        $Users = Get-AzureADUser -All $true
        $UserLicenses = foreach ($User in $Users) {
            $Licenses = Get-AzureADUserLicenseDetail -ObjectId $User.ObjectId
            foreach ($License in $Licenses) {
                [PSCustomObject]@{
                    UserPrincipalName = $User.UserPrincipalName
                    DisplayName       = $User.DisplayName
                    License           = $License.SkuPartNumber
                }
            }
        }
        return $UserLicenses
    } catch {
        Write-Error "An error occurred while fetching users and licenses: $_"
        return $null
    }
}

# Function to retrieve the last login date for each user
function Get-UserLastLogin {
    param (
        [Parameter(Mandatory=$true)]
        [string]$UserPrincipalHandle
    )

    try {
        $AuditLogs = Get-AzureADAuditSignInLogs -Filter "userPrincipalName eq '$UserPrincipalHandle'" -Top 1
        if ($AuditLogs) {
            return $AuditLogs[0].CreatedDateTime
        } else {
            return $null
        }
    } catch {
        Write-Error "Failed to retrieve login data for user $UserPrincipalHandle."
        return $null
    }
}

# Main execution block
Write-Host "Fetching users and their licenses..."
$UsersAndLicenses = Get-UsersAndLicenses

if (-not $UsersAndLicenses) {
    Write-Host "No user license data fetched. Exiting script..."
    return
}

Write-Host "Fetching last login time for each user..."
$AllUserLogins = foreach ($UserLicense in $UsersAndLicenses) {
    $LastLogin = Get-UserLastLogin -UserPrincipalHandle $UserLicense.UserPrincipalName
    [PSCustomObject]@{
        UserPrincipalName = $UserLicense.UserPrincipalName
        DisplayName       = $UserLicense.DisplayName
        License           = $UserLicense.License
        LastLogin         = $LastLogin
    }
}

# Analyzing license usage
$LicenseUsage = $AllUserLogins | Group-Object -Property License | ForEach-Object {
    $License = $_.Name
    $TotalUsers = $_.Count
    $NoLoginUsers = ($_.Group | Where-Object { $_.LastLogin -eq $null }).Count
    [PSCustomObject]@{
        License           = $License
        TotalUsers        = $TotalUsers
        NoLoginUsers      = $NoLoginUsers
        UtilizationRate   = (($TotalUsers - $NoLoginUsers) / $TotalUsers) * 100
    }
}

Write-Host "License Utilization Summary:"
$LicenseUsage | Sort-Object UtilizationRate | Format-Table -AutoSize

# Ensure target directory exists
$ExportPath = 'C:\temp'
if (-not (Test-Path -Path $ExportPath)) {
    New-Item -ItemType Directory -Path $ExportPath -Force
}

# Generate a filename with today's date
$Today = Get-Date -Format "MMMM-d-yyyy"
$FileName = "LicenseUtilization_${Today}.csv"
$FullPath = Join-Path -Path $ExportPath -ChildPath $FileName

# Export data to CSV
try {
    $LicenseUsage | Export-Csv -Path $FullPath -NoTypeInformation -Encoding UTF8
    Write-Host "Data successfully exported to $FullPath"
} catch {
    Write-Error "Failed to export data: $_"
}