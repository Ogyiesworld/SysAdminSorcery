<#
********************************************************************************
# SUMMARY:      Copy User Group Memberships to Another User
# AUTHOR:       Joshua Ogden
# DESCRIPTION:  This script copies all group memberships from one user to another 
#               in Active Directory. It includes error handling and logging to ensure 
#               any issues are captured and addressed.
# COMPATIBILITY: Windows Server 2008 R2 and above, Windows 7 with RSAT
# NOTES:        Run this script with appropriate privileges to modify Active Directory.
********************************************************************************
#>

# Import the Active Directory module
Import-Module ActiveDirectory

# Define the source and target usernames
$SourceUser = "SourceUsername"
$TargetUser = "TargetUsername"

# Function to log messages
Function Log-Message {
    param (
        [string]$Message,
        [string]$LogType = "INFO"
    )
    $Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Write-Host "$Timestamp [$LogType] - $Message"
}

# Start script execution
Log-Message "Starting the script to copy group memberships from $SourceUser to $TargetUser."

Try {
    # Get the distinguished names of the source and target users
    $SourceUserDN = Get-ADUser -Identity $SourceUser -Properties DistinguishedName
    $TargetUserDN = Get-ADUser -Identity $TargetUser -Properties DistinguishedName

    # Check if both users exist
    If (-not $SourceUserDN) {
        Throw "Source user $SourceUser does not exist in Active Directory."
    }
    If (-not $TargetUserDN) {
        Throw "Target user $TargetUser does not exist in Active Directory."
    }

    # Get the groups the source user is a member of
    $SourceGroups = Get-ADUser -Identity $SourceUser -Properties MemberOf | Select-Object -ExpandProperty MemberOf

    If ($SourceGroups) {
        # Add the target user to each group
        ForEach ($GroupDN in $SourceGroups) {
            Try {
                Add-ADGroupMember -Identity $GroupDN -Members $TargetUserDN.DistinguishedName
                Log-Message "Added $TargetUser to group $GroupDN."
            }
            Catch {
                Log-Message "Failed to add $TargetUser to group $GroupDN. Error: $_" "ERROR"
            }
        }
    }
    Else {
        Log-Message "$SourceUser is not a member of any groups."
    }
}
Catch {
    Log-Message "An error occurred: $_" "ERROR"
}

Log-Message "Script execution completed."
