<# 
********************************************************************************
# SUMMARY:      Retrieve Last Login Time for Azure AD Users and Export to CSV
# AUTHOR:       Joshua Ogden
# DESCRIPTION:  This script connects to Azure AD via Microsoft Graph and retrieves
#               the last login time for all users. Users are listed in descending 
#               order of their last login time, helping identify accounts that may 
#               need to be removed or have licenses downgraded.
#               The results are exported to a CSV file at C:\temp\entra_last_login_YYYYMMDD.csv.
# COMPATIBILITY: Azure AD, PowerShell
# NOTES:        Requires the Microsoft.Graph.Users module to be installed.
#               Ensure you have the necessary permissions: User.Read.All and 
#               AuditLog.Read.All.
********************************************************************************
#>

# Connect to Microsoft Graph with the required scopes
Connect-MgGraph -Scopes "User.Read.All","AuditLog.Read.All"

try {
    # Get all users with the signInActivity property
    $users = Get-MgUser -All -Property "displayName,userPrincipalName,signInActivity"

    # Create a list of users with their last sign-in time
    $userLogins = $users | ForEach-Object {
        $lastSignIn = if ($_.SignInActivity) { $_.SignInActivity.LastSignInDateTime } else { $null }
        [PSCustomObject]@{
            UserPrincipalName = $_.UserPrincipalName
            DisplayName       = $_.DisplayName
            LastLogin         = $lastSignIn
        }
    }

    # Sort users by last login time in descending order
    $sortedUserLogins = $userLogins | Sort-Object -Property LastLogin -Descending

    # Prepare the output file path
    $dateString = (Get-Date).ToString('yyyyMMdd')
    $outputDirectory = "C:\temp"
    $outputFile = "$outputDirectory\entra_last_login_$dateString.csv"

    # Ensure the output directory exists
    if (-not (Test-Path -Path $outputDirectory)) {
        New-Item -ItemType Directory -Path $outputDirectory | Out-Null
    }

    # Export the data to CSV
    $sortedUserLogins | Export-Csv -Path $outputFile -NoTypeInformation -Encoding UTF8

    Write-Host "User login information exported to $outputFile"

}
catch {
    Write-Error "An error occurred: $_"
}
finally {
    # Disconnect from Microsoft Graph
    Disconnect-MgGraph
}
