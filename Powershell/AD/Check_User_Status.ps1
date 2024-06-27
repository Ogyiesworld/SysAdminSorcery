# Import the Active Directory module
Import-Module ActiveDirectory

# Specify the username you want to check
$username = Read-Host "Enter the username"

# Check if the user exists in Active Directory
if (Get-ADUser -Filter {SamAccountName -eq $username} -ErrorAction SilentlyContinue) {
    # Get the user object from Active Directory
    $user = Get-ADUser -Identity $username -Properties Enabled, CanonicalName, PasswordExpired

    # Check if the user is disabled
    if ($user.Enabled -eq $false) {
        Write-Host "User '$username' is disabled"
    }
    else {
        Write-Host "User '$username' is enabled"
    }

    # Get the OUs the user is in
    $ou = $user.CanonicalName
    Write-Host "User '$username' is in the following OU: $ou"

    # Check if the user's password is expired
    if ($user.PasswordExpired -eq $true) {
        Write-Host "User '$username' has an expired password"
    }
    else {
        Write-Host "User '$username' does not have an expired password"
    }
}
else {
    Write-Host "User '$username' not found"
}