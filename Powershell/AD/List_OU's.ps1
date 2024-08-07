<#
********************************************************************************
# SUMMARY:      List OUs and select for user placement
# AUTHOR:       Joshua Ogden
# DESCRIPTION:  This script lists all Organizational Units (OUs) in an Active 
#               Directory domain, enabling the user to select an OU to place a 
#               user account.
# COMPATIBILITY: Windows PowerShell 5.1, PowerShell Core 7.x
# NOTES:        Ensure that the AD module is installed and loaded.
********************************************************************************
#>

# Load the Active Directory module
Import-Module ActiveDirectory

# Variable Declaration
$OUs = @()

<#
.SYNOPSIS
    Recursively lists all Organizational Units (OUs) in the given LDAP path.
.PARAMETER LdapPath
    The LDAP path from which to list the OUs.
#>
Function RecursivelyListOUs {
    param([string]$LdapPath)
    
    try {
        # Get directory entry
        $DirectoryEntry = New-Object System.DirectoryServices.DirectoryEntry($LdapPath)

        # Fetch all child OUs
        $ChildOUs = $DirectoryEntry.Children | Where-Object { $_.SchemaClassName -eq "organizationalUnit" }

        # Process each child OU
        foreach ($ChildOU in $ChildOUs) {
            $DistinguishedName = $ChildOU.Properties["DistinguishedName"].Value
            $OUs += $DistinguishedName
            # Recursively call the function for child OUs
            RecursivelyListOUs -LdapPath "LDAP://$DistinguishedName"
        }
    }
    catch {
        Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Red
    }
}

<#
.SYNOPSIS
    Lists all Organizational Units (OUs) in the specified domain and allows the 
    user to choose one for placing a new user.
.PARAMETER AdServer
    The Active Directory server to connect to (hostname).
#>
Function ListAndSelectOU {
    param([string]$AdServer)
    
    try {
        # Get the directory entry for the specified AD server
        $RootDSE = [ADSI]("LDAP://$AdServer/RootDSE")
        $DefaultNamingContext = $RootDSE.defaultNamingContext

        # Run the recursive OU listing function
        RecursivelyListOUs -LdapPath "LDAP://$AdServer/$DefaultNamingContext"

        # Remove DC= components and sort OUs alphabetically
        $FormattedOUs = $OUs | ForEach-Object { $_ -replace ",DC=.*" } | Sort-Object

        # Display formatted OUs with an index and prompt for selection
        $SelectedOU = $null
        while (($null -eq $SelectedOU) -or ($SelectedOU -eq '')) {
            Write-Host "Available OUs:" -ForegroundColor Cyan
            $FormattedOUs | ForEach-Object { Write-Host "$([array]::IndexOf($FormattedOUs, $_) + 1): $_" }
            $SelectedIndex = [int](Read-Host "Enter the number of the desired OU")
            if ($SelectedIndex -gt 0 -and $SelectedIndex -le $FormattedOUs.Length) {
                $SelectedOU = $FormattedOUs[$SelectedIndex - 1]
            }
            if ($null -eq $SelectedOU) {
                Write-Host "Invalid selection. Please try again." -ForegroundColor Yellow
            }
        }

        Write-Host "You have selected the OU: $SelectedOU" -ForegroundColor Green
    }
    catch {
        Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Red
    }
}

# Main Script Execution
$AdServer = Read-Host "Enter the Active Directory server hostname to connect to"
ListAndSelectOU -AdServer $AdServer