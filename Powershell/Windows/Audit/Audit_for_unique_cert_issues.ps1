<#
********************************************************************************
# SUMMARY:      Script to scan and list unique certificate issuers from local machine's stores.
# AUTHOR:       Joshua Ogden
# DESCRIPTION:  This script scans specified certificate stores on the local machine, gathering and listing unique 
                issuers (Certificate Authorities). It processes both 'LocalMachine' and 'CurrentUser' stores.
# COMPATIBILITY: Windows environments with PowerShell.
# NOTES:        Run this script with administrative privileges for best results. The output will include sorted 
                unique issuers which can be useful for administrative and security auditing purposes.
********************************************************************************
#>

# Define the locations of the certificate stores to be scanned
$StoreLocations = @("LocalMachine", "CurrentUser")
$IssuerList = @()

foreach ($Location in $StoreLocations) {
    try {
        Write-Host "Scanning $Location..."
        # Open the certificate store based on the specified location
        $Store = New-Object System.Security.Cryptography.X509Certificates.X509Store("My", [System.Security.Cryptography.X509Certificates.StoreLocation]::$Location)
        $Store.Open("ReadOnly")

        # Retrieve certificates and append unique issuers to the list
        $Certs = $Store.Certificates
        foreach ($Cert in $Certs) {
            if (-not $IssuerList.Contains($Cert.Issuer)) {
                $IssuerList += $Cert.Issuer
            }
        }

        $Store.Close()
    } catch {
        Write-Host "Failed to scan $Location $_"
    }
}

# Output the sorted list of unique certificate issuers
Write-Host "Unique Issuers (Certificate Authorities) on your machine:"
$IssuerList | Sort-Object | ForEach-Object { Write-Host $_ }