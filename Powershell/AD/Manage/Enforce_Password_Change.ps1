<#
********************************************************************************
# SUMMARY:      Script to enforce password change at next login for users.
# AUTHOR:       Joshua Ogden
# DESCRIPTION:  This script allows the user to specify multiple OUs, queries AD for users in those OUs, to require a password change at next login.
# COMPATIBILITY: Windows PowerShell 5.1, PowerShell 7+, Active Directory Module
# NOTES:        Ensure you have required privileges to query AD and modify user settings, and have the Microsoft Graph 
#               module installed. The script now also excludes accounts based on specific SamAccountNames.
********************************************************************************
#>

# Variable declaration
$OUs = @()                      # Array to hold Organizational Units specified by the user
$Users = @()                    # Array to hold user details fetched from AD
$CutoffDate = (Get-Date).AddDays(-12)    # Define cutoff date, users whose passwords haven't been changed in the last 10 days
$Domain = "contoso.com"         # Define the domain to filter email addresses
$InputOUs = @("DC=contoso,DC=com")  # Sample OUs input - Replace this with user input as needed
$DescriptionsToExclude = @("Special Mailbox", "Temporary Account", "Service Account", "Office mailbox")  # Define descriptions to filter out
$RegexToExcludeNumerics = '.*\d+.*'   # Regular expression to match any string with digits
$SamAccountNamesToExclude = @("HealthMailbox", "San", "Backup", "NAS", "Log", "IMAP", "Scan", "Pay", "Invoice", "Reserv", "mail", "noreply", "Phone",
"Update", "Invest", "Data", "resume", "Print", "campain", "Calendar", "communicat", "Insurance", "mission", "Server", "Account", "alive",
"concern", "admin", "support", "service", "info", "contact", "webmaster", "web", "help", "it", "tech", "security", "abuse",
 "postmaster", "fso", "lit", "Birthday", "estate", "candy", "campain")  # SamAccountNames to exclude adjust for your needs

# Function to get user input for OUs
function Get-OUs {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [Array]$InputOUs
    )
    $Script:OUs = $InputOUs
    Write-Output "OUs to be processed: $Script:OUs"
}

# Function to query Active Directory for users in specified OUs and filter those whose passwords have not been changed in the last 10 days
function Get-ADUsers {
    [CmdletBinding()]
    param()

    foreach ($OU in $Script:OUs) {
        try {
            Write-Output "Querying AD for users in OU $OU"
            # Fetch users from the specified OU and sub-OUs
            $UsersInOU = Get-ADUser -Filter * -SearchBase $OU -SearchScope Subtree -Property EmailAddress, SamAccountName, pwdLastSet, Description, Enabled

            if ($UsersInOU) {
                Write-Output "Found $($UsersInOU.Count) users in OU $OU"
            } else {
                Write-Output "No users found in OU $OU"
                continue
            }

            # Convert AD timestamp to DateTime and filter
            foreach ($User in $UsersInOU) {
                # Skip users with descriptions in the exclusion list
                if ($User.Description -and ($DescriptionsToExclude -contains $User.Description)) {
                    Write-Output "Skipping user $($User.SamAccountName) due to exclusion description $($User.Description)"
                    continue
                }

                # Skip disabled users
                if ($User.Enabled -eq $false) {
                    Write-Output "Skipping disabled user $($User.SamAccountName)"
                    continue
                }

                # Skip users whose SamAccountName matches the exclusion patterns or contains digits
                $isExcluded = $false
                foreach ($pattern in $SamAccountNamesToExclude) {
                    if ($User.SamAccountName -like $pattern -or $User.SamAccountName -match $RegexToExcludeNumerics) {
                        Write-Output "Skipping user $($User.SamAccountName) due to exclusion pattern $pattern or numeric content"
                        $isExcluded = $true
                        break
                    }
                }
                if ($isExcluded) {
                    continue
                }

                $PwdLastSetDate = [datetime]::FromFileTime($User.pwdLastSet)
                if ($PwdLastSetDate -lt $CutoffDate) {
                    if ($User.EmailAddress -and $User.EmailAddress -like "*$Domain") {
                        $Script:Users += [PSCustomObject]@{
                            SamAccountName = $User.SamAccountName
                            EmailAddress   = $User.EmailAddress
                            PwdLastSet     = $PwdLastSetDate
                        }
                    }
                }
            }
        } catch {
            Write-Error "Failed to query Active Directory for OU $OU $_"
        }
    }
    Write-Output "Total users processed: $($Script:Users.Count)"
}
# set users to change password at next login via Active Director
function Set-PasswordChangeAtNextLogin {
    foreach ($User in $Script:Users) {
        try {
            Write-Output "Setting $($User.SamAccountName) to change password at next login"
            Set-ADUser -Identity $User.SamAccountName -ChangePasswordAtLogon $true
        } catch {
            Write-Error "Failed to set $($User.SamAccountName) to change password at next login $_"
        }
    }
}

# Main script execution

# Get OUs from user input
Get-OUs -InputOUs $InputOUs

# Retrieve users from specified OUs
Get-ADUsers

# Check if Azure AD Sync force password change at next login is enabled
get-azuresynccompanyfeatures

# Set users to change password at next login
Set-PasswordChangeAtNextLogin

# Output the users who will be forced to change their password
Write-Output "Users who will be forced to change their password:"
$Script:Users | Format-Table -AutoSize SamAccountName, EmailAddress, PwdLastSet