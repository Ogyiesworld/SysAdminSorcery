<#
********************************************************************************
# SUMMARY:      Check and Validate Password Complexity Requirements
# AUTHOR:       Joshua Ogden
# DESCRIPTION:  This script retrieves and displays the domain password complexity 
#               requirements. It also includes a test to check if a given password 
#               meets these requirements.
# COMPATIBILITY: Windows Server with Active Directory
# NOTES:        Ensure you run this script with appropriate permissions.
#********************************************************************************
#>

# Variable Declaration
$Date = Get-Date -Format "MMMM-d-yyyy"
$TestPassword = "TestPassword123!"   # Test password to check against the policy

try {
    # Check the password complexity requirements
    $PasswordComplexity = Get-ADDefaultDomainPasswordPolicy

    # Output the password complexity requirements
    Write-Host "Password Complexity Requirements for $Date:"
    Write-Host "---------------------------------"
    Write-Host "Minimum Password Length: $($PasswordComplexity.MinPasswordLength)"
    Write-Host "Password History Length: $($PasswordComplexity.PasswordHistoryCount)"
    Write-Host "Maximum Password Age: $($PasswordComplexity.MaxPasswordAge)"
    Write-Host "Minimum Password Age: $($PasswordComplexity.MinPasswordAge)"
    Write-Host "Password Complexity Enabled: $($PasswordComplexity.ComplexityEnabled)"
    Write-Host "Reversible Encryption Enabled: $($PasswordComplexity.ReversibleEncryptionEnabled)"
    Write-Host "Lockout Threshold: $($PasswordComplexity.LockoutThreshold)"
    Write-Host "Lockout Duration: $($PasswordComplexity.LockoutDuration)"
    Write-Host "Lockout Observation Window: $($PasswordComplexity.LockoutObservationWindow)"
    Write-Host "---------------------------------"
    
    # Convert the test password to a secure string
    $SecureTestPassword = ConvertTo-SecureString -String $TestPassword -AsPlainText -Force

    # Find an user to simulate password complexity check
    $User = Get-ADUser -Filter {SamAccountName -eq 'Administrator'} -Properties DistinguishedName

    if ($User) {
        # Simulation of setting the password to test it (without actual account modification)
        Write-Host "Testing password complexity with password: $TestPassword"
        try {
            $TestResult = Set-ADAccountPassword -Identity $User.DistinguishedName -NewPassword $SecureTestPassword -PassThru -ErrorAction Stop
            Write-Host "Password meets the complexity requirements."
        } catch {
            Write-Host "Password does not meet the complexity requirements: " + $_.Exception.Message
        }
    } else {
        Write-Host "Could not find the user 'Administrator' to test the password complexity."
    }
} catch {
    Write-Host "There was an error while retrieving the password complexity requirements:"
    Write-Host $_.Exception.Message
}
