<#
********************************************************************************
# SUMMARY:      List All Users Without MFA
# AUTHOR:       Joshua Ogden
# DESCRIPTION:  This script retrieves a list of all Azure Active Directory users
#               who do not have Multi-Factor Authentication (MFA) enabled.
# COMPATIBILITY: Azure Active Directory, PowerShell 7.0+
# NOTES:        Ensure you have the Microsoft.Graph module installed and are 
#               connected to your Azure AD environment before running this script.
# ERROR: This script is checking the wrong location for MFA status. It should be checking the user's MFA status, not the authentication methods.
********************************************************************************
#>

# Import Microsoft.Graph module
#Import-Module Microsoft.Graph

# Variable Declaration
$OutputFilePath = "C:\temp\nomfa_$((Get-Date).ToString('MMMM-dd-yyyy')).csv"
$NonMfaUsers = @()

# Connect to Microsoft Graph
Write-Output "Connecting to Microsoft Graph..."
try {
    Connect-MgGraph -Scopes "User.Read.All", "Directory.Read.All"
} catch {
    Write-Error "Failed to connect to Microsoft Graph. Please ensure your credentials are correct and retry."
    exit
}

# Get all users in Azure AD
Write-Output "Retrieving all users from Azure AD..."
$AllUsers = Get-MgUser -All

# Check each user for MFA status
Write-Output "Checking MFA status for each user..."
foreach ($User in $AllUsers) {
    $AuthMethods = Get-MgUserAuthenticationMethod -UserId $User.Id
    $MfaEnabled = $AuthMethods.Methods -match 'microsoftAuthenticator'

    if (-not $MfaEnabled) {
        $NonMfaUsers += New-Object PSObject -Property @{
            UserPrincipalName = $User.UserPrincipalName
            DisplayName = $User.DisplayName
            MFAStatus = "Disabled"
        }
    }
}

# Export results to CSV
Write-Output "Exporting results to $OutputFilePath..."
try {
    $NonMfaUsers | Export-Csv -Path $OutputFilePath -NoTypeInformation
    Write-Output "Export completed successfully."
} catch {
    Write-Error "Failed to export results to CSV. Please check the file path and permissions."
    exit
}

Write-Output "Script execution completed."