<#
********************************************************************************
# SUMMARY:      Creates a new Active Directory user
# AUTHOR:       Joshua Ogden
# DESCRIPTION:  This script prompts for user details, checks if the user already exists,
#               and if not, creates a new user in Active Directory. It also logs the user
#               details on the specified Domain Controller.
# COMPATIBILITY: Windows PowerShell 5.0 or later
# NOTES:        Ensure the script is run with appropriate permissions to create AD users.
********************************************************************************
#>

# Variable Declaration
$DCServerHostname = $null
$FirstName = $null
$Initial = $null
$Surname = $null
$EmailAddressDomain = $null
$localdomain = $Null
$MobilePhone = $null
$Address = $null
$City = $null
$State = $null
$ZipCode = $null
$Title = $null
$Manager = $null
$OUPath = $null
$Password = $null

# Inputs to create the User
$DCServerHostname = Read-Host -Prompt 'Enter the hostname of the Domain Controller'
$FirstName = Read-Host -Prompt 'First name'
$Initial = Read-Host -Prompt 'Initial'
$Surname = Read-Host -Prompt 'Last Name'
$localDomain = Read-Host -Prompt 'Enter the local domain extension, e.g., "example.local"'
$EmailAddressDomain = Read-Host -Prompt 'Enter the domain of the email'
$MobilePhone = Read-Host -Prompt 'Mobile phone with periods between, e.g., 123.123.1234'
$Address = Read-Host -Prompt 'Users home address'
$City = Read-Host -Prompt 'Users City'
$State = Read-Host -Prompt 'Users State'
$ZipCode = Read-Host -Prompt 'Users Zip Code'
$Title = Read-Host -Prompt 'Users Title'
$Manager = Read-Host -Prompt 'Manager Username'
$OUPath = Read-Host -Prompt 'Insert the OU path for the user, e.g., "OU=Sales,OU=Users,DC=example,DC=com"'
$Password = Read-Host -Prompt 'Password'

# Validate essential fields
if (-not $DCServerHostname) { throw 'Domain Controller hostname is required' }
if (-not $localDomain) { throw 'Local domain extension is required' }
if (-not $EmailAddressDomain) { throw 'Email domain is required' }
if (-not $FirstName) { throw 'First name is required' }
if (-not $Surname) { throw 'Last name is required' }
if (-not $OUPath) { throw 'OU path is required' }
if (-not $Password) { throw 'Password is required' }

$Name = "$FirstName $Surname"

# Show inputs
Write-Output "First name and last name: $Name"
Write-Output '--------------'
Write-Output "First name: $FirstName"
Write-Output '--------------'
Write-Output "Initial: $Initial"
Write-Output '--------------'
Write-Output "Last Name: $Surname"
Write-Output '--------------'
Write-Output "Username: $FirstName.$Surname"
Write-Output '--------------'
Write-Output "User Principal Name: $FirstName.$Surname@$localDomain"
Write-Output '--------------'
Write-Output "Email Address: $FirstName.$surname@$EmailAddressDomain'"
Write-Output '--------------'
Write-Output "Mobile: $MobilePhone"
Write-Output '--------------'
Write-Output "Address: $Address"
Write-Output '--------------'
Write-Output "City: $City"
Write-Output '--------------'
Write-Output "State: $State"
Write-Output '--------------'
Write-Output "Zip Code: $ZipCode"
Write-Output '--------------'
Write-Output "Title: $Title"
Write-Output '--------------'
Write-Output "Manager: $Manager"
Write-Output '--------------'
Write-Output "OU Path: $OUPath"
Write-Output '--------------'

Read-Host -Prompt "Check output is correct then press any key to continue..."

# Check if the user account already exists in AD
Invoke-Command -ComputerName "$DCServerHostname" -ScriptBlock {
    if (Get-ADUser -Filter { SamAccountName -eq "$FirstName.$Surname" }) {
        # If user exists, output a warning message
        Write-Warning "A user account '$FirstName $Surname' already exists in Active Directory."
        exit
    }
}

# Confirm to continue with account creation
Write-Host -NoNewLine "Continue with account creation? (Y/N) "
$response = Read-Host
if ($response -ne "Y") { exit }

# Prepare parameters for New-ADUser
$Params = @{
    Name              = $Name
    SamAccountName    = "$FirstName.$Surname"
    GivenName         = $FirstName
    Surname           = $Surname
    DisplayName       = "$FirstName $Initial $Surname"
    EmailAddress      = "$FirstName.$surname@$EmailAddressDomain"
    Country           = "US"
    UserPrincipalName = "$FirstName.$Surname@$localDomain"
    Path              = $OUPath
    AccountPassword   = (ConvertTo-SecureString $Password -AsPlainText -Force)
    Enabled           = $true
}

# Add optional parameters if they are not empty
if ($Initial) { $Params.Add("Initial", $Initial) }
if ($Title) { $Params.Add("Title", $Title) }
if ($Manager) { $Params.Add("Manager", $Manager) }
if ($MobilePhone) { $Params.Add("MobilePhone", $MobilePhone) }
if ($Address) { $Params.Add("StreetAddress", $Address) }
if ($City) { $Params.Add("City", $City) }
if ($State) { $Params.Add("State", $State) }
if ($ZipCode) { $Params.Add("PostalCode", $ZipCode) }

# Create the user account
try {
    Invoke-Command -ComputerName "$DCServerHostname" -ScriptBlock {
        param ($UserParams)
        New-ADUser @UserParams
    } -ArgumentList $Params

    Write-Output "User '$FirstName $Surname' created successfully."
}
catch {
    Write-Error "Failed to create user: $_"
}

# Create a log file on the DC server if it does not exist
$LogFilePath = "C:\temp\NewUserLog.txt"
if (!(Test-Path $LogFilePath)) {
    try {
        New-Item $LogFilePath -ItemType File
        Write-Output "Log file created at $LogFilePath"
    }
    catch {
        Write-Error "Failed to create log file: $_"
    }
}

# Log user details to the file
try {
    Invoke-Command -ComputerName "$DCServerHostname" -ScriptBlock {
        param ($UserSamAccountName)
        Get-ADUser -Identity $UserSamAccountName -Properties * | Out-File -FilePath "C:\temp\NewUserLog.txt" -Append
    } -ArgumentList "$FirstName.$Surname"

    Write-Output "User details logged to $LogFilePath"
}
catch {
    Write-Error "Failed to log user details: $_"
}

Write-Host -NoNewLine "Would you like to view user properties? (Y/N) "
$response = Read-Host
if ($response -ne "Y") { exit }

# Output user information
try {
    Get-ADUser -Identity "$FirstName.$Surname" -Properties *
}
catch {
    Write-Error "Failed to retrieve user information: $_"
}

Read-Host -Prompt "Press any key to end the script"