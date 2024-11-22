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
        <nonBroadcast>$Hidden</nonBroadcast>
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
    netsh wlan add profile filename="$TempFile"
    Write-Host "WiFi profile for $SSID has been added successfully."
} catch {
    Write-Host "An error occurred while adding the WiFi profile: $_"
} finally {
    Remove-Item -Path $TempFile -Force
}
