# Import the Active Directory module
Import-Module ActiveDirectory

# Get all users from Active Directory
$users = Get-ADUser -Filter * -Properties UserPrincipalName

# Initialize an array to hold the users where UPN and SAM do not match
$usersWithMismatch = @()

# Loop through each users account user logon name (without domain name) and sam account name
foreach ($user in $users) {
    if ($null -ne $user.UserPrincipalName) {
        $upn = $user.UserPrincipalName.Split("@")[0]  # Extract the username part of the UPN
        $sam = $user.SamAccountName

        # Check if UPN and SAM do not match
        if ($upn -ne $sam) {
            $usersWithMismatch += $user
        }
    }
}

# Output the list of users where UPN and SAM do not match
$usersWithMismatch | Select-Object Name, UserPrincipalName, SamAccountName | Format-Table

#output to csv
$usersWithMismatch | Select-Object Name, UserPrincipalName, SamAccountName | Export-Csv -Path "C:\Temp\UsersWithMismatch_SAM_UPN.csv" -NoTypeInformation
