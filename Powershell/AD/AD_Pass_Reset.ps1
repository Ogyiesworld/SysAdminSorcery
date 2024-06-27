# Ask the user to input the domain controller
$domainController = Read-Host "Enter the domain controller"
$username = Read-Host "Enter the username"

try {
    # Connect to a domain controller
    $credential = Get-Credential
    $session = New-PSSession -ComputerName $domainController -Credential $credential

    Invoke-Command -Session $session -ScriptBlock {
        param($username)

        try {
            # Get the user object
            $user = Get-ADUser -Identity $username -ErrorAction Stop

            # list the users first name and last name and email address in table format
            $user | Select-Object Name, EmailAddress | Format-Table -AutoSize

            # Confirm the user before changing the password
            $confirm = Read-Host "Are you sure you want to reset the password for user '$($user.Name)'? (Y/N)"
            if ($confirm -eq "Y") {
                # Reset the user's password
                $newPassword = Read-Host "Enter the new password" -AsSecureString
                Set-ADAccountPassword -Identity $user -NewPassword $newPassword -Reset
                Write-Output "Password reset successfully for user '$($user.Name)'."
            } else {
                Write-Output "Password reset cancelled."
            }
        } catch {
            Write-Output "Error: $_"
        }
    } -ArgumentList $username
} catch {
    Write-Output "Error: $_"
} finally {
    # Close the session
    if ($session) {
        Remove-PSSession -Session $session
    }
}
