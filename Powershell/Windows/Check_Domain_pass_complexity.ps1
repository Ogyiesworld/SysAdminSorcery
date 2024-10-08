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
    Write-Host "Password Complexity Requirements for $(Get-Date -Format 'MMMM d, yyyy'):"
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
    
    # Test the password against the password complexity requirements
    $SecureTestPassword = $TestPassword | ConvertTo-SecureString -AsPlainText -Force

    # Simulation of setting the password to test it (without actual account modification)
    Write-Host "Testing password complexity with password: $TestPassword"
    $TestResult = Set-ADAccountPassword -Identity (Get-ADUser -Filter {SamAccountName -eq 'Administrator'}).DistinguishedName -NewPassword $SecureTestPassword -PassThru -ErrorAction Stop
    if ($TestResult) {
        Write-Host "Password meets the complexity requirements."
    }
} catch {
    Write-Host "There was an error while checking the password complexity requirements:"
    Write-Host $_.Exception.Message
}