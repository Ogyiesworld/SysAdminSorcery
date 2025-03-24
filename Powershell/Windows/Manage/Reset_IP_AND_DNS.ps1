<#
********************************************************************************
# SUMMARY:      Confirm and Adjust Network Adapter DHCP Configuration
# AUTHOR:       Joshua Ogden
# DESCRIPTION:  This script lists all network adapters, including VPN adapters, 
#               and indicates which ones will be changed to use DHCP for IP and DNS settings.
#               It prompts the user for confirmation before making any changes, and now also 
#               asks if the user wants to reset VPN NICs DHCP to auto. Adapters both UP or DOWN are included.
# COMPATIBILITY: Compatible with Windows PowerShell 5.1 and above on Windows 8.1, 
#               and Windows 10. Administrative privileges are required.
# NOTES:        Version 1.2. Last Updated: [07/04/2024]. Run this script as Administrator 
#               to ensure it has the necessary permissions to modify network adapter settings.
#>

# Get all network adapters including VPN adapters, regardless of their 'Up' or 'Down' status
$adapters = Get-NetAdapter | Where-Object { $_.Status -eq 'Up' -or $_.Status -eq 'Down' }

if ($adapters.Count -eq 0) {
    Write-Host "No applicable network adapters found. Exiting script." -ForegroundColor Yellow
    exit
}

Write-Host "The following network adapters will be considered for configuration to use DHCP for IP and DNS settings:" -ForegroundColor Cyan

foreach ($adapter in $adapters) {
    Write-Host "Adapter: $($adapter.Name) - Status: $($adapter.Status)" -ForegroundColor Yellow
}

# Ask for user confirmation
$resetVpnChoice = Read-Host "Do you also want to reset VPN NICs DHCP to auto? (Y/N)"
$userChoice = Read-Host "Do you want to proceed with these changes? (Y/N)"
if ($userChoice -ieq "Y") {
    
    foreach ($adapter in $adapters) {
        if ($resetVpnChoice -ieq "Y" -or $adapter.InterfaceDescription -notmatch 'VPN') {
            Write-Host "Configuring adapter to DHCP: $($adapter.Name)" -ForegroundColor Green
            # Set IP address to be obtained automatically
            Set-NetIPInterface -InterfaceIndex $adapter.ifIndex -Dhcp Enabled
            
            # Clear any static DNS settings, ensuring DNS is obtained automatically
            Set-DnsClientServerAddress -InterfaceIndex $adapter.ifIndex -ResetServerAddresses
        }
    }
    Write-Host "Network adapters have been configured to use DHCP for IP and DNS settings." -ForegroundColor Green
} elseif ($userChoice -ieq "N") {
    Write-Host "Operation aborted by the user. No changes have been made." -ForegroundColor Red
} else {
    Write-Host "Invalid input detected. No changes have been made." -ForegroundColor Red
}
