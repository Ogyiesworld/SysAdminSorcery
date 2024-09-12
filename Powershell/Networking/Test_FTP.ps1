<#
********************************************************************************
# SUMMARY:      Test connectivity to an FTP site using an IP address without login credentials
# AUTHOR:       Joshua Ogden
# DESCRIPTION:  This script checks if an FTP site is accessible without using 
#               credentials by attempting an anonymous connection to an FTP site via its IP address.
# COMPATIBILITY: Windows PowerShell 5.1, PowerShell Core 7+
# NOTES:        Requires Internet connection.
********************************************************************************
#>

# Variable Declaration
Param(
    [string]$FtpServerIp = ""
)

function Test-FtpConnection {
    Param (
        [string]$IpAddress
    )

    try {
        # Construct the full FTP URL from the IP address
        $Url = "ftp://$IpAddress"
        Write-Output "Constructed FTP URL: $Url"

        # Validate URL format
        if (-not ($Url -match "^ftp://")) {
            throw [System.ArgumentException]::new("Invalid URI: URL must begin with 'ftp://'")
        } else {
            Write-Output "Valid URL format confirmed."
        }

        # Create the FTP WebRequest
        Write-Output "Creating FTP web request..."
        $FtpRequest = [System.Net.FtpWebRequest]::Create($Url)
        $FtpRequest.Method = [System.Net.WebRequestMethods+Ftp]::ListDirectory
        $FtpRequest.Credentials = [System.Net.CredentialCache]::DefaultNetworkCredentials
        $FtpRequest.Timeout = 5000  # Timeout in milliseconds

        Write-Output "Sending request to FTP server..."
        # Get the response from the server
        $FtpResponse = $FtpRequest.GetResponse()
        
        Write-Output "Checking response status code..."
        # Ensure connection
        if ($FtpResponse.StatusCode -ne [System.Net.FtpStatusCode]::OpeningData -and $FtpResponse.StatusCode -ne [System.Net.FtpStatusCode]::DataAlreadyOpen) {
            Write-Output "Connection failed: $($FtpResponse.StatusDescription)"
            $FtpResponse.Close()
            return $false
        } else {
            Write-Output "FTP connection successful: $($FtpResponse.StatusDescription)"
        }

        Write-Output "Reading response from FTP server..."
        $FtpStream = $FtpResponse.GetResponseStream()
        $Reader = New-Object System.IO.StreamReader($FtpStream)
        $ListData = $Reader.ReadToEnd() # Even though we don't use the data, this action validates the stream
        
        # Output the retrieved directory list for verification
        Write-Output "Retrieved Data:"
        Write-Output $ListData

        # Clean up
        $Reader.Close()
        $FtpResponse.Close()

        Write-Output "FTP Server List Directory Operation Completed Successfully."
        return $true
        
    } catch [System.ArgumentException] {
        Write-Output "Argument Exception: $($_.Exception.Message)"
        return $false
    } catch [System.Net.WebException] {
        Write-Output "Web Exception: Status $($_.Exception.Status). Message: $($_.Exception.Message)"
        return $false
    } catch {
        Write-Output "General Exception: $($_.Exception.Message)"
        return $false
    }
}

# Main script execution
Write-Output "Starting FTP Connection Test..."
$ConnectionResult = Test-FtpConnection -IpAddress $FtpServerIp
if ($ConnectionResult) {
    Write-Output "FTP server is reachable and talking."
} else {
    Write-Output "FTP server is not reachable or not talking."
}
Write-Output "FTP Connection Test Completed."