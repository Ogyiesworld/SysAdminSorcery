<#
********************************************************************************
# SUMMARY:      Check User Account Lockout Information
# AUTHOR:       Joshua Ogden
# DESCRIPTION:  This script checks the lockout information of a specified user
#               account in Active Directory. It retrieves details such as
#               lockout status, lockout threshold, last bad password attempt, 
#               lockout duration, time remaining until lockout expires, 
#               and the last 5 bad password attempts across all domain controllers.
# COMPATIBILITY: Windows Server 2008 or later with Active Directory module installed
# NOTES:        This script requires the Active Directory module for Windows PowerShell.
********************************************************************************
#>

# Import the Active Directory module
Import-Module ActiveDirectory

# Function to get user lockout information
function Get-UserLockoutInfo {
    param (
        [string]$User
    )
    try {
        # Search for the user account
        $userAccount = Get-ADUser -Identity $User -Properties LockedOut, LastBadPasswordAttempt, LockoutTime

        if ($null -eq $userAccount) {
            Write-Host "User account not found."
            return
        }

        # Get domain policy to retrieve lockout threshold and duration
        $domainPolicy = Get-ADDefaultDomainPasswordPolicy
        $lockoutDurationMinutes = $domainPolicy.LockoutDuration

        # Display lockout information
        Write-Host "User: $($userAccount.SamAccountName)"
        Write-Host "Locked Out: $($userAccount.LockedOut)"
        Write-Host "Lockout Threshold: $($domainPolicy.LockoutThreshold)"
        Write-Host "Lockout Duration: $lockoutDurationMinutes minutes"
        Write-Host "Last Bad Password Attempt: $($userAccount.LastBadPasswordAttempt)"

        if ($userAccount.LockedOut -eq $true) {
            $lockoutTime = [DateTime]::FromFileTime([Int64]::Parse($userAccount.LockoutTime))
            Write-Host "Lockout Time: $lockoutTime"
            $lockoutEndTime = $lockoutTime.AddMinutes($lockoutDurationMinutes)
            $timeRemaining = $lockoutEndTime - (Get-Date)
            Write-Host "Time Remaining Until Lockout Expires: $($timeRemaining.ToString('hh\:mm\:ss'))"
        } else {
            Write-Host "Lockout Time: Account is not currently locked out."
        }

        # Get all domain controllers
        $domainControllers = Get-ADDomainController -Filter *

        $badPasswordAttempts = @()

        # Retrieve the last 5 bad password attempts from each domain controller
        foreach ($dc in $domainControllers) {
            Write-Host "Checking domain controller: $($dc.HostName)"

            $filterXml = @"
<QueryList>
  <Query Id="0" Path="Security">
    <Select Path="Security">
      *[System[EventID=4625]] and *[EventData[Data[@Name='TargetUserName'] and (Data='$User')]]
    </Select>
  </Query>
</QueryList>
"@

            try {
                $dcBadPasswordAttempts = Get-WinEvent -ComputerName $dc.HostName -FilterXml $filterXml -ErrorAction Stop |
                                         Sort-Object TimeCreated -Descending |
                                         Select-Object TimeCreated, Message

                $badPasswordAttempts += $dcBadPasswordAttempts
            } catch {
                Write-Host "No events were found on domain controller: $($dc.HostName)"
            }
        }

        # Sort and select the top 5 bad password attempts across all domain controllers
        $badPasswordAttempts = $badPasswordAttempts | Sort-Object TimeCreated -Descending | Select-Object -First 5

        Write-Host "Last 5 Bad Password Attempts:"
        if ($badPasswordAttempts) {
            foreach ($attempt in $badPasswordAttempts) {
                Write-Host "Time: $($attempt.TimeCreated) - Message: $($attempt.Message)"
            }
        } else {
            Write-Host "No bad password attempts found."
        }
    } catch {
        Write-Host "An error occurred: $_"
    }
}

# Prompt for the username
$Username = Read-Host -Prompt "Enter the username"

# Get the user lockout information
Get-UserLockoutInfo -User $Username
