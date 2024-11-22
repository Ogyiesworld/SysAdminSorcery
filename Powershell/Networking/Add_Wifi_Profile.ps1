# Variable declarations
$SSID = Read-Host "Enter the SSID of the WiFi network"
$Password = Read-Host "Enter the password for the WiFi network" -AsSecureString

# Check if SSID is hidden
$IsHidden = Read-Host "Is the SSID hidden? (Y/N)"
$Hidden = $IsHidden -eq 'Y'

# Convert secure string password to plain text
$BSTR = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($Password)
$PlainPassword = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($BSTR)

# Create XML profile for WPA2-Personal (PSK)
$XMLProfile = @"
<?xml version="1.0"?>
<WLANProfile xmlns="http://www.microsoft.com/networking/WLAN/profile/v1">
    <name>$SSID</name>
    <SSIDConfig>
        <SSID>
            <name>$SSID</name>
        </SSID>
        <nonBroadcast>$($Hidden.ToString().ToLower())</nonBroadcast>
    </SSIDConfig>
    <connectionType>ESS</connectionType>
    <connectionMode>auto</connectionMode>
    <MSM>
        <security>
            <authEncryption>
                <authentication>WPA2PSK</authentication>
                <encryption>AES</encryption>
                <useOneX>false</useOneX>
            </authEncryption>
            <sharedKey>
                <keyType>passPhrase</keyType>
                <protected>false</protected>
                <keyMaterial>$PlainPassword</keyMaterial>
            </sharedKey>
        </security>
    </MSM>
</WLANProfile>
"@

# Add WiFi profile
$TempFile = [System.IO.Path]::GetTempFileName()
$XMLProfile | Out-File -FilePath $TempFile -Encoding ASCII

try {
    # Remove existing profile if it exists
    $existingProfile = netsh wlan show profiles name="$SSID" 2>$null
    if ($LASTEXITCODE -eq 0) {
        Write-Host "Removing existing profile for $SSID..."
        netsh wlan delete profile name="$SSID" | Out-Null
    }

    # Add new profile
    $result = netsh wlan add profile filename="$TempFile"
    if ($LASTEXITCODE -eq 0) {
        Write-Host "WiFi profile for $SSID has been added successfully."
        # Try to connect to the network
        netsh wlan connect name="$SSID"
    } else {
        Write-Host "Failed to add WiFi profile. Error: $result" -ForegroundColor Red
    }
} catch {
    Write-Host "An error occurred while adding the WiFi profile: $_" -ForegroundColor Red
} finally {
    # Clean up
    if ($BSTR) {
        [System.Runtime.InteropServices.Marshal]::ZeroFreeBSTR($BSTR)
    }
    if (Test-Path $TempFile) {
        Remove-Item -Path $TempFile -Force
    }
}
