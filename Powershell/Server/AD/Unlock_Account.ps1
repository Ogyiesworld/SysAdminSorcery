# Import the Active Directory module
Import-Module ActiveDirectory

# Ask the username of the account you want to unlock
$accountName = Read-Host "Enter the username of the account you want to unlock"
# Get the user object from Active Directory
$user = Get-ADUser -Identity $accountName

# Check if the user account is locked
if ($user.LockedOut) {
    # Unlock the user account
    $user | Unlock-ADAccount
    Write-Host "User account '$accountName' has been unlocked."
} else {
    Write-Host "User account '$accountName' is already unlocked."
}