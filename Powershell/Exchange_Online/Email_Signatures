<#
********************************************************************************
# SUMMARY:      Script to format employee signatures for Exchange Online
# AUTHOR:       Joshua Ogden
# DESCRIPTION:  This script retrieves user details from Azure AD and formats their 
#               email signatures to include their first name, last name, department,
#               direct line, and fax line.
# COMPATIBILITY: Exchange Online, Azure AD
# NOTES:        Ensure you have the necessary permissions to access Azure AD and modify 
#               user attributes in Exchange Online.
********************************************************************************
#>

# Import necessary modules
Import-Module AzureAD
Import-Module ExchangeOnlineManagement

# Function to get user details from Azure AD
Function Get-UserDetails {
    Param (
        [string]$UserPrincipalName
    )
    Try {
        $User = Get-AzureADUser -ObjectId $UserPrincipalName
        If ($User) {
            $UserDetails = @{
                ObjectId                    = $User.ObjectId
                UserPrincipalName           = $User.UserPrincipalName
                DisplayName                 = $User.DisplayName
                GivenName                   = $User.GivenName
                Surname                     = $User.Surname
                JobTitle                    = $User.JobTitle
                Department                  = $User.Department
                CompanyName                 = $User.CompanyName
                TelephoneNumber             = $User.TelephoneNumber
                Mobile                      = $User.Mobile
                Country                     = $User.Country
                ProxyAddresses              = $User.ProxyAddresses
            }
            Return $UserDetails
        } Else {
            Write-Error "User not found in Azure AD"
        }
    } Catch {
        Write-Error "Failed to retrieve user details: $_"
    }
}

# Function to update user signature in Exchange Online
Function Set-UserSignature {
    Param (
        [string]$UserPrincipalName,
        [hashtable]$UserDetails
    )
    Try {
        $Signature = @"
        <div>
            <p>$($UserDetails.GivenName) $($UserDetails.Surname)</p>
            <p>$($UserDetails.CompanyName)</p>
            <p>$($UserDetails.JobTitle)</p>
            <p>Department: $($UserDetails.Department)</p>
            <p>Direct Line: $($UserDetails.TelephoneNumber)</p>
            <p>Fax Line: (555)-555-5555</p>
        </div>
"@
        Set-MailboxMessageConfiguration -Identity $UserPrincipalName -SignatureHtml $Signature
        Write-Output "Signature updated for $UserPrincipalName"
    } Catch {
        Write-Error "Failed to update signature: $_"
    }
}

# Connect to Azure AD and Exchange Online
Try {
    Connect-AzureAD
    Connect-ExchangeOnline -UserPrincipalName read-host -Prompt "admin@yourdomain.com"
} Catch {
    Write-Error "Failed to connect to Azure AD or Exchange Online: $_"
    Exit
}

# Prompt for group name
$GroupName = Read-Host -Prompt "Enter the name of the group whose members should get the signature update"

# Check if group exists
Try {
    $Group = Get-AzureADGroup -Filter "DisplayName eq '$($GroupName)'"
    If (-Not $Group) {
        Throw "Group '$($GroupName)' does not exist."
    }
} Catch {
    Write-Error "Failed to retrieve group information: $_"
    Disconnect-AzureAD
    Disconnect-ExchangeOnline
    Exit
}

# Get members of the group
Try {
    $GroupMembers = Get-AzureADGroupMember -ObjectId $Group.ObjectId
} Catch {
    Write-Error "Failed to retrieve group members: $_"
    Disconnect-AzureAD
    Disconnect-ExchangeOnline
    Exit
}

# Main script
ForEach ($Member in $GroupMembers) {
    $UserPrincipalName = $Member.UserPrincipalName
    $UserDetails = Get-UserDetails -UserPrincipalName $UserPrincipalName
    If ($UserDetails) {
        Set-UserSignature -UserPrincipalName $UserPrincipalName -UserDetails $UserDetails
    }
}

# Disconnect from services
Disconnect-AzureAD
Disconnect-ExchangeOnline
