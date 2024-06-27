<#
********************************************************************************
# SUMMARY:      Windows Licensing Cleanup Script
# AUTHOR:       Joshua Ogden
# DESCRIPTION:  Identifies the system drive and performs cleanup operations on
                Windows licensing files for various Windows versions.
# COMPATIBILITY: Windows 7, 8, 8.1, 10
# NOTES:        This script must be run with administrative privileges. It is
                designed to be executed in the background without user interaction.
********************************************************************************
#>

# Attempt to find the system drive by checking for the presence of SYSTEM in the config directory
$TargetLetter = $null
'D', 'C', 'B', 'A' | ForEach-Object {
    if (Test-Path "$_`:\Windows\system32\config\SYSTEM") {
        $TargetLetter = "$_`:"
        break
    }
}

if (-not $TargetLetter) {
    Write-Host "Cannot find target system"
    exit 1
}

# Detected system drive
Write-Host "Detected system on $TargetLetter"

# Confirmation prompt (simulated as always 'yes' for automation purposes)
$Sure = 'y'

if ($Sure -ieq 'y') {
    Start-Process -FilePath "diskpart" -ArgumentList "list volume" -NoNewWindow -Wait

    # Load registry hive for manipulation
    REG LOAD HKLM\TEMP "$TargetLetter\Windows\system32\config\SYSTEM"
    
    # Attempt to delete licensing information
    Get-ChildItem HKLM:\TEMP\WPA | ForEach-Object {
        Remove-Item $_.Name -Force
    }
    REG UNLOAD HKLM\TEMP

    # Helper function to remove files with attributes
    function Remove-ItemWithAttributes {
        param (
            [string]$Path
        )
        if (Test-Path $Path) {
            attrib -s -h $Path
            Remove-Item $Path -Force
        }
    }

    # Helper function to remove directories with attributes
    function Remove-DirectoryWithAttributes {
        param (
            [string]$Path
        )
        if (Test-Path $Path) {
            attrib -s -h $Path /S /D
            Remove-Item $Path -Recurse -Force
        }
    }

    # Paths and actions for different Windows versions
    @(
        "$TargetLetter\ProgramData\Microsoft\Windows\ClipSVC\tokens.dat",
        "$TargetLetter\Windows\System32\spp\store_test\2.0\data.dat",
        "$TargetLetter\Windows\System32\spp\store_test\2.0\tokens.dat",
        "$TargetLetter\Windows\System32\spp\store\2.0\data.dat",
        "$TargetLetter\Windows\System32\spp\store\2.0\tokens.dat",
        "$TargetLetter\Windows\System32\spp\store\data.dat",
        "$TargetLetter\Windows\System32\spp\store\tokens.dat",
        "$TargetLetter\Windows\ServiceProfiles\NetworkService\AppData\Roaming\Microsoft\SoftwareProtectionPlatform\tokens.dat"
    ) | ForEach-Object {
        Remove-ItemWithAttributes -Path $_
    }

    @(
        "$TargetLetter\Windows\System32\spp\store_test\2.0\cache",
        "$TargetLetter\Windows\System32\spp\store\2.0\cache",
        "$TargetLetter\Windows\System32\spp\store\cache",
        "$TargetLetter\Windows\ServiceProfiles\NetworkService\AppData\Roaming\Microsoft\SoftwareProtectionPlatform\cache"
    ) | ForEach-Object {
        Remove-DirectoryWithAttributes -Path $_
    }
}
else {
    Write-Host "Operation cancelled by user."
    exit
}
