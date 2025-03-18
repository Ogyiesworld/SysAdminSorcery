# connect to Microsoft Graph
Connect-MgGraph

# Variables
$Date = Get-Date -Format 'yyyyMMdd'
$CsvPath = "C:\Temp\All_Users_Licenses_$Date.csv"

# List all users in M365 UPN and their associated licenses
try {
    # Get all users from M365 with their UPN and licenses
    $Users = Get-MgUser -All -Property "UserPrincipalName", "AssignedLicenses"

    # Process user data
    $UserData = $Users | ForEach-Object {
        $Licenses = $_.AssignedLicenses | ForEach-Object { (Get-MgSubscribedSku -SkuId $_.SkuId).SkuPartNumber }
        [PSCustomObject]@{
            UserPrincipalName = $_.UserPrincipalName
            Licenses = ($Licenses -join ', ')
        }
    }

    # Export to CSV
    $UserData | Export-Csv -Path $CsvPath -NoTypeInformation
    Write-Host "Users and their associated licenses exported to $CsvPath" -ForegroundColor Green
} catch {
    Write-Error "An error occurred: $_"
}