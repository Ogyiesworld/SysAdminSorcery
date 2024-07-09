<#
********************************************************************************
# SUMMARY:      Diagnostic Script for RDS Profiles
# AUTHOR:       Joshua Ogden
# DESCRIPTION:  This script gathers diagnostic information to help determine why users are receiving temporary profiles on an RDS server.
# COMPATIBILITY: Windows Server 2012 and later
# NOTES:        This script performs only diagnostic checks and does not make any changes to the system. Run with administrative privileges.
********************************************************************************
#>

Function Get-UserProfileLogs {
    Write-Verbose "Gathering User Profile Service logs..."
    Try {
        Get-WinEvent -LogName "Microsoft-Windows-User Profiles Service/Operational" | Where-Object {
            $_.Id -in 1511, 1515, 1518, 1521, 1530
        } | Select-Object TimeCreated, Id, Message
    } Catch {
        Write-Warning "Failed to gather User Profile Service logs: $($_.Exception.Message)"
    }
}

Function Get-ProfileListRegistry {
    Write-Verbose "Checking Profile List in Registry..."
    Try {
        Get-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\ProfileList\*" | Select-Object PSChildName, ProfileImagePath, State
    } Catch {
        Write-Warning "Failed to access Profile List in Registry: $($_.Exception.Message)"
    }
}

Function Get-DiskSpace {
    Write-Verbose "Checking Disk Space on C: Drive..."
    Try {
        Get-PSDrive -Name C | Select-Object Name, Used, Free, @{Name="Used(GB)"; Expression={"{0:N2}" -f ($_.Used/1GB)}}, @{Name="Free(GB)"; Expression={"{0:N2}" -f ($_.Free/1GB)}}
    } Catch {
        Write-Warning "Failed to check Disk Space: $($_.Exception.Message)"
    }
}

Function Get-UserProfilePermissions {
    Write-Verbose "Checking permissions on user profile directory..."
    Try {
        Get-Acl -Path "C:\Users" | Select-Object Path, Owner, @{Name="Permissions"; Expression={$_.AccessToString}}
    } Catch {
        Write-Warning "Failed to check User Profile Directory Permissions: $($_.Exception.Message)"
    }
}

Function Get-RDSSessionInfo {
    Write-Verbose "Gathering RDS Session information..."
    Try {
        quser
    } Catch {
        Write-Warning "Failed to gather RDS Session information: $($_.Exception.Message)"
    }
}

Function Get-SystemLogs {
    Write-Verbose "Gathering System event logs..."
    Try {
        Get-WinEvent -LogName System | Where-Object {
            $_.Id -in 6005, 6006, 6008, 41
        } | Select-Object TimeCreated, Id, Message
    } Catch {
        Write-Warning "Failed to gather System Event Logs: $($_.Exception.Message)"
    }
}

Function Check-CorruptProfiles {
    Write-Verbose "Checking for corrupt profiles..."
    Try {
        $profileList = Get-ProfileListRegistry
        $profileList | Where-Object {$_.State -ne 0} | Select-Object PSChildName, ProfileImagePath, State
    } Catch {
        Write-Warning "Failed to check for Corrupt Profiles: $($_.Exception.Message)"
    }
}

Function Check-GroupPolicy {
    Write-Verbose "Generating Group Policy Resultant Set of Policy (RSoP) Report..."
    Try {
        $gpresultPath = "$env:TEMP\GPReport.html"
        gpresult /h $gpresultPath /f
        Start-Process $gpresultPath
    } Catch {
        Write-Warning "Failed to generate Group Policy RSoP Report: $($_.Exception.Message)"
    }
}

Function Check-UserProfileService {
    Write-Verbose "Checking User Profile Service status..."
    Try {
        Get-Service -Name ProfSvc | Select-Object Status, Name, DisplayName
    } Catch {
        Write-Warning "Failed to check User Profile Service status: $($_.Exception.Message)"
    }
}

Function Get-NetworkDiagnostics {
    Write-Verbose "Checking network connectivity to google.com..."
    Try {
        Test-Connection -ComputerName "google.com" -Count 4 | Select-Object Address, StatusCode, ResponseTime, BufferSize
    } Catch {
        Write-Warning "Failed to perform Network Diagnostics: $($_.Exception.Message)"
    }
}

Function Check-ServiceDependencies {
    Write-Verbose "Checking User Profile Service dependencies..."
    Try {
        Get-Service -Name ProfSvc | Select-Object -ExpandProperty ServicesDependedOn | Select-Object Name, Status
    } Catch {
        Write-Warning "Failed to check User Profile Service Dependencies: $($_.Exception.Message)"
    }
}

# Main execution block
Write-Host "Starting RDS Temp Profile Diagnostics..."
$VerbosePreference = 'Continue'

$profileLogs = Get-UserProfileLogs
$profileRegistry = Get-ProfileListRegistry
$diskSpace = Get-DiskSpace
$profilePermissions = Get-UserProfilePermissions
$rdsSessionInfo = Get-RDSSessionInfo
$systemLogs = Get-SystemLogs
$corruptProfiles = Check-CorruptProfiles
$userProfileService = Check-UserProfileService
$networkDiagnostics = Get-NetworkDiagnostics
$serviceDependencies = Check-ServiceDependencies

$diagnosticsOutput = @{
    "User Profile Service Logs" = $profileLogs
    "Profile List Registry Information" = $profileRegistry
    "Disk Space Information" = $diskSpace
    "User Profile Directory Permissions" = $profilePermissions
    "RDS Session Information" = $rdsSessionInfo
    "System Event Logs" = $systemLogs
    "Corrupt Profiles Information" = $corruptProfiles
    "User Profile Service Status" = $userProfileService
    "Network Diagnostics" = $networkDiagnostics
    "User Profile Service Dependencies" = $serviceDependencies
}

$outputFilePath = "C:\temp\RDSProfileDiagnostics.csv"
if (-not (Test-Path -Path "C:\temp")) {
    New-Item -ItemType Directory -Path "C:\temp"
}

foreach ($key in $diagnosticsOutput.Keys) {
    Write-Host "`n$key:"
    $diagnosticsOutput[$key] | Export-Csv -Path $outputFilePath -Append -NoTypeInformation
}

Write-Host "Diagnostics saved to $outputFilePath"

Check-GroupPolicy

Write-Host "RDS Temp Profile Diagnostics Completed."