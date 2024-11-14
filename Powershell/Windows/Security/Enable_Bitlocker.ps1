<#
********************************************************************************
# SUMMARY:      Check and Enable BitLocker with User Notification, Recovery Key Storage, and Logging
# AUTHOR:       Joshua Ogden
# DESCRIPTION:  This script checks if BitLocker is enabled on the system. 
#               If BitLocker is not enabled, it enables BitLocker, stores the 
#               BitLocker recovery key in a specified directory, and notifies the
#               user to restart or lock their device to complete the encryption. 
#               If BitLocker is already enabled, it still pulls the recovery key and stores it.
# COMPATIBILITY: Windows 10, Windows Server 2016 and above
# NOTES:        Run the script with administrative privileges.
********************************************************************************
#>

# Variable Declaration
$RecoveryKeyPath = "\\Server\Directory\BitlockerKeys"
$DriveLetter = "C"
$CurrentDate = Get-Date -Format "yyyy-MM-dd"  # Changed format for consistency
$Hostname = $env:COMPUTERNAME
$LogPath = "C:\temp\BitLockerLog_$CurrentDate.txt"

# Initialize the log
function Write-LogMessage {
    param (
        [string]$Message
    )
    $Timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
    "$Timestamp $Message" | Out-File -FilePath $LogPath -Append
}

Write-LogMessage "Script started"

function Save-RecoveryKey {
    param (
        [string]$DriveLetter,
        [string]$RecoveryKeyPath,
        [string]$CurrentDate,
        [string]$Hostname
    )

    try {
        $RecoveryKey = (Get-BitLockerVolume -MountPoint $DriveLetter).KeyProtector | Where-Object {$_.KeyProtectorType -eq 'RecoveryPassword'}
        
        # Create directory if it doesn't exist
        if (-not (Test-Path -Path $RecoveryKeyPath)) {
            New-Item -ItemType Directory -Path $RecoveryKeyPath -Force
            Write-LogMessage "Created directory at $RecoveryKeyPath"
        }
        
        # Save the recovery key to a file
        $RecoveryKeyFileName = "${Hostname}_BitLockerKey_$CurrentDate.txt"
        $RecoveryKeyFilePath = Join-Path -Path $RecoveryKeyPath -ChildPath $RecoveryKeyFileName
        
        $RecoveryKey.RecoveryPassword | Out-File -FilePath $RecoveryKeyFilePath
        Write-LogMessage "The recovery key has been saved to $RecoveryKeyFilePath"
    }
    catch {
        Write-LogMessage "Failed to save the recovery key. Error: $_"
        throw $_
    }
}

try {
    # Check if BitLocker is enabled on the specified drive
    $BitLockerStatus = Get-BitLockerVolume -MountPoint $DriveLetter
    Write-LogMessage "Checked BitLocker status on drive $DriveLetter"

    if ($BitLockerStatus.ProtectionStatus -eq 'On') {
        Write-LogMessage "BitLocker is already enabled on drive $DriveLetter"

        # Save the recovery key
        Save-RecoveryKey -DriveLetter $DriveLetter -RecoveryKeyPath $RecoveryKeyPath -CurrentDate $CurrentDate -Hostname $Hostname
    }
    else {
        Write-LogMessage "BitLocker is not enabled on drive $DriveLetter. Enabling BitLocker..."

        # Enable BitLocker and save the recovery key
        Enable-BitLocker -MountPoint $DriveLetter -EncryptionMethod XtsAes256 -RecoveryPasswordProtector -UsedSpaceOnly -TpmProtector | Out-Null
        Write-LogMessage "BitLocker has been enabled on drive $DriveLetter"

        # Save the recovery key
        Save-RecoveryKey -DriveLetter $DriveLetter -RecoveryKeyPath $RecoveryKeyPath -CurrentDate $CurrentDate -Hostname $Hostname
    }

    # Inform user that BitLocker will complete encryption on restart or lock
    $BalloonMessage = @{
        Text = "BitLocker encryption has been started. To complete the process, please restart or lock your device."
        Title = "BitLocker Encryption"
        Sound = "ms-winsoundevent:Notification.Default"
    }

    $toastXml = [Windows.Data.Xml.Dom.XmlDocument]::new()
    $toastXml.LoadXml("<toast><visual><binding template='ToastGeneric'><text>$($BalloonMessage.Title)</text><text>$($BalloonMessage.Text)</text></binding></visual><audio src='$($BalloonMessage.Sound)'/></toast>")
    [Windows.UI.Notifications.ToastNotificationManager]::CreateToastNotifier("System").Show([Windows.UI.Notifications.ToastNotification]::new($toastXml))
    
    Write-LogMessage "User has been notified to restart or lock the device to complete the encryption"

}
catch {
    Write-LogMessage "An error occurred: $_"
}

# Finalize the log
Write-LogMessage "Script ended"
