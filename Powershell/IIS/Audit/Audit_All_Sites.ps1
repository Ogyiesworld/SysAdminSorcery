#The goal of this script is to list out all of the sites in IIS for auditing if they are still needed or not.
#The script will output the site name, ID, and physical path.
#The script will also output the application pool name and ID for each site.
#The script will output the bindings for each site, including the protocol, IP address, port, and host name.
#The script will output the SSL certificate information for each site, if applicable.
#The script will output the authentication settings for each site.

# Define the output file path
$outputFilePath = "C:\Temp\IIS_Sites_Audit.csv"

# Get all the sites in IIS
$sites = Get-Website

# Initialize an array to hold the site information
$siteInfoArray = @()

# Loop through each site
foreach ($site in $sites) {
    # ... (rest of the code)

    # Get the site name and ID
    $siteName = $site.Name
    $siteId = $site.Id


    # Get the bindings for the site
    $bindings = $site.Bindings.Collection | ForEach-Object {
        $protocol = $_.Protocol
        $ipAddress = $_.BindingInformation.Split(":")[0]
        $port = $_.BindingInformation.Split(":")[1]
        $hostName = $_.Host
        "$protocol $ipAddress $port $hostName"
    }

    # Get the SSL certificate information for the site
    $sslCertificate = $site.Bindings.Collection | Where-Object { $_.CertificateHash -ne $null } | ForEach-Object {
        $certificateHash = $_.CertificateHash
        $certificateStoreName = $_.CertificateStoreName
        $certificateSubject = $_.CertificateSubject
        $certificateIssuer = $_.CertificateIssuer
        $certificateThumbprint = $_.CertificateThumbprint
        $certificateEffectiveDate = $_.CertificateEffectiveDate
        $certificateExpirationDate = $_.CertificateExpirationDate
        [PSCustomObject]@{
            CertificateHash = $certificateHash
            CertificateStoreName = $certificateStoreName
            CertificateSubject = $certificateSubject
            CertificateIssuer = $certificateIssuer
            CertificateThumbprint = $certificateThumbprint
            CertificateEffectiveDate = $certificateEffectiveDate
            CertificateExpirationDate = $certificateExpirationDate
        }
    }

    # Create a custom object with all the site information
    $siteInfo = [PSCustomObject]@{
        SiteName = $siteName
        SiteId = $siteId
        PhysicalPath = $site.PhysicalPath
        Bindings = $bindings -join ", "
        SSLCertificate = $sslCertificate
    }
    # Add the site information to the array
    $siteInfoArray += $siteInfo
}

# Export the site information to the CSV file
$siteInfoArray | Export-Csv -Path $outputFilePath -NoTypeInformation -Force

# Output a message to the user
Write-Host "IIS sites audit completed. Results saved to $outputFilePath" -ForegroundColor Green